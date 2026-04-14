import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

// ── Currency slider ────────────────────────────────────────────────────────────

class CurrencySliderInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String symbol;

  const CurrencySliderInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 500,
    this.symbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(fmt.format(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) / step).round().clamp(1, 1000),
        onChanged: (v) => onChanged((v / step).round() * step),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(fmt.format(min),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        Text(fmt.format(max),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ]),
    ]);
  }
}

// ── Percent slider ─────────────────────────────────────────────────────────────

class PercentSliderInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final int decimals;

  const PercentSliderInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 0.1,
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text('${value.toStringAsFixed(decimals)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) / step).round().clamp(1, 1000),
        onChanged: (v) {
          final rounded = (v / step).round() * step;
          onChanged(double.parse(rounded.toStringAsFixed(decimals)));
        },
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${min.toStringAsFixed(decimals)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        Text('${max.toStringAsFixed(decimals)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ]),
    ]);
  }
}

// ── Duration chips ─────────────────────────────────────────────────────────────

class DurationChips extends StatefulWidget {
  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelected;
  final String label;

  const DurationChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.label = 'Term',
  });

  @override
  State<DurationChips> createState() => _DurationChipsState();
}

class _DurationChipsState extends State<DurationChips> {
  bool _showCustom = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final isCustom = !widget.options.contains(widget.selected);
    _showCustom = isCustom;
    _ctrl = TextEditingController(
        text: isCustom ? widget.selected.toString() : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isCustomSelected => !widget.options.contains(widget.selected);

  void _submitCustom(String val) {
    final months = int.tryParse(val);
    if (months != null && months >= 1 && months <= 120) {
      widget.onSelected(months);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...widget.options.map((months) {
            final years     = months / 12;
            final chipLabel = months % 12 == 0
                ? '${years.toStringAsFixed(0)} ${l10n.year}'
                : '$months ${l10n.month}';
            final isSelected = months == widget.selected && !_isCustomSelected;
            return ChoiceChip(
              label: Text(chipLabel),
              selected: isSelected,
              backgroundColor: Colors.transparent,
              selectedColor: primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: isSelected
                  ? BorderSide.none
                  : BorderSide(color: primary),
              onSelected: (_) {
                setState(() => _showCustom = false);
                widget.onSelected(months);
              },
            );
          }),
          // Custom chip
          ChoiceChip(
            label: const Text('Custom'),
            selected: _isCustomSelected,
            backgroundColor: Colors.transparent,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: _isCustomSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              fontWeight: _isCustomSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: _isCustomSelected
                ? BorderSide.none
                : BorderSide(color: Theme.of(context).colorScheme.primary),
            onSelected: (_) => setState(() => _showCustom = true),
          ),
        ],
      ),
      if (_showCustom) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Months (1–120)',
              suffixText: 'mo',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: () {
                final v = int.tryParse(_ctrl.text);
                if (_ctrl.text.isEmpty) return null;
                if (v == null || v < 1 || v > 120) return '1–120 only';
                return null;
              }(),
            ),
            onChanged: _submitCustom,
            onSubmitted: _submitCustom,
          ),
        ),
      ],
    ]);
  }
}

// ── Rate field ─────────────────────────────────────────────────────────────────

class RateInputField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  const RateInputField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Annual Rate',
  });

  @override
  State<RateInputField> createState() => _RateInputFieldState();
}

class _RateInputFieldState extends State<RateInputField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(RateInputField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final newText = widget.value.toStringAsFixed(2);
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: '%',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (s) {
        final v = double.tryParse(s);
        if (v != null && v >= 0 && v <= 30) widget.onChanged(v);
      },
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }
}

// ── Result tile ────────────────────────────────────────────────────────────────

class ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const ResultTile({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: isHighlight
                ? Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)
                : Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: isHighlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
