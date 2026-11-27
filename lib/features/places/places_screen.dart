import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import '../../clinical/cuisine_score.dart';
import '../../core/config/ai_config.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/api_client.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/places_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import '../../core/i18n/text.dart';

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  List<NearbyPlace> _places = const [];
  bool _loading = false;
  String? _errorTr;
  int _radius = 2000;
  bool _showMap = true;
  bool _routesLoaded = false;

  /// Liste Overpass'tan değil yedek kaynaktan geldi.
  bool _limited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _ensureLocation() async {
    final permission = ref.read(permissionServiceProvider);
    if (await permission.status(AppPermission.location) !=
        AppPermissionStatus.granted) {
      if (!mounted) return;
      final ok = await showPermissionDialog(
        context,
        permissionInfo(AppPermission.location),
      );
      if (!ok) return;
      if (await permission.request(AppPermission.location) !=
          AppPermissionStatus.granted) {
        return;
      }
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final place = await ref
          .read(placesServiceProvider)
          .reverseGeocode(pos.latitude, pos.longitude);
      await ref.read(locationProvider.notifier).save(
            LastLocation(
              latitude: pos.latitude,
              longitude: pos.longitude,
              placeName: place,
              at: DateTime.now(),
            ),
          );
    } on Object {
      // Son bilinen konum kullanılır.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorTr = null;
      _routesLoaded = false;
      _limited = false;
    });

    await _ensureLocation();
    final loc = ref.read(locationProvider);
    if (loc == null) {
      setState(() {
        _loading = false;
        _errorTr = 'Konum alınamadı. Yakındaki mekanları bulmak için '
            'konum izni gerekiyor.';
      });
      return;
    }

    try {
      final result = await ref.read(placesServiceProvider).nearbyRestaurants(
            latitude: loc.latitude,
            longitude: loc.longitude,
            radiusMeters: _radius,
          );
      if (!mounted) return;
      setState(() {
        _places = result.places;
        _limited = result.limited;
        _loading = false;
      });
    } on ServiceFailure catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorTr = e.messageTr;
        });
      }
    }
  }

  Future<void> _loadRoutes() async {
    final loc = ref.read(locationProvider);
    if (loc == null || _places.isEmpty) return;
    setState(() => _loading = true);
    final withRoutes = await ref.read(placesServiceProvider).addRouteTimes(
          fromLat: loc.latitude,
          fromLon: loc.longitude,
          places: _places,
        );
    if (!mounted) return;
    setState(() {
      _places = withRoutes;
      _loading = false;
      _routesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final loc = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('Yakındaki restoranlar'),
        actions: [
          TapIcon(
            icon: _showMap ? Icons.list_rounded : Icons.map_outlined,
            semanticLabel: _showMap ? 'Liste görünümü' : 'Harita görünümü',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          TapIcon(
            icon: Icons.refresh_rounded,
            semanticLabel: 'Yenile',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showMap && loc != null)
              SizedBox(
                height: r.s(230),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(r.s(20)),
                    bottomRight: Radius.circular(r.s(20)),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          LatLng(loc.latitude, loc.longitude),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all &
                            ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: Endpoints.osmTiles,
                        userAgentPackageName:
                            AppConfig.tileUserAgentPackage,
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(loc.latitude, loc.longitude),
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.my_location_rounded,
                              color: p.info,
                              size: 28,
                            ),
                          ),
                          for (final place in _places.take(40))
                            Marker(
                              point: LatLng(
                                place.latitude,
                                place.longitude,
                              ),
                              width: 30,
                              height: 30,
                              child: Icon(
                                Icons.place_rounded,
                                color: switch (adviseCuisine(
                                  place.cuisine,
                                  amenity: place.amenity,
                                ).suitability) {
                                  CuisineSuitability.good => p.success,
                                  CuisineSuitability.moderate => p.accent,
                                  CuisineSuitability.caution => p.danger,
                                  CuisineSuitability.unknown => p.textMuted,
                                },
                                size: 26,
                              ),
                            ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap katkıcıları',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://openstreetmap.org/copyright',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: PageBody(
                children: [
                  if (_loading)
                    const NeuCard(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 14),
                          Expanded(child: Text('Aranıyor…')),
                        ],
                      ),
                    ),

                  if (_errorTr != null)
                    NeuCard(
                      color: p.danger.withValues(alpha: 0.09),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _errorTr!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: r.gapSm),
                          NeuButton(
                            label: 'Tekrar dene',
                            compact: true,
                            filled: false,
                            expanded: true,
                            onPressed: _load,
                          ),
                        ],
                      ),
                    ),

                  if (_limited)
                    NeuCard(
                      color: p.info.withValues(alpha: 0.09),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: p.info,
                          ),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: Text(
                              'Ayrıntılı mekan servisi (Overpass) şu an '
                              'yanıt vermiyor. Liste yedek kaynaktan '
                              'geldi: daha az mekan ve daha az bilgi '
                              'içerebilir.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- mesafe seçimi ---
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arama yarıçapı: ${(_radius / 1000).toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Slider(
                          value: _radius.toDouble(),
                          min: 500,
                          max: 5000,
                          divisions: 9,
                          label: '${(_radius / 1000).toStringAsFixed(1)} km',
                          onChanged: (v) =>
                              setState(() => _radius = v.round()),
                          onChangeEnd: (_) => _load(),
                        ),
                        if (!_routesLoaded && _places.isNotEmpty)
                          NeuButton(
                            label: 'Araba/yürüyüş sürelerini hesapla',
                            icon: Icons.route_outlined,
                            compact: true,
                            filled: false,
                            expanded: true,
                            onPressed: _loading ? null : _loadRoutes,
                          ),
                      ],
                    ),
                  ),

                  if (_places.isEmpty && !_loading && _errorTr == null)
                    const EmptyState(
                      title: 'Yakında kayıtlı mekan bulunamadı',
                      message: 'OpenStreetMap verisinde bu yarıçapta '
                          'adı yazılı restoran/kafe yok. Yarıçapı '
                          'büyütmeyi dene.',
                      icon: Icons.not_listed_location_outlined,
                    ),

                  for (final place in _places)
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapSm),
                      child: _PlaceCard(place: place),
                    ),

                  if (_places.isNotEmpty)
                    NeuCard(
                      color: p.backgroundDeep.withValues(alpha: 0.45),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Veri kaynakları ve sınırları',
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                          SizedBox(height: r.gapSm),
                          Text(
                            'Mekan listesi OpenStreetMap (Overpass API), '
                            'süre/mesafe OSRM, yer adı Nominatim '
                            'verisinden gelir. Hepsi ücretsiz, '
                            'topluluk servisleridir: eksik veya eski '
                            'olabilir, yoğun saatlerde yanıt vermeyebilir.'
                            '\n\n$kMenuNotVerifiedTr',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends ConsumerStatefulWidget {
  const _PlaceCard({required this.place});

  final NearbyPlace place;

  @override
  ConsumerState<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends ConsumerState<_PlaceCard> {
  bool _expanded = false;
  bool _menuBusy = false;
  String? _menuAnalysis;
  String? _menuError;

  Future<void> _analyzeMenu() async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menü fotoğrafı yapay zekaya gönderilecek'),
        content: const Text(
          'Menünün fotoğrafı Anthropic Claude API sunucusuna '
          'gönderilir ve böbrek diyetine uygunluk açısından '
          'değerlendirilir.\n\n'
          'Yapay zeka menüde OLMAYAN yemekleri uydurmaması için '
          'özel olarak uyarılır; yine de sonucu kontrol et.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    if (consent != true) return;

    final permission = ref.read(permissionServiceProvider);
    if (await permission.status(AppPermission.camera) !=
        AppPermissionStatus.granted) {
      if (!mounted) return;
      final ok = await showPermissionDialog(
        context,
        permissionInfo(AppPermission.camera),
      );
      if (!ok) return;
      if (await permission.request(AppPermission.camera) !=
          AppPermissionStatus.granted) {
        return;
      }
    }

    final File? image =
        await ref.read(scannerServiceProvider).captureFromCamera(
              maxWidth: 1400,
            );
    if (image == null) return;

    setState(() {
      _menuBusy = true;
      _menuError = null;
    });
    try {
      final settings = ref.read(clinicalSettingsProvider);
      final prompt = ref
          .read(aiPromptBuilderProvider)
          .buildMenuVisionPrompt(settings: settings);
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;
      final reply = await ref.read(aiServiceProvider).sendVision(
            systemPrompt: prompt,
            userText: 'Bu menüyü değerlendir.',
            image: image,
            model: model,
          );
      if (!mounted) return;
      setState(() {
        _menuBusy = false;
        _menuAnalysis = reply.text;
      });
    } on AiFailure catch (e) {
      if (mounted) {
        setState(() {
          _menuBusy = false;
          _menuError = e.messageTr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final place = widget.place;
    final advice = adviseCuisine(place.cuisine, amenity: place.amenity);
    final conn = ref.watch(aiConnectionProvider).value;

    final tone = switch (advice.suitability) {
      CuisineSuitability.good => p.success,
      CuisineSuitability.moderate => p.accent,
      CuisineSuitability.caution => p.danger,
      CuisineSuitability.unknown => p.textMuted,
    };

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: r.s(2)),
                    Text(
                      [
                        if (place.cuisine != null) place.cuisine!,
                        '${(place.straightLineMeters / 1000).toStringAsFixed(1)} km',
                        if (place.address != null) place.address!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: tone.withValues(alpha: 0.35)),
                ),
                child: Text(
                  advice.suitability.labelTr,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: tone, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // --- süre / mesafe ---
          if (place.driveMinutes != null || place.walkMinutes != null) ...[
            SizedBox(height: r.gapSm),
            Row(
              children: [
                if (place.driveMinutes != null)
                  _TravelPill(
                    icon: Icons.directions_car_outlined,
                    label: '${place.driveMinutes!.round()} dk',
                    sub: '${(place.driveMeters! / 1000).toStringAsFixed(1)} km',
                  ),
                if (place.driveMinutes != null && place.walkMinutes != null)
                  SizedBox(width: r.gapSm),
                if (place.walkMinutes != null)
                  _TravelPill(
                    icon: Icons.directions_walk_rounded,
                    label: '${place.walkMinutes!.round()} dk',
                    sub: '${(place.walkMeters! / 1000).toStringAsFixed(1)} km',
                  ),
              ],
            ),
          ],

          SizedBox(height: r.gapSm),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 18,
            ),
            label: Text(_expanded ? 'Kapat' : 'Öneriler ve menü'),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: r.gapSm),
                Container(
                  padding: EdgeInsets.all(r.gapSm),
                  decoration: BoxDecoration(
                    color: p.backgroundDeep.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advice.reasonTr,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: r.gapSm),
                      for (final tip in advice.tipsTr)
                        Padding(
                          padding: EdgeInsets.only(bottom: r.gapXs),
                          child: Text(
                            '• $tip',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: r.gapSm),
                Container(
                  padding: EdgeInsets.all(r.gapSm),
                  decoration: BoxDecoration(
                    color: p.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: r.s(15),
                        color: p.danger,
                      ),
                      SizedBox(width: r.gapXs),
                      Expanded(
                        child: Text(
                          kMenuNotVerifiedTr,
                          style:
                              Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.gapMd),
                Text(
                  'Menüyü öğrenmenin iki yolu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: r.gapSm),
                NeuButton(
                  label: _menuBusy
                      ? 'Analiz ediliyor…'
                      : (conn == AiConnectionState.ok
                          ? 'Menü fotoğrafı çek ve analiz et'
                          : 'Menü analizi için bağlantı kur'),
                  icon: Icons.menu_book_outlined,
                  tone: NeuTone.accent,
                  compact: true,
                  expanded: true,
                  onPressed: _menuBusy
                      ? null
                      : (conn == AiConnectionState.ok
                          ? _analyzeMenu
                          : () => context.push(Routes.aiConnection)),
                ),
                SizedBox(height: r.gapSm),
                Row(
                  children: [
                    if (place.phone != null)
                      Expanded(
                        child: NeuButton(
                          label: 'Ara ve sor',
                          icon: Icons.call_outlined,
                          filled: false,
                          compact: true,
                          expanded: true,
                          onPressed: () => ref
                              .read(smsServiceProvider)
                              .call(place.phone!),
                        ),
                      ),
                    if (place.phone != null) SizedBox(width: r.gapSm),
                    Expanded(
                      child: NeuButton(
                        label: 'Haritada aç',
                        icon: Icons.map_outlined,
                        filled: false,
                        compact: true,
                        expanded: true,
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://www.openstreetmap.org/?mlat='
                            '${place.latitude}&mlon=${place.longitude}'
                            '#map=18/${place.latitude}/${place.longitude}',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                  ],
                ),
                if (place.openingHours != null) ...[
                  SizedBox(height: r.gapSm),
                  Text(
                    'Açılış (OSM verisi): ${place.openingHours}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
                if (_menuError != null) ...[
                  SizedBox(height: r.gapSm),
                  Text(
                    _menuError!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: p.danger),
                  ),
                ],
                if (_menuAnalysis != null) ...[
                  SizedBox(height: r.gapMd),
                  Container(
                    padding: EdgeInsets.all(r.gapMd),
                    decoration: BoxDecoration(
                      color: p.accentSoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: r.s(16),
                              color: p.accent,
                            ),
                            SizedBox(width: r.gapXs),
                            Text(
                              'Menü analizi',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                          ],
                        ),
                        SizedBox(height: r.gapSm),
                        SelectableText(
                          _menuAnalysis!,
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: r.gapSm),
                const SourceFootnote(
                  sourceIds: ['kdigo_ckd_2024', 'kdoqi_nutrition_2020'],
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
          ),
        ],
      ),
    );
  }
}

class _TravelPill extends StatelessWidget {
  const _TravelPill({
    required this.icon,
    required this.label,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.primarySoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: p.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(sub, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
