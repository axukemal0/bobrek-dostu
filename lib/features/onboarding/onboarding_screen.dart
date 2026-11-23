import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/definitions.dart';
import '../../clinical/settings.dart';
import '../../core/config/app_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/drop_leaf_logo.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';
import '../settings/clinical_settings_screen.dart';

/// İlk kurulum testi: adım adım, görselli.
///
/// Sonuçlar tüm uygulamayı kişiselleştirir: klinik ayarlar bu
/// cevaplara göre ön doldurulur.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  // --- form durumu ---
  final _name = TextEditingController();
  final _birthYear = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _dryWeight = TextEditingController();
  final _comorbidities = TextEditingController();
  final _allergies = TextEditingController();
  final _disliked = TextEditingController();
  final _doctorName = TextEditingController();
  final _doctorPhone = TextEditingController();
  final _hospital = TextEditingController();

  TreatmentMode _mode = TreatmentMode.unknown;
  final Set<int> _dialysisDays = {};
  bool _hasResidualUrine = true;
  bool _expertMode = false;
  final Set<String> _selectedComorbidities = {};

  final List<({TextEditingController name, TextEditingController dose,
          TextEditingController times})> _meds = [];
  final List<({TextEditingController name, TextEditingController phone,
          TextEditingController relation})> _contacts = [];

  bool _saving = false;

  static const List<String> _comorbidityOptions = [
    'Diyabet',
    'Hipertansiyon',
    'Kalp hastalığı',
    'Anemi',
    'Gut',
    'Tiroid hastalığı',
    'Kemik hastalığı',
    'Astım / KOAH',
  ];

  @override
  void initState() {
    super.initState();
    _addMed();
    _addContact();
  }

  @override
  void dispose() {
    _page.dispose();
    for (final c in [
      _name, _birthYear, _height, _weight, _dryWeight,
      _comorbidities, _allergies, _disliked,
      _doctorName, _doctorPhone, _hospital,
    ]) {
      c.dispose();
    }
    for (final m in _meds) {
      m.name.dispose();
      m.dose.dispose();
      m.times.dispose();
    }
    for (final c in _contacts) {
      c.name.dispose();
      c.phone.dispose();
      c.relation.dispose();
    }
    super.dispose();
  }

  void _addMed() => setState(() => _meds.add((
        name: TextEditingController(),
        dose: TextEditingController(),
        times: TextEditingController(text: '08:00'),
      )));

  void _addContact() => setState(() => _contacts.add((
        name: TextEditingController(),
        phone: TextEditingController(),
        relation: TextEditingController(),
      )));

  List<_Step> get _steps => [
        _Step('Hoş geldin', _welcomeStep),
        _Step('Seni tanıyalım', _identityStep),
        _Step('Boy ve kilo', _bodyStep),
        _Step('Böbrek durumu', _treatmentStep),
        _Step('Diğer hastalıklar', _comorbidityStep),
        _Step('Alerji ve yemek', _foodStep),
        _Step('İlaçların', _medsStep),
        _Step('Doktorun', _doctorStep),
        _Step('Acil durum kişileri', _contactsStep),
        _Step('Klinik ayarlar', _clinicalStep),
        _Step('Yapay zeka bağlantısı', _aiStep),
        _Step('Hazırsın', _doneStep),
      ];

  bool get _canContinue {
    switch (_index) {
      case 1:
        return _name.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (_index == _steps.length - 1) {
      await _finish();
      return;
    }
    setState(() => _index++);
    await _page.animateToPage(
      _index,
      duration: context.motion.normal == Duration.zero
          ? const Duration(milliseconds: 1)
          : context.motion.normal,
      curve: context.motion.enter,
    );
  }

  Future<void> _back() async {
    if (_index == 0) return;
    setState(() => _index--);
    await _page.animateToPage(
      _index,
      duration: context.motion.normal == Duration.zero
          ? const Duration(milliseconds: 1)
          : context.motion.normal,
      curve: context.motion.enter,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    final weight = parseLocaleNumber(_weight.text);
    final dryWeight = parseLocaleNumber(_dryWeight.text);

    // Profil
    final comorbidityText = [
      ..._selectedComorbidities,
      if (_comorbidities.text.trim().isNotEmpty) _comorbidities.text.trim(),
    ].join(', ');

    await db.into(db.profileRows).insertOnConflictUpdate(
          ProfileRowsCompanion.insert(
            id: const Value(1),
            name: _name.text.trim(),
            birthYear: Value(parseLocaleInt(_birthYear.text)),
            heightCm: Value(parseLocaleNumber(_height.text)),
            weightKg: Value(weight),
            treatmentMode: _mode.name,
            dialysisDays: Value(
              _dialysisDays.isEmpty
                  ? null
                  : (_dialysisDays.toList()..sort()).join(','),
            ),
            comorbidities:
                Value(comorbidityText.isEmpty ? null : comorbidityText),
            allergies: Value(
              _allergies.text.trim().isEmpty ? null : _allergies.text.trim(),
            ),
            dislikedFoods: Value(
              _disliked.text.trim().isEmpty ? null : _disliked.text.trim(),
            ),
            doctorName: Value(
              _doctorName.text.trim().isEmpty ? null : _doctorName.text.trim(),
            ),
            doctorPhone: Value(
              _doctorPhone.text.trim().isEmpty
                  ? null
                  : _doctorPhone.text.trim(),
            ),
            hospital: Value(
              _hospital.text.trim().isEmpty ? null : _hospital.text.trim(),
            ),
            expertMode: Value(_expertMode),
          ),
        );

    // İlaçlar
    var order = 0;
    for (final m in _meds) {
      final name = m.name.text.trim();
      if (name.isEmpty) continue;
      final times = m.times.text.trim().isEmpty ? '08:00' : m.times.text.trim();
      await db.into(db.medicationRows).insert(
            MedicationRowsCompanion.insert(
              name: name,
              dose: Value(m.dose.text.trim().isEmpty ? null : m.dose.text.trim()),
              times: times,
            ),
          );
      order++;
    }

    // Acil kişiler
    order = 0;
    for (final c in _contacts) {
      final name = c.name.text.trim();
      final phone = c.phone.text.trim();
      if (name.isEmpty || phone.isEmpty) continue;
      await db.into(db.emergencyContactRows).insert(
            EmergencyContactRowsCompanion.insert(
              name: name,
              phone: phone,
              relation: Value(
                c.relation.text.trim().isEmpty ? null : c.relation.text.trim(),
              ),
              sortOrder: Value(order++),
            ),
          );
    }

    // Klinik ayarlar
    final clinical = ref.read(clinicalSettingsProvider.notifier);
    await clinical.setTreatmentMode(_mode);
    await clinical.setBodyWeight(weight);
    if (dryWeight != null) await clinical.setDryWeight(dryWeight);
    await clinical.setResidualUrine(_hasResidualUrine);

    // Kurulum tamam
    await ref.read(preferencesProvider.notifier).update(
          (p) => p.copyWith(onboardingCompleted: true),
        );

    if (!mounted) return;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final steps = _steps;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- ilerleme ---
            Padding(
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                r.gapMd,
                r.pagePadding,
                r.gapSm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_index > 0)
                        TapIcon(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: 'Geri',
                          onPressed: _back,
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          steps[_index].title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Center(
                          child: Text(
                            '${_index + 1}/${steps.length}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: (_index + 1) / steps.length,
                      ),
                      duration: context.motion.normal,
                      curve: context.motion.enter,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 7,
                        backgroundColor: p.backgroundDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- adımlar ---
            Expanded(
              child: PageView.builder(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, i) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    r.pagePadding,
                    r.gapSm,
                    r.pagePadding,
                    r.gapLg,
                  ),
                  child: ContentColumn(child: steps[i].builder(context)),
                ),
              ),
            ),

            // --- alt butonlar ---
            Container(
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                r.gapSm,
                r.pagePadding,
                r.gapMd,
              ),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.divider)),
              ),
              child: ContentColumn(
                child: Row(
                  children: [
                    if (_index > 0) ...[
                      Expanded(
                        child: NeuButton(
                          label: 'Geri',
                          filled: false,
                          expanded: true,
                          onPressed: _back,
                        ),
                      ),
                      SizedBox(width: r.gapSm),
                    ],
                    Expanded(
                      flex: 2,
                      child: NeuButton(
                        label: _saving
                            ? 'Kaydediliyor…'
                            : (_index == steps.length - 1
                                ? 'Uygulamayı başlat'
                                : 'Devam'),
                        icon: _index == steps.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        expanded: true,
                        onPressed:
                            _saving || !_canContinue ? null : _next,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================== ADIMLAR ===========================

  Widget _welcomeStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      children: [
        SizedBox(height: r.gapMd),
        Hero(
          tag: 'app-mark',
          child: DropLeafMark(size: r.s(110), animate: false),
        ),
        SizedBox(height: r.gapLg),
        Text(
          AppConfig.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        SizedBox(height: r.gapSm),
        Text(
          'Birkaç soruyla uygulamayı sana göre ayarlayacağım. '
          'Hepsini sonradan Ayarlar\'dan değiştirebilirsin.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: r.gapLg),
        const MedicalDisclaimerBanner(),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: r.s(18),
                    color: context.palette.primary,
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: Text(
                      'Gizlilik',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.gapSm),
              Text(
                kPrivacyNoteTr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _identityStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.person_outline_rounded,
          text: 'Uygulama tek kişi için: adın yalnızca ekranlarda ve '
              'doktor raporunda görünür, hiçbir yere gönderilmez.',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            children: [
              LabeledField(
                label: 'Ad',
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Örn. Ahmet',
                  ),
                ),
              ),
              SizedBox(height: r.gapMd),
              LabeledField(
                label: 'Doğum yılı',
                hint: 'Yaş hesaplaması ve raporda kullanılır.',
                child: NumberField(
                  controller: _birthYear,
                  allowDecimal: false,
                  hintText: 'Örn. 1958',
                ),
              ),
              SizedBox(height: r.gapMd),
              SwitchListTile.adaptive(
                value: _expertMode,
                onChanged: (v) => setState(() => _expertMode = v),
                title: const Text('Uzman modu'),
                subtitle: const Text(
                  'Hekimsen aç: yapay zeka daha teknik dil kullanır, '
                  'kılavuz öneri numaraları ve kanıt düzeyleri verir.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bodyStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.straighten_rounded,
          text: 'Kilo, protein ve enerji hedeflerinin hesaplanmasında '
              'kullanılır (g/kg/gün × kilo).',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            children: [
              LabeledField(
                label: 'Boy',
                child: NumberField(
                  controller: _height,
                  suffix: 'cm',
                  hintText: '170',
                ),
              ),
              SizedBox(height: r.gapMd),
              LabeledField(
                label: 'Kilo',
                child: NumberField(
                  controller: _weight,
                  suffix: 'kg',
                  hintText: '72,5',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (parseLocaleNumber(_weight.text) != null) ...[
                SizedBox(height: r.gapMd),
                Container(
                  padding: EdgeInsets.all(r.gapSm),
                  decoration: BoxDecoration(
                    color: context.palette.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Bu kiloyla varsayılan protein hedefi: '
                    '${(0.8 * parseLocaleNumber(_weight.text)!).toStringAsFixed(0)} g/gün '
                    '(0,8 g/kg/gün — KDIGO 2024). '
                    'Diyaliz seçersen KDOQI 2020\'ye göre '
                    '${(1.0 * parseLocaleNumber(_weight.text)!).toStringAsFixed(0)} g/gün '
                    'önerilir. Hepsini sonra değiştirebilirsin.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _treatmentStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.medical_information_outlined,
          text: 'Bu seçim protein hedefini, sıvı yaklaşımını ve hangi '
              'alarmların açılacağını belirler. Emin değilsen '
              '"Bilmiyorum" seç — sonra değiştirebilirsin.',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'Durumun',
                child: ChipSelector<TreatmentMode>(
                  options: TreatmentMode.values,
                  selected: _mode,
                  labelOf: (m) => m.labelTr,
                  onSelected: (m) => setState(() => _mode = m),
                ),
              ),
              if (_mode == TreatmentMode.hemodialysis) ...[
                SizedBox(height: r.gapLg),
                LabeledField(
                  label: 'Diyaliz günleri',
                  hint: 'Hatırlatmalar ve takvim bu günlere göre kurulur.',
                  child: WeekdayPicker(
                    selected: _dialysisDays,
                    onToggle: (d) => setState(() {
                      if (!_dialysisDays.remove(d)) _dialysisDays.add(d);
                    }),
                  ),
                ),
              ],
              if (_mode.isDialysis) ...[
                SizedBox(height: r.gapLg),
                LabeledField(
                  label: 'Kuru ağırlık',
                  hint: 'Diyaliz arası kilo artışı yüzdesi bununla '
                      'hesaplanır. Bilmiyorsan boş bırak.',
                  child: NumberField(
                    controller: _dryWeight,
                    suffix: 'kg',
                    hintText: '70',
                  ),
                ),
                SizedBox(height: r.gapMd),
                SwitchListTile.adaptive(
                  value: _hasResidualUrine,
                  onChanged: (v) => setState(() => _hasResidualUrine = v),
                  title: const Text('Rezidüel idrar çıkışım var'),
                  subtitle: const Text(
                    'Kapatırsan "idrar azaldı" alarmı devre dışı kalır '
                    '(anürik hastada bu alarm anlamsızdır).',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _comorbidityStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.fact_check_outlined,
          text: 'Diyabet varsa protein aralığı değişir (KDOQI 2020: '
              'diyabetli CKD 3-5\'te 0,6-0,8 g/kg/gün). '
              'Yapay zeka da bunları dikkate alır.',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'Sende olanları seç',
                child: MultiChipSelector(
                  options: _comorbidityOptions,
                  selected: _selectedComorbidities,
                  onToggle: (o) => setState(() {
                    if (!_selectedComorbidities.remove(o)) {
                      _selectedComorbidities.add(o);
                    }
                  }),
                ),
              ),
              SizedBox(height: r.gapLg),
              LabeledField(
                label: 'Listede olmayanlar',
                child: TextField(
                  controller: _comorbidities,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Örn. prostat büyümesi, katarakt…',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _foodStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.no_food_outlined,
          text: 'Yemek önerileri ve seyahat planları bunlara saygı duyar.',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            children: [
              LabeledField(
                label: 'Alerjiler',
                hint: 'Acil durum mesajında da yer alır — bu yüzden '
                    'önemlidir.',
                child: TextField(
                  controller: _allergies,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Örn. penisilin, fıstık…',
                  ),
                ),
              ),
              SizedBox(height: r.gapLg),
              LabeledField(
                label: 'Sevmediğin yemekler',
                child: TextField(
                  controller: _disliked,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Örn. karnabahar, ciğer…',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medsStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.medication_outlined,
          text: 'Şimdi eklemek zorunda değilsin; İlaç ekranından sonra '
              'da ekleyebilirsin. Eklediğin her ilaç böbrek güvenliği '
              'açısından taranır.',
        ),
        SizedBox(height: r.gapMd),
        for (var i = 0; i < _meds.length; i++) ...[
          NeuCard(
            margin: EdgeInsets.only(bottom: r.gapSm),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _meds[i].name,
                        decoration: InputDecoration(
                          labelText: 'İlaç ${i + 1}',
                          hintText: 'Örn. Renagel',
                        ),
                      ),
                    ),
                    if (_meds.length > 1)
                      TapIcon(
                        icon: Icons.delete_outline_rounded,
                        semanticLabel: 'İlacı kaldır',
                        onPressed: () => setState(() => _meds.removeAt(i)),
                      ),
                  ],
                ),
                SizedBox(height: r.gapSm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _meds[i].dose,
                        decoration: const InputDecoration(
                          labelText: 'Doz',
                          hintText: '800 mg',
                        ),
                      ),
                    ),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      child: TextField(
                        controller: _meds[i].times,
                        decoration: const InputDecoration(
                          labelText: 'Saatler',
                          hintText: '08:00,20:00',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        NeuButton(
          label: 'İlaç ekle',
          icon: Icons.add_rounded,
          filled: false,
          expanded: true,
          onPressed: _addMed,
        ),
      ],
    );
  }

  Widget _doctorStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.local_hospital_outlined,
          text: 'Acil durum mesajına eklenir ve tek dokunuşla '
              'arayabilirsin.',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            children: [
              LabeledField(
                label: 'Doktorun adı',
                child: TextField(
                  controller: _doctorName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Örn. Dr. Ayşe Yılmaz',
                  ),
                ),
              ),
              SizedBox(height: r.gapMd),
              LabeledField(
                label: 'Telefon',
                child: TextField(
                  controller: _doctorPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '0212 000 00 00',
                  ),
                ),
              ),
              SizedBox(height: r.gapMd),
              LabeledField(
                label: 'Hastane / diyaliz merkezi',
                child: TextField(
                  controller: _hospital,
                  decoration: const InputDecoration(
                    hintText: 'Örn. X Diyaliz Merkezi',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactsStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.contact_emergency_outlined,
          text: 'Acil durum butonuna bastığında bu kişilere konumun ve '
              'kritik bilgilerin gönderilir. Otomatik gönderim '
              'VARSAYILAN OLARAK KAPALIDIR; mesaj hazırlanır, gönder '
              'tuşuna sen basarsın.',
        ),
        SizedBox(height: r.gapMd),
        for (var i = 0; i < _contacts.length; i++)
          NeuCard(
            margin: EdgeInsets.only(bottom: r.gapSm),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contacts[i].name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Kişi ${i + 1}',
                          hintText: 'Örn. Mehmet (oğlu)',
                        ),
                      ),
                    ),
                    if (_contacts.length > 1)
                      TapIcon(
                        icon: Icons.delete_outline_rounded,
                        semanticLabel: 'Kişiyi kaldır',
                        onPressed: () =>
                            setState(() => _contacts.removeAt(i)),
                      ),
                  ],
                ),
                SizedBox(height: r.gapSm),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _contacts[i].phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          hintText: '0532 000 00 00',
                        ),
                      ),
                    ),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _contacts[i].relation,
                        decoration: const InputDecoration(
                          labelText: 'Yakınlık',
                          hintText: 'Oğlu',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        NeuButton(
          label: 'Kişi ekle',
          icon: Icons.person_add_alt_rounded,
          filled: false,
          expanded: true,
          onPressed: _addContact,
        ),
      ],
    );
  }

  Widget _clinicalStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    final weight = parseLocaleNumber(_weight.text);
    final preview = ClinicalSettings(
      bodyWeightKg: weight,
      dryWeightKg: parseLocaleNumber(_dryWeight.text),
      hasResidualUrine: _hasResidualUrine,
      treatmentMode: _mode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.tune_rounded,
          text: 'Klinik eşikler kılavuz referanslarıyla ÖNCEDEN '
              'DOLDURULDU. Hiçbiri kilitli değil: hepsini serbestçe '
              'değiştirebilirsin. Yanlarında kaynak adı, yılı ve '
              'doğrulama durumu yazar.',
        ),
        SizedBox(height: r.gapMd),
        for (final def in kDietTargets)
          Padding(
            padding: EdgeInsets.only(bottom: r.gapSm),
            child: ClinicalValueTile(
              definition: def,
              settings: preview,
              readOnly: true,
            ),
          ),
        SizedBox(height: r.gapSm),
        NeuCard(
          color: context.palette.accentSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alarm eşikleri de hazır',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: r.gapXs),
              Text(
                'Tansiyon (ACC/AHA 2017: >180/120 kriz), serum potasyum '
                'kademeleri, diyaliz arası kilo artışı (%4) ve daha '
                'fazlası. Kurulumdan sonra Ayarlar > Klinik Ayarlar\'dan '
                'tek tek düzenleyebilirsin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aiStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    final conn = ref.watch(aiConnectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(
          icon: Icons.auto_awesome_outlined,
          text: 'Yapay zeka özellikleri (sohbet, yemek fotoğrafı analizi, '
              'tahlil fotoğrafı okuma, menü analizi) kendi Anthropic '
              'anahtarınla çalışır. Şimdi eklemek ZORUNLU DEĞİL — '
              'uygulamanın geri kalanı anahtar olmadan da çalışır.',
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    conn.value == AiConnectionState.ok
                        ? Icons.check_circle_rounded
                        : Icons.link_off_rounded,
                    color: conn.value == AiConnectionState.ok
                        ? context.palette.success
                        : context.palette.textMuted,
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: Text(
                      conn.value == AiConnectionState.ok
                          ? 'Bağlantı kurulu'
                          : 'Bağlantı kurulmadı',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.gapMd),
              NeuButton(
                label: conn.value == AiConnectionState.ok
                    ? 'Bağlantıyı yönet'
                    : 'Şimdi bağlan',
                icon: Icons.key_outlined,
                expanded: true,
                onPressed: () => context.push(Routes.aiConnection),
              ),
              SizedBox(height: r.gapSm),
              Text(
                'Sonra da kurabilirsin: Ayarlar > Yapay Zeka Bağlantısı.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _doneStep(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: r.gapMd),
        Center(child: DropLeafMark(size: r.s(96), animate: false)),
        SizedBox(height: r.gapLg),
        Text(
          'Hazırsın, ${_name.text.trim().isEmpty ? "hoş geldin" : _name.text.trim()}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: r.gapMd),
        NeuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buradan sonra ne yapabilirsin',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: r.gapSm),
              for (final line in [
                'Ana sayfada günün özetini gör',
                'Yemek ekle — ara, barkod oku veya fotoğraf çek',
                'Sıvı kaydı tut (limit girdiysen kalanı gösterir)',
                'Tahlil gir veya tahlil kağıdını fotoğrafla',
                'İlaç hatırlatmalarını kur',
                'Acil durum butonunu bir kere dene (mesaj gönderilmez, '
                    'önizleme gösterir)',
              ])
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: r.s(16),
                        color: context.palette.primary,
                      ),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          line,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: r.gapMd),
        const MedicalDisclaimerBanner(),
      ],
    );
  }
}

class _Step {
  const _Step(this.title, this.builder);
  final String title;
  final Widget Function(BuildContext) builder;
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return GlassCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(r.gapSm),
            decoration: BoxDecoration(
              color: p.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: p.primary, size: r.s(20)),
          ),
          SizedBox(width: r.gapMd),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
