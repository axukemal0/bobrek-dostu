import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../clinical/definitions.dart';
import '../../clinical/evaluator.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/nutrient_meter.dart';
import '../../core/widgets/responsive.dart';
import '../medications/medication_logic.dart';
import 'day_tip.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _locating = false;

  Future<void> _refreshLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final status =
          await ref.read(permissionServiceProvider).status(AppPermission.location);
      if (status != AppPermissionStatus.granted) {
        final granted = await _askLocation();
        if (!granted) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
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
      ref.invalidate(weatherProvider);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tf('Konum alınamadı: {0}', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<bool> _askLocation() async {
    final info = permissionInfo(AppPermission.location);
    final ok = await showPermissionDialog(context, info);
    if (!ok) return false;
    final result =
        await ref.read(permissionServiceProvider).request(AppPermission.location);
    if (result != AppPermissionStatus.granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Konum izni verilmedi. Hava durumu ve yakın mekanlar '
            'çalışmaz; diğer her şey çalışır.',
          ),
        ),
      );
    }
    return result == AppPermissionStatus.granted;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final day = ref.watch(selectedDayProvider);
    final profile = ref.watch(profileProvider).value;
    final settings = ref.watch(clinicalSettingsProvider);
    final foods = ref.watch(foodLogsForDayProvider).value ?? const [];
    final fluids = ref.watch(fluidLogsForDayProvider).value ?? const [];
    final doses = ref.watch(dosesForDayProvider).value ?? const [];
    final meds = ref.watch(medicationsProvider).value ?? const [];
    final weather = ref.watch(weatherProvider);
    final location = ref.watch(locationProvider);

    // --- sıvı bütçesi ---
    final fluidFromDrinks =
        fluids.fold<int>(0, (a, b) => a + b.ml);
    final fluidFromFood = foods
        .map((f) => f.fluidMl ?? 0)
        .fold<double>(0, (a, b) => a + b);
    final fluidLimit = settings.resolve('fluid_ml');
    final budget = computeFluidBudget(
      consumedMl: fluidFromDrinks + fluidFromFood.round(),
      limitMl: fluidLimit.isCleared ? null : fluidLimit.value?.round(),
    );

    // --- besin ---
    final nutrition = computeDailyNutrition(
      entries: [
        for (final f in foods)
          FoodEntryValues(
            grams: 100,
            kcalPer100g: f.kcal,
            proteinPer100g: f.proteinG,
            sodiumMgPer100g: f.sodiumMg,
            potassiumMgPer100g: f.potassiumMg,
            phosphorusMgPer100g: f.phosphorusMg,
          ),
      ],
      settings: settings,
    );

    // --- sıradaki ilaç ---
    final nextDose = nextPendingDose(doses, meds);

    final greeting = _greeting();
    final tip = tipForDay(day);

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  r.gapMd,
                  r.pagePadding,
                  0,
                ),
                child: ContentColumn(
                  // Başlık yeniden kuruldu.
                  //
                  // Önceden küçük gri bir "İyi akşamlar" yazısının
                  // altına ad geliyordu: selam, adın üstünde asılı
                  // duran etiketsiz bir not gibi duruyor ve günün
                  // hangi saatinde olduğumuz dışında hiçbir şey
                  // söylemiyordu. Artık üstte TARİH (günün hangi günü
                  // olduğunu bilmek takvim ve diyaliz günleri için
                  // gerçekten işe yarıyor), altta tek cümlelik selam
                  // ve ad birlikte; yanında günün saatine göre
                  // renklenen bir simge var.
                  child: Row(
                    children: [
                      AccentTile(
                        icon: greeting.icon,
                        color: greeting.tone(p),
                        size: r.s(22),
                      ),
                      SizedBox(width: r.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatTurkishDate(DateTime.now()),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: greeting.tone(p),
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            SizedBox(height: r.s(2)),
                            Text(
                              greeting.sentenceFor(profile?.name),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      TapIcon(
                        icon: Icons.settings_outlined,
                        semanticLabel: 'Ayarlar',
                        onPressed: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: PageBody(
                padBottom: true,
                children: [
                  // --- ACİL DURUM ---
                  _EmergencyBar(),

                  // --- SIVI HALKASI ---
                  NeuCard(
                    onTap: () => context.go(Routes.fluid),
                    semanticLabel: 'Sıvı bütçesi, aç',
                    child: Row(
                      children: [
                        ProgressRing(
                          ratio: budget.ratio,
                          label: 'Sıvı',
                          valueText: '${budget.consumedMl}',
                          unitText: 'mL',
                          size: r.s(112),
                          tone: p.accents.fluid,
                        ),
                        SizedBox(width: r.gapMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sıvı bütçesi',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              SizedBox(height: r.gapXs),
                              Text(
                                fluidAdviceTr(
                                  budget,
                                  hotWeather:
                                      weather.value?.isHot ?? false,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                              if (fluidFromFood > 0) ...[
                                SizedBox(height: r.gapXs),
                                Text(
                                  tf(
                                    'Bunun {0} mL\'si yemekten (çorba, meyve vb.)',
                                    [fluidFromFood.round()],
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- BESİN HALKALARI ---
                  NeuCard(
                    onTap: () => context.go(Routes.nutrition),
                    semanticLabel: 'Besin takibi, aç',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Bugünün besinleri',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                            const ApproximateBadge(
                              tooltipTr:
                                  'Besin değerleri yaklaşıktır; '
                                  'porsiyon ve tarife göre değişir.',
                            ),
                          ],
                        ),
                        SizedBox(height: r.gapMd),
                        for (final n in nutrition.all)
                          NutrientMeter(total: n),
                        if (foods.isEmpty) ...[
                          SizedBox(height: r.gapSm),
                          Text(
                            'Bugün henüz yemek eklenmedi.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (nutrition.exceeded.isNotEmpty) ...[
                          SizedBox(height: r.gapSm),
                          for (final n in nutrition.exceeded)
                            Padding(
                              padding: EdgeInsets.only(bottom: r.gapXs),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: r.s(15),
                                    color: p.warning,
                                  ),
                                  SizedBox(width: r.gapXs),
                                  Expanded(
                                    child: Text(
                                      nutrientExceededAdviceTr(n),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  // --- SIRADAKİ İLAÇ ---
                  NeuCard(
                    onTap: () => context.go(Routes.medications),
                    semanticLabel: 'İlaçlar, aç',
                    child: Row(
                      children: [
                        AccentTile(
                          icon: Icons.medication_rounded,
                          color: p.accents.medication,
                        ),
                        SizedBox(width: r.gapMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sıradaki ilaç',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall,
                              ),
                              SizedBox(height: r.s(2)),
                              Text(
                                nextDose == null
                                    ? (meds.isEmpty
                                        ? 'Henüz ilaç tanımlanmadı'
                                        : 'Bugün için kalan doz yok')
                                    : '${nextDose.medicationName} · '
                                        '${_hm(nextDose.scheduledAt)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: p.textMuted,
                        ),
                      ],
                    ),
                  ),

                  // --- ADIM ---
                  _StepsCard(),

                  // --- HAVA / UV / HAVA KALİTESİ ---
                  _WeatherCard(
                    weather: weather,
                    location: location,
                    locating: _locating,
                    onRefresh: _refreshLocation,
                    budget: budget,
                  ),

                  // --- GÜNÜN NOTU ---
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: p.accent,
                              size: r.s(19),
                            ),
                            SizedBox(width: r.gapSm),
                            Text(
                              'Günün notu',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: r.gapSm),
                        Text(
                          tip.textTr,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: r.gapSm),
                        Text(
                          'Kaynak: ${tip.sourceTr} · $kReferenceCaveatTr',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),

                  // --- HIZLI ERİŞİM ---
                  AdaptiveGrid(
                    children: [
                      _QuickTile(
                        icon: Icons.science_outlined,
                        label: 'Tahlil',
                        route: Routes.labs,
                        tone: p.accents.lab,
                      ),
                      _QuickTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Kilo & tansiyon',
                        route: Routes.weight,
                        tone: p.accents.weight,
                      ),
                      _QuickTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Takvim',
                        route: Routes.calendar,
                        tone: p.accents.appointment,
                      ),
                      _QuickTile(
                        icon: Icons.auto_awesome_outlined,
                        label: 'Yapay zeka',
                        route: Routes.ai,
                        tone: p.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Greeting _greeting() => Greeting.now();

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _EmergencyBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return Semantics(
      button: true,
      label: 'Acil durum ekranını aç',
      child: InkWell(
        onTap: () => context.push(Routes.emergency),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.gapMd,
            vertical: r.gapSm,
          ),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: p.danger.withValues(alpha: p.isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.danger.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.emergency_rounded, color: p.danger, size: r.s(24)),
              SizedBox(width: r.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acil durum',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.danger),
                    ),
                    Text(
                      '112\'yi ara · yakınlarına konum ve bilgi gönder',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.danger),
            ],
          ),
        ),
      ),
    );
  }
}

/// Günün adım sayısı. Health Connect izni yoksa izin isteme kartı olur.
class _StepsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final steps = ref.watch(todayStepsProvider);

    return NeuCard(
      onTap: () => context.push(Routes.health),
      semanticLabel: 'Sağlık verisi ekranını aç',
      child: Row(
        children: [
          AccentTile(
            icon: Icons.directions_walk_rounded,
            color: p.accents.activity,
          ),
          SizedBox(width: r.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugünün adımı',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: r.s(2)),
                steps.when(
                  loading: () => Text(
                    'okunuyor…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  error: (_, _) => Text(
                    'okunamadı',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  data: (value) => value == null
                      ? Text(
                          Platform.isIOS
                              ? 'Sağlık verisi izni verilmedi'
                              : 'Health Connect izni verilmedi',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$value',
                                style: AppTypography.numeric(
                                  p,
                                  size: r.s(22),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'adım',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.weather,
    required this.location,
    required this.locating,
    required this.onRefresh,
    required this.budget,
  });

  final AsyncValue<WeatherSnapshot?> weather;
  final LastLocation? location;
  final bool locating;
  final VoidCallback onRefresh;
  final FluidBudget budget;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    if (location == null) {
      return NeuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: p.accent),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: Text(
                    'Hava, UV ve hava kalitesi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapSm),
            Text(
              'Konum izni verirsen bulunduğun yerin sıcaklık, UV ve '
              'hava kalitesi bilgisini gösterebilirim. Sıcak havada '
              'uyarı metinleri SIVI LİMİTİNE saygı duyar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: r.gapMd),
            NeuButton(
              label: locating ? 'Konum alınıyor…' : 'Konumu kullan',
              icon: Icons.my_location_rounded,
              compact: true,
              expanded: true,
              onPressed: locating ? null : onRefresh,
            ),
          ],
        ),
      );
    }

    return weather.when(
      loading: () => NeuCard(
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: r.gapMd),
            Text(
              'Hava bilgisi alınıyor…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      error: (e, _) => NeuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hava bilgisi alınamadı',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: r.gapXs),
            Text(
              '$e',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: r.gapSm),
            NeuButton(
              label: 'Tekrar dene',
              compact: true,
              filled: false,
              onPressed: onRefresh,
            ),
          ],
        ),
      ),
      data: (w) {
        if (w == null) return const SizedBox.shrink();
        return NeuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location?.placeName ?? 'Bulunduğun yer',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${w.temperatureC?.toStringAsFixed(0) ?? "—"}°C · '
                          '${w.conditionTr}',
                          style: AppTypography.numeric(p, size: r.s(22)),
                        ),
                        if (w.apparentTemperatureC != null)
                          Text(
                            'Hissedilen '
                            '${w.apparentTemperatureC!.toStringAsFixed(0)}°C',
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                  TapIcon(
                    icon: Icons.refresh_rounded,
                    semanticLabel: 'Konumu ve havayı yenile',
                    onPressed: locating ? null : onRefresh,
                  ),
                ],
              ),
              SizedBox(height: r.gapSm),
              Wrap(
                spacing: r.gapSm,
                runSpacing: r.gapXs,
                children: [
                  _Pill(
                    icon: Icons.wb_sunny_outlined,
                    label: 'UV '
                        '${(w.uvIndexMaxToday ?? w.uvIndex)?.toStringAsFixed(0) ?? "—"}',
                    tone: w.isUvHigh ? p.warning : p.primary,
                  ),
                  _Pill(
                    icon: Icons.air_rounded,
                    label: 'AQI ${w.europeanAqi ?? "—"}',
                    tone: w.isAirPoor ? p.warning : p.primary,
                  ),
                  if (w.humidity != null)
                    _Pill(
                      icon: Icons.water_outlined,
                      label: 'Nem %${w.humidity}',
                      tone: p.info,
                    ),
                ],
              ),
              if (w.isHot) ...[
                SizedBox(height: r.gapSm),
                Container(
                  padding: EdgeInsets.all(r.gapSm),
                  decoration: BoxDecoration(
                    color: p.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fluidAdviceTr(budget, hotWeather: true),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              if (w.isUvHigh) ...[
                SizedBox(height: r.gapXs),
                Text(
                  w.uvAdviceTr,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              if (w.isAirPoor) ...[
                SizedBox(height: r.gapXs),
                Text(
                  w.airAdviceTr,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              SizedBox(height: r.gapXs),
              Text(
                'Kaynak: Open-Meteo (anahtar gerektirmez)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.tone});

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: tone, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Gideceği alanın rengi — kart okunmadan nereye götürdüğü anlaşılsın.
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return NeuCard(
      onTap: () => context.push(route),
      semanticLabel: label,
      padding: EdgeInsets.symmetric(
        horizontal: r.gapMd,
        vertical: r.gapMd,
      ),
      child: Row(
        children: [
          AccentTile(icon: icon, color: tone, size: r.s(20)),
          SizedBox(width: r.gapSm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted, size: 18),
        ],
      ),
    );
  }
}

/// İzin gerekçesini gösterip onay alan diyalog.
Future<bool> showPermissionDialog(
  BuildContext context,
  PermissionInfo info,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(info.titleTr),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tf('Nerede kullanılıyor: {0}', [info.featureTr]),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Text(info.whyTr),
            if (info.optional) ...[
              const SizedBox(height: 10),
              Text(
                'İzin vermezsen uygulamanın geri kalanı çalışmaya '
                'devam eder.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Şimdi değil'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('İzin isteyebilirsin'),
        ),
      ],
    ),
  );
  return result ?? false;
}


// ---------------------------------------------------------------------------
// SELAMLAMA
// ---------------------------------------------------------------------------

/// Günün saatine göre selam, simge ve renk.
///
/// Tek bir kelimeden ibaret olmaması önemli: ad varsa cümle "İyi
/// akşamlar, Kemal" olur; yoksa selam tek başına durur ve altında
/// boşlukta kalan bir "Böbrek Dostu" yazısı belirmez.
enum Greeting {
  night,
  morning,
  day,
  evening;

  static Greeting now({DateTime? at}) {
    final h = (at ?? DateTime.now()).hour;
    if (h < 5 || h >= 21) return Greeting.night;
    if (h < 11) return Greeting.morning;
    if (h < 17) return Greeting.day;
    return Greeting.evening;
  }

  String get wordTr => switch (this) {
        Greeting.night => 'İyi geceler',
        Greeting.morning => 'Günaydın',
        Greeting.day => 'İyi günler',
        Greeting.evening => 'İyi akşamlar',
      };

  IconData get icon => switch (this) {
        Greeting.night => Icons.nightlight_round,
        Greeting.morning => Icons.wb_twilight_rounded,
        Greeting.day => Icons.wb_sunny_rounded,
        Greeting.evening => Icons.nights_stay_outlined,
      };

  Color tone(AppPalette p) => switch (this) {
        Greeting.night => p.accents.medication,
        Greeting.morning => p.accents.energy,
        Greeting.day => p.accents.activity,
        Greeting.evening => p.accents.appointment,
      };

  /// "İyi akşamlar, Kemal" — ad yoksa yalnız selam.
  String sentenceFor(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return wordTr;
    // Yalnız ilk ad: tam ad başlığı iki satıra taşırıyordu.
    final first = trimmed.split(RegExp(r'\s+')).first;
    return '$wordTr, $first';
  }
}

const List<String> _trWeekdays = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
];

const List<String> _trMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

/// "27 Kasım, Cuma" — cihaz diline bağlı değil, her zaman Türkçe.
String formatTurkishDate(DateTime d) =>
    '${d.day} ${_trMonths[d.month - 1]}, ${_trWeekdays[d.weekday - 1]}';
