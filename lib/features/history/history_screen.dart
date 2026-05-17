import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'history_detail_screen.dart';
import '../../services/history_service.dart';
import 'package:calcwise_core/calcwise_core.dart' show CalcwiseAdService;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../../core/freemium/freemium_service.dart';
import '../../widgets/premium_gate.dart';

class HistoryScreen extends StatelessWidget {
  final String country;
  const HistoryScreen({super.key, required this.country});

  String get _flag {
    switch (country) {
      case 'uk':
        return '🇬🇧';
      case 'us':
        return '🇺🇸';
      default:
        return '🇨🇦';
    }
  }

  String get _currency => country == 'uk' ? '£' : '\$';

  @override
  Widget build(BuildContext context) {
    final history = context.read<HistoryService>();
    final adService = context.read<CalcwiseAdService>();
    final l10n = AppLocalizations.of(context)!;

    final all = history.getAll().where((e) => e['country'] == country).toList();

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.isPremiumNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        final shown = hasFull
            ? all
            : all.take(freemiumService.historyLimit).toList();
        final locked = all.length - shown.length;
        return _buildScaffold(
          context,
          l10n,
          adService,
          history,
          all,
          shown,
          locked,
          hasFull,
        );
      },
    );
  }

  Scaffold _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    CalcwiseAdService adService,
    HistoryService history,
    List<Map<String, dynamic>> all,
    List<Map<String, dynamic>> shown,
    int locked,
    bool hasFull,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_flag ${l10n.history}'),
        actions: [
          if (all.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.clearHistory,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l10n.clearHistory),
                    content: Text(
                      'Clear all ${all.length} calculation${all.length == 1 ? '' : 's'}? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await history.clear();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: all.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noHistory,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Approaching-limit nudge (shown at exactly the limit, no locked yet) ──
                if (!hasFull &&
                    locked == 0 &&
                    shown.length >= freemiumService.historyLimit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'History limit reached (${freemiumService.historyLimit}). '
                              'Upgrade to keep all future calculations.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Locked banner ─────────────────────────────────────
                if (!hasFull && locked > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: PremiumGate(
                      adService: adService,
                      flavor: country,
                      onUnlocked: () => Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              HistoryScreen(country: country),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: AppDuration.base,
                        ),
                      ),
                    ),
                  ),

                // ── Entry cards ───────────────────────────────────────
                ...shown.map(
                  (e) => _HistoryCard(
                    entry: e,
                    currency: _currency,
                    country: country,
                  ),
                ),

                // ── Locked tail ───────────────────────────────────────
                if (!hasFull && locked > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$locked older record${locked > 1 ? 's' : ''} locked',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

// ── History entry card ─────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String currency;
  final String country;

  const _HistoryCard({
    required this.entry,
    required this.currency,
    required this.country,
  });

  double? _d(String key) {
    final v = entry[key];
    return v == null ? null : (v as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 0);
    final fmtDec = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, y');
    final timeFmt = DateFormat('HH:mm');

    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
    final price = _d('vehiclePrice') ?? 0;
    final payment = _d('monthlyPayment') ?? _d('regularMonthly') ?? 0;
    final biWeekly = _d('biWeeklyPayment');
    final totalCost = _d('totalCost') ?? 0;
    final termMonths = entry['termMonths'] as int?;
    final rate = _d('annualRate') ?? _d('effectiveRate') ?? 0;
    final province = entry['provinceCode'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HistoryDetailScreen(entry: entry),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: AppDuration.base,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.mdPlus),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: price + payment chip ──────────────────────
              Row(
                children: [
                  Text(
                    fmt.format(price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${fmtDec.format(biWeekly ?? payment)}/mo',
                      style: TextStyle(
                        fontSize: AppTextSize.md,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Row 2: term · rate · province ────────────────────
              Wrap(
                spacing: 8,
                children: [
                  if (termMonths != null)
                    _Tag(
                      icon: Icons.calendar_today_rounded,
                      label: '${termMonths ~/ 12} yr',
                    ),
                  _Tag(
                    icon: Icons.percent,
                    label: '${rate.toStringAsFixed(1)}%',
                  ),
                  if (province != null)
                    _Tag(icon: Icons.location_on_rounded, label: province),
                  _Tag(icon: Icons.price_check, label: fmt.format(totalCost)),
                ],
              ),

              // ── Row 3: date ──────────────────────────────────────
              if (ts != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFmt.format(ts)} · ${timeFmt.format(ts)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: cs.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
