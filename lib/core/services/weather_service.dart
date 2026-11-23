import 'dart:convert';

import '../config/app_config.dart';
import 'api_client.dart';

/// Hava, UV ve hava kalitesi (Open-Meteo — anahtar gerektirmez).
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.humidity,
    required this.uvIndex,
    required this.uvIndexMaxToday,
    required this.maxTempToday,
    required this.precipitationProbability,
    required this.weatherCode,
    this.pm25,
    this.pm10,
    this.europeanAqi,
    this.pollenNote,
  });

  final double? temperatureC;
  final double? apparentTemperatureC;
  final int? humidity;
  final double? uvIndex;
  final double? uvIndexMaxToday;
  final double? maxTempToday;
  final int? precipitationProbability;
  final int? weatherCode;

  final double? pm25;
  final double? pm10;
  final int? europeanAqi;
  final String? pollenNote;

  /// Sıcak hava uyarısı eşiği: hissedilen ≥30 °C veya bugünün azamisi ≥32 °C.
  bool get isHot {
    final feels = apparentTemperatureC ?? temperatureC;
    if (feels != null && feels >= 30) return true;
    final mx = maxTempToday;
    return mx != null && mx >= 32;
  }

  bool get isUvHigh => (uvIndexMaxToday ?? uvIndex ?? 0) >= 6;

  bool get isAirPoor => (europeanAqi ?? 0) >= 60;

  String get conditionTr => switch (weatherCode) {
        0 => 'Açık',
        1 => 'Çoğunlukla açık',
        2 => 'Parçalı bulutlu',
        3 => 'Kapalı',
        45 || 48 => 'Puslu',
        51 || 53 || 55 => 'Çisenti',
        56 || 57 => 'Dondurucu çisenti',
        61 || 63 || 65 => 'Yağmurlu',
        66 || 67 => 'Dondurucu yağmur',
        71 || 73 || 75 || 77 => 'Karlı',
        80 || 81 || 82 => 'Sağanak',
        85 || 86 => 'Kar sağanağı',
        95 => 'Gök gürültülü',
        96 || 99 => 'Dolulu fırtına',
        _ => 'Bilinmiyor',
      };

  String get uvAdviceTr {
    final uv = uvIndexMaxToday ?? uvIndex;
    if (uv == null) return 'UV bilgisi yok.';
    if (uv >= 8) {
      return 'UV çok yüksek (${uv.toStringAsFixed(0)}). 11:00-16:00 arası '
          'gölgede kal, şapka ve güneş kremi kullan. Nakil hastalarında '
          'bağışıklık baskılayıcı ilaçlar cilt kanseri riskini artırır — '
          'güneşten korunma ayrıca önemlidir.';
    }
    if (uv >= 6) {
      return 'UV yüksek (${uv.toStringAsFixed(0)}). Öğle saatlerinde '
          'gölge ve güneş kremi iyi olur.';
    }
    if (uv >= 3) {
      return 'UV orta (${uv.toStringAsFixed(0)}). Uzun süre dışarıdaysan '
          'korun.';
    }
    return 'UV düşük (${uv.toStringAsFixed(0)}). Ek önlem gerekmez.';
  }

  String get airAdviceTr {
    final aqi = europeanAqi;
    if (aqi == null) return 'Hava kalitesi bilgisi yok.';
    if (aqi >= 100) {
      return 'Hava kalitesi kötü (AQI $aqi). Dışarıda ağır eforlu '
          'aktiviteden kaçın, pencereleri kapalı tut.';
    }
    if (aqi >= 60) {
      return 'Hava kalitesi orta-kötü (AQI $aqi). Hassasiyeti olanlar '
          'uzun süreli açık hava eforundan kaçınmalı.';
    }
    if (aqi >= 40) return 'Hava kalitesi orta (AQI $aqi).';
    return 'Hava kalitesi iyi (AQI $aqi).';
  }
}

class WeatherService {
  WeatherService(this._api);

  final ApiClient _api;

  /// Hava + UV + hava kalitesi. Önbellek 30 dakika.
  Future<WeatherSnapshot> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final lat = latitude.toStringAsFixed(3);
    final lon = longitude.toStringAsFixed(3);

    final forecastUri = Uri.parse(Endpoints.openMeteoForecast).replace(
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'weather_code,uv_index',
        'daily': 'uv_index_max,temperature_2m_max,'
            'precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': '1',
      },
    );

    final airUri = Uri.parse(Endpoints.openMeteoAirQuality).replace(
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'pm2_5,pm10,european_aqi',
        'timezone': 'auto',
      },
    );

    const cache = Duration(minutes: 30);

    final forecastRaw = await _api.cachedGet(forecastUri, maxAge: cache);
    final forecast = jsonDecode(forecastRaw) as Map<String, dynamic>;

    Map<String, dynamic>? air;
    try {
      final airRaw = await _api.cachedGet(airUri, maxAge: cache);
      air = jsonDecode(airRaw) as Map<String, dynamic>;
    } on ServiceFailure {
      // Hava kalitesi alınamazsa hava durumu yine gösterilir.
      air = null;
    }

    final current = forecast['current'] as Map<String, dynamic>?;
    final daily = forecast['daily'] as Map<String, dynamic>?;
    final airCurrent = air?['current'] as Map<String, dynamic>?;

    double? firstDouble(Object? list) {
      if (list is List && list.isNotEmpty) {
        final v = list.first;
        if (v is num) return v.toDouble();
      }
      return null;
    }

    int? firstInt(Object? list) {
      if (list is List && list.isNotEmpty) {
        final v = list.first;
        if (v is num) return v.round();
      }
      return null;
    }

    return WeatherSnapshot(
      temperatureC: (current?['temperature_2m'] as num?)?.toDouble(),
      apparentTemperatureC:
          (current?['apparent_temperature'] as num?)?.toDouble(),
      humidity: (current?['relative_humidity_2m'] as num?)?.round(),
      uvIndex: (current?['uv_index'] as num?)?.toDouble(),
      weatherCode: (current?['weather_code'] as num?)?.round(),
      uvIndexMaxToday: firstDouble(daily?['uv_index_max']),
      maxTempToday: firstDouble(daily?['temperature_2m_max']),
      precipitationProbability:
          firstInt(daily?['precipitation_probability_max']),
      pm25: (airCurrent?['pm2_5'] as num?)?.toDouble(),
      pm10: (airCurrent?['pm10'] as num?)?.toDouble(),
      europeanAqi: (airCurrent?['european_aqi'] as num?)?.round(),
    );
  }
}
