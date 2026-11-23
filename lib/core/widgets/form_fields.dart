import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'responsive.dart';

/// Etiketli alan sarmalayıcı.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.child,
    this.hint,
    this.trailing,
    super.key,
  });

  final String label;
  final Widget child;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ?trailing,
          ],
        ),
        SizedBox(height: r.gapXs),
        child,
        if (hint != null) ...[
          SizedBox(height: r.gapXs),
          Text(hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Sayısal giriş alanı. Türkçe klavyede virgül de kabul eder.
class NumberField extends StatelessWidget {
  const NumberField({
    required this.controller,
    this.hintText,
    this.suffix,
    this.allowDecimal = true,
    this.onChanged,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? suffix;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textAlign: textAlign,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: suffix,
        suffixStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

/// Virgül/nokta farkını gözeten sayı çözümleyici.
double? parseLocaleNumber(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

int? parseLocaleInt(String? raw) {
  final v = parseLocaleNumber(raw);
  return v?.round();
}

/// Tek seçimli çip grubu.
class ChipSelector<T> extends StatelessWidget {
  const ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
    super.key,
  });

  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Wrap(
      spacing: r.gapSm,
      runSpacing: r.gapSm,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(labelOf(o)),
            selected: selected == o,
            onSelected: (_) => onSelected(o),
            // Min dokunma alanı 48dp.
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
      ],
    );
  }
}

/// Çok seçimli çip grubu.
class MultiChipSelector extends StatelessWidget {
  const MultiChipSelector({
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Wrap(
      spacing: r.gapSm,
      runSpacing: r.gapSm,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(o),
            selected: selected.contains(o),
            onSelected: (_) => onToggle(o),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
      ],
    );
  }
}

/// Haftanın günleri seçici (1 = Pazartesi).
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const List<String> shortNames = [
    'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return Row(
      children: [
        for (var i = 1; i <= 7; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 7 ? 0 : r.gapXs),
              child: Semantics(
                button: true,
                selected: selected.contains(i),
                label: shortNames[i - 1],
                child: InkWell(
                  onTap: () => onToggle(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected.contains(i)
                          ? p.primary
                          : p.backgroundDeep.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected.contains(i) ? p.primary : p.divider,
                      ),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          shortNames[i - 1],
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: selected.contains(i)
                                    ? p.onPrimary
                                    : p.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Saat seçici satırı.
class TimeChips extends StatelessWidget {
  const TimeChips({
    required this.times,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<TimeOfDay> times;
  final VoidCallback onAdd;
  final ValueChanged<TimeOfDay> onRemove;

  static String format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Wrap(
      spacing: r.gapSm,
      runSpacing: r.gapSm,
      children: [
        for (final t in times)
          InputChip(
            label: Text(format(t)),
            onDeleted: () => onRemove(t),
            deleteIcon: const Icon(Icons.close_rounded, size: 18),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Saat ekle'),
          onPressed: onAdd,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        ),
      ],
    );
  }
}
