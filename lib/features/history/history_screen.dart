import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'history_detail_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/history_service.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService, CalcwiseAdFooter;
import 'package:calcwise_core/calcwise_core.dart'
    hide SectionCard, ResultTile, PaywallHard;
import '../../core/freemium/freemium_service.dart';
import '../../widgets/paywall_hard.dart';
import '../../widgets/paywall_soft.dart';
import '../../core/freemium/iap_service.dart';

class HistoryScreen extends StatefulWidget {
  final String country;
  final bool showAppBar;
  final VoidCallback? onClear;
  const HistoryScreen({
    super.key,
    required this.country,
    this.showAppBar = true,
    this.onClear,
  });

  /// Increment to trigger a silent refresh of the history list after auto-save.
  static final refreshNotifier = ValueNotifier<int>(0);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// ── Skeleton shimmer ─────────────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.smPlus),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ShimmerBox(
                          width: 120,
                          height: 26,
                          radius: AppRadius.md,
                        ),
                        const Spacer(),
                        _ShimmerBox(
                          width: 70,
                          height: 22,
                          radius: AppRadius.sm,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ShimmerBox(width: 100, height: 13, radius: 4),
                            _ShimmerBox(width: 70, height: 13, radius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width, height, radius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  String _searchQuery = '';

  String get _flag {
    switch (widget.country) {
      case 'uk':
        return '🇬🇧';
      case 'us':
        return '🇺🇸';
      default:
        return '🇨🇦';
    }
  }

  String get _currency =>
      widget.country == 'uk' ? '£' : widget.country == 'ca' ? 'C\$' : '\$';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('history');
    Future.microtask(_load);
    HistoryScreen.refreshNotifier.addListener(_load);
  }

  @override
  void dispose() {
    HistoryScreen.refreshNotifier.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    final history = context.read<HistoryService>();
    final all = history.getAllForCountry(widget.country);
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adService = context.read<CalcwiseAdService>();
    final l10n = AppLocalizations.of(context)!;
    final history = context.read<HistoryService>();

    if (_loading) {
      if (widget.showAppBar) {
        return Scaffold(
          appBar: AppBar(title: Text('$_flag ${l10n.history}')),
          body: const _HistorySkeleton(),
          bottomNavigationBar: const CalcwiseAdFooter(),
        );
      }
      return const _HistorySkeleton();
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.hasFullAccessNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        final autoSaves =
            _all.where((e) => e['isPinned'] != true).toList();
        final pinned = _all
            .where((e) => e['isPinned'] == true && _matchesQuery(e))
            .toList();
        final shownAutoSavesBase = hasFull
            ? autoSaves
            : autoSaves.take(freemiumService.historyLimit).toList();
        final shownAutoSaves = _searchQuery.isEmpty
            ? shownAutoSavesBase
            : shownAutoSavesBase.where(_matchesQuery).toList();
        final locked = autoSaves.length - shownAutoSavesBase.length;

        if (!widget.showAppBar) {
          return _buildBody(
            context,
            l10n,
            adService,
            history,
            pinned,
            shownAutoSaves,
            locked,
            hasFull,
          );
        }
        return _buildScaffold(
          context,
          l10n,
          adService,
          history,
          pinned,
          shownAutoSaves,
          locked,
          hasFull,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    CalcwiseAdService adService,
    HistoryService history,
    List<Map<String, dynamic>> pinned,
    List<Map<String, dynamic>> shownAutoSaves,
    int locked,
    bool hasFull,
  ) {
    if (_all.isEmpty) {
      return CalcwiseEmptyState(
        icon: Icons.history_rounded,
        title: l10n.noHistory,
        body: l10n.historyEmptyBody,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(l10n.clearHistory),
                      content: Text(l10n.historyClearAll(_all.length)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.historyCancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.historyClearAction),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    HapticFeedback.mediumImpact();
                    await history.clear();
                    if (!mounted) return;
                    widget.onClear?.call();
                    _load();
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(l10n.clearHistory),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildListView(
            context,
            l10n,
            adService,
            history,
            pinned,
            shownAutoSaves,
            locked,
            hasFull,
          ),
        ),
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    AppLocalizations l10n,
    CalcwiseAdService adService,
    HistoryService history,
    List<Map<String, dynamic>> pinned,
    List<Map<String, dynamic>> shownAutoSaves,
    int locked,
    bool hasFull,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        CalcwiseSearchBar(
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        if (_searchQuery.isNotEmpty && pinned.isEmpty && shownAutoSaves.isEmpty)
          CalcwiseEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results',
            body: 'Try a different search term',
          ),
        // ── Pinned scenarios ─────────────────────────────────────────────
        if (pinned.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.bookmark_rounded,
            label: l10n.historySavedScenarios,
          ),
          ...pinned.map(
            (e) => _HistoryCard(
              entry: e,
              currency: _currency,
              country: widget.country,
              onAction: (action) => _handleAction(action, e, history),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // ── Recent calculations ───────────────────────────────────────────
        if (shownAutoSaves.isNotEmpty)
          _SectionHeader(
            icon: Icons.history_rounded,
            label: l10n.historyRecentCalc,
          ),

        // ── Approaching-limit nudge ──
        if (!hasFull &&
            locked == 0 &&
            shownAutoSaves.length >= freemiumService.historyLimit)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.historyLimitNudge(freemiumService.historyLimit),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

        // ── Locked banner ──
        if (!hasFull && locked > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: CalcwisePremiumGate(
              title: l10n.history,
              description: l10n.unlockFull,
              price: IAPService.instance.localizedPrice,
              onUnlock: () => PaywallSoft.show(context),
            ),
          ),

        // ── Auto-save entry cards ──
        ...shownAutoSaves.map(
          (e) => _HistoryCard(
            entry: e,
            currency: _currency,
            country: widget.country,
            onAction: (action) => _handleAction(action, e, history),
          ),
        ),

        // ── Locked tail ──
        if (!hasFull && locked > 0)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    l10n.historyLockedCount(locked),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Scaffold _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    CalcwiseAdService adService,
    HistoryService history,
    List<Map<String, dynamic>> pinned,
    List<Map<String, dynamic>> shownAutoSaves,
    int locked,
    bool hasFull,
  ) {
    return Scaffold(
      bottomNavigationBar: const CalcwiseAdFooter(),
      appBar: AppBar(
        title: Text('$_flag ${l10n.history}'),
        actions: [
          if (_all.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.clearHistory,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l10n.clearHistory),
                    content: Text(l10n.historyClearAll(_all.length)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.historyCancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.historyClearAction),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  HapticFeedback.mediumImpact();
                  await history.clear();
                  if (!mounted) return;
                  _load();
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: CalcwisePageEntrance(
        child: _all.isEmpty
            ? CalcwiseEmptyState(
                icon: Icons.history_rounded,
                title: l10n.noHistory,
                body: l10n.historyEmptyBody,
              )
            : _buildListView(
                context,
                l10n,
                adService,
                history,
                pinned,
                shownAutoSaves,
                locked,
                hasFull,
              ),
      ),
    );
  }

  Future<void> _handleAction(
    _CardAction action,
    Map<String, dynamic> entry,
    HistoryService history,
  ) async {
    final id = entry['id'] as int?;
    if (id == null) return;

    switch (action) {
      case _CardAction.unpin:
        HapticFeedback.mediumImpact();
        await history.unpin(id);
        if (!mounted) return;
        _load();
      case _CardAction.rename:
        if (!freemiumService.hasFullAccess) {
          await PaywallHard.show(context);
          return;
        }
        final label = await _showRenameDialog(
          entry['pinLabel'] as String? ?? '',
        );
        if (label == null) return;
        if (!mounted) return;
        await history.rename(id, label.trim());
        if (!mounted) return;
        _load();
      case _CardAction.delete:
        final l10n = AppLocalizations.of(context)!;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.historyDeleteTitle),
            content: Text(l10n.historyDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.historyCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.historyDelete),
              ),
            ],
          ),
        );
        if (confirm == true) {
          HapticFeedback.mediumImpact();
          await history.delete(id);
          if (!mounted) return;
          _load();
        }
    }
  }

  bool _matchesQuery(Map<String, dynamic> e) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    final label = (e['pinLabel'] as String? ?? '').toLowerCase();
    final price = ((e['vehiclePrice'] as num?) ?? 0).toDouble();
    final priceStr = price.toStringAsFixed(0).toLowerCase();
    return label.contains(q) || priceStr.contains(q);
  }

  Future<String?> _showRenameDialog(String current) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: current);
    final label = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.historyRenameTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.historyRenameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.historyCancel),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, ctrl.text);
            },
            child: Text(l10n.historyRename),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return label;
  }
}

// ── Section header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card action enum ─────────────────────────────────────────────────────────
enum _CardAction { unpin, rename, delete }

// ── History entry card ─────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String currency;
  final String country;
  final void Function(_CardAction) onAction;

  const _HistoryCard({
    required this.entry,
    required this.currency,
    required this.country,
    required this.onAction,
  });

  double? _d(String key) {
    final v = entry[key];
    return v == null ? null : (v as num).toDouble();
  }

  bool get _isPinned => entry['isPinned'] == true;
  String? get _pinLabel => entry['pinLabel'] as String?;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 0);
    final fmtDec = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, y', Localizations.localeOf(context).languageCode);
    final timeFmt = DateFormat('HH:mm');

    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
    final price = _d('vehiclePrice') ?? 0;
    final payment = _d('monthlyPayment') ?? _d('regularMonthly') ?? 0;
    final biWeekly = _d('biWeeklyPayment');
    final totalCost = _d('totalCost') ?? 0;
    final termMonths = entry['termMonths'] as int?;
    final rate = _d('annualRate') ?? _d('effectiveRate') ?? 0;
    final province = entry['provinceCode'] as String?;
    final freqName = entry['frequency'] as String?;
    final isBiWeeklyEntry = freqName == 'biWeekly';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: _isPinned
              ? cs.primary.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor,
          width: _isPinned ? 1.5 : 1.0,
        ),
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
              // ── Row 1: price + payment chip + menu ────────────────────
              Row(
                children: [
                  // Pin badge or label
                  if (_isPinned) ...[
                    Icon(Icons.bookmark_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    if (_pinLabel != null && _pinLabel!.isNotEmpty)
                      Flexible(
                        child: Text(
                          _pinLabel!,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (_pinLabel == null || _pinLabel!.isEmpty)
                      Text(
                        fmt.format(price),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                  ] else
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
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${fmtDec.format(biWeekly ?? payment)}/${isBiWeeklyEntry ? '2wk' : 'mo'}',
                      style: TextStyle(
                        fontSize: AppTextSize.md,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<_CardAction>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    onSelected: onAction,
                    itemBuilder: (ctx) {
                      final l = AppLocalizations.of(ctx)!;
                      return [
                        if (_isPinned)
                          PopupMenuItem(
                            value: _CardAction.unpin,
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.bookmark_remove_outlined),
                              title: Text(l.historyRemovePin),
                            ),
                          ),
                        if (_isPinned)
                          PopupMenuItem(
                            value: _CardAction.rename,
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.edit_outlined),
                              title: Text(l.historyRename),
                            ),
                          ),
                        PopupMenuItem(
                          value: _CardAction.delete,
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.delete_outline),
                            title: Text(l.historyDelete),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),

              // Pin label subtitle (if pinned and has a label, show the price below)
              if (_isPinned &&
                  _pinLabel != null &&
                  _pinLabel!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  fmt.format(price),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],

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
