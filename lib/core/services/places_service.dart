import 'dart:convert';
import 'dart:math' as math;

import '../config/app_config.dart';
import 'api_client.dart';

/// Yakındaki mekan (Overpass/OSM) ve rota süresi (OSRM).
class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.straightLineMeters,
    this.cuisine,
    this.amenity,
    this.phone,
    this.website,
    this.openingHours,
    this.address,
    this.driveMinutes,
    this.driveMeters,
    this.walkMinutes,
    this.walkMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Kuş uçuşu mesafe (metre).
  final double straightLineMeters;

  final String? cuisine;
  final String? amenity;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? address;

  final double? driveMinutes;
  final double? driveMeters;
  final double? walkMinutes;
  final double? walkMeters;

  NearbyPlace withRoutes({
    double? driveMinutes,
    double? driveMeters,
    double? walkMinutes,
    double? walkMeters,
  }) =>
      NearbyPlace(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        straightLineMeters: straightLineMeters,
        cuisine: cuisine,
        amenity: amenity,
        phone: phone,
        website: website,
        openingHours: openingHours,
        address: address,
        driveMinutes: driveMinutes ?? this.driveMinutes,
        driveMeters: driveMeters ?? this.driveMeters,
        walkMinutes: walkMinutes ?? this.walkMinutes,
        walkMeters: walkMeters ?? this.walkMeters,
      );
}

class PlacesService {
  PlacesService(this._api);

  final ApiClient _api;

  /// Yakındaki restoran/kafe/fırın.
  Future<List<NearbyPlace>> nearbyRestaurants({
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
    int limit = 40,
  }) async {
    final lat = latitude.toStringAsFixed(4);
    final lon = longitude.toStringAsFixed(4);

    // Overpass QL: restoran, kafe, fast food ve fırın.
    final query = '''
[out:json][timeout:30];
(
  node["amenity"~"^(restaurant|cafe|fast_food)\$"](around:$radiusMeters,$lat,$lon);
  way["amenity"~"^(restaurant|cafe|fast_food)\$"](around:$radiusMeters,$lat,$lon);
);
out center $limit;
''';

    final raw = await _api.overpassQuery(query);
    final body = jsonDecode(raw) as Map<String, dynamic>;
    final elements = (body['elements'] as List?) ?? const [];

    final places = <NearbyPlace>[];
    for (final e in elements) {
      if (e is! Map) continue;
      final tags = (e['tags'] as Map?) ?? const {};
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      double? plat;
      double? plon;
      if (e['lat'] is num && e['lon'] is num) {
        plat = (e['lat'] as num).toDouble();
        plon = (e['lon'] as num).toDouble();
      } else if (e['center'] is Map) {
        final c = e['center'] as Map;
        plat = (c['lat'] as num?)?.toDouble();
        plon = (c['lon'] as num?)?.toDouble();
      }
      if (plat == null || plon == null) continue;

      final street = tags['addr:street'] as String?;
      final number = tags['addr:housenumber'] as String?;
      final city = tags['addr:city'] as String?;
      final addressParts = <String>[
        if (street != null) [street, number].whereType<String>().join(' '),
        ?city,
      ];

      places.add(
        NearbyPlace(
          id: '${e['type']}/${e['id']}',
          name: name,
          latitude: plat,
          longitude: plon,
          straightLineMeters:
              haversineMeters(latitude, longitude, plat, plon),
          cuisine: tags['cuisine'] as String?,
          amenity: tags['amenity'] as String?,
          phone: (tags['phone'] ?? tags['contact:phone']) as String?,
          website: (tags['website'] ?? tags['contact:website']) as String?,
          openingHours: tags['opening_hours'] as String?,
          address: addressParts.isEmpty ? null : addressParts.join(', '),
        ),
      );
    }

    places.sort(
      (a, b) => a.straightLineMeters.compareTo(b.straightLineMeters),
    );
    return places;
  }

  /// OSRM ile araba ve yürüyüş süresi/mesafesi.
  ///
  /// OSRM'nin demo sunucusu bir istekte birçok hedefi destekler
  /// (table servisi), ancak ücretsiz sunucuda sınırlıdır.
  /// Bu yüzden en yakın [maxPlaces] mekan için tek tek route sorulur.
  Future<List<NearbyPlace>> addRouteTimes({
    required double fromLat,
    required double fromLon,
    required List<NearbyPlace> places,
    int maxPlaces = 12,
  }) async {
    final result = <NearbyPlace>[];
    for (var i = 0; i < places.length; i++) {
      final place = places[i];
      if (i >= maxPlaces) {
        result.add(place);
        continue;
      }
      final drive = await _route(
        Endpoints.osrmDriving,
        fromLat,
        fromLon,
        place.latitude,
        place.longitude,
      );
      final walk = await _route(
        Endpoints.osrmWalking,
        fromLat,
        fromLon,
        place.latitude,
        place.longitude,
      );
      result.add(
        place.withRoutes(
          driveMinutes: drive?.minutes,
          driveMeters: drive?.meters,
          walkMinutes: walk?.minutes,
          walkMeters: walk?.meters,
        ),
      );
    }
    return result;
  }

  Future<({double minutes, double meters})?> _route(
    String base,
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) async {
    final uri = Uri.parse(
      '$base/${fromLon.toStringAsFixed(5)},${fromLat.toStringAsFixed(5)};'
      '${toLon.toStringAsFixed(5)},${toLat.toStringAsFixed(5)}'
      '?overview=false&alternatives=false&steps=false',
    );
    try {
      final raw = await _api.cachedGet(
        uri,
        maxAge: const Duration(hours: 12),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(raw) as Map<String, dynamic>;
      if (body['code'] != 'Ok') return null;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes.first as Map<String, dynamic>;
      final duration = (r['duration'] as num?)?.toDouble();
      final distance = (r['distance'] as num?)?.toDouble();
      if (duration == null || distance == null) return null;
      return (minutes: duration / 60.0, meters: distance);
    } on ServiceFailure {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Adres -> koordinat (Nominatim).
  Future<({double lat, double lon, String displayName})?> geocode(
    String query,
  ) async {
    final uri = Uri.parse(Endpoints.nominatimSearch).replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '1',
        'addressdetails': '0',
      },
    );
    final raw = await _api.cachedGet(
      uri,
      maxAge: const Duration(days: 30),
      rateLimitNominatim: true,
    );
    final list = jsonDecode(raw);
    if (list is! List || list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return null;
    return (
      lat: lat,
      lon: lon,
      displayName: '${first['display_name'] ?? query}',
    );
  }

  /// Koordinat -> yer adı (Nominatim).
  Future<String?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(Endpoints.nominatimReverse).replace(
      queryParameters: {
        'lat': lat.toStringAsFixed(5),
        'lon': lon.toStringAsFixed(5),
        'format': 'json',
        'zoom': '12',
      },
    );
    try {
      final raw = await _api.cachedGet(
        uri,
        maxAge: const Duration(days: 7),
        rateLimitNominatim: true,
      );
      final body = jsonDecode(raw);
      if (body is! Map) return null;
      final addr = body['address'];
      if (addr is Map) {
        final city = (addr['city'] ?? addr['town'] ?? addr['village'] ??
            addr['county']) as String?;
        final state = addr['state'] as String?;
        if (city != null) {
          return state == null || state == city ? city : '$city, $state';
        }
      }
      return body['display_name'] as String?;
    } on ServiceFailure {
      return null;
    }
  }
}

/// İki koordinat arası kuş uçuşu mesafe (metre).
double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _rad(double deg) => deg * math.pi / 180.0;
