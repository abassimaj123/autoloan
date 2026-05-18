import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/freemium/freemium_service.dart';
import '../core/theme/app_theme.dart';
import '../core/freemium/iap_service.dart';
import 'package:calcwise_core/calcwise_core.dart' show CalcwiseAdService;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../services/analytics_service.dart';

/// Full-screen bottom sheet with two options: Watch Ad (60 min) or Get Premium.
/// Replaces the inline PremiumGate card.
class UnlockSheet extends StatefulWidget {
  final CalcwiseAdService adService;
  final String flavor;
  final VoidCallback? onUnlocked;

  const UnlockSheet({
    super.key,
    required this.adService,
    required this.flavor,
    this.onUnlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required CalcwiseAdService adService,
    required String flavor,
    VoidCallback? onUnlocked,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (_) => UnlockSheet(
      adService: adService,
      flavor: flavor,
      onUnlocked: onUnlocked,
    ),
  );

  @override
  State<UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<UnlockSheet> {
  bool _loading = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick every second to refresh countdown
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _premiumLabel(AppLocalizations l10n) {
    switch (widget.flavor) {
      case 'uk':
        return l10n.getPremiumUK;
      case 'us':
        return l10n.getPremiumUS;
      default:
        return l10n.getPremiumCA;
    }
  }

  Future<void> _watchAd() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final earned = await widget.adService.showRewarded();
      if (!mounted) return;
      if (earned) {
        await freemiumService.activateRewarded();
        AnalyticsService.instance.logRewardedAdWatched();
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fullAccessActive),
            backgroundColor: AppTheme.rewardedGreen,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onUnlocked?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adNotAvailable)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isRewarded = freemiumService.isRewarded;
    final minsLeft = freemiumService.rewardedRemaining?.inMinutes ?? 0;
    final canWatch = freemiumService.canWatchRewarded();
    final adReady = widget.adService.isRewardedReady;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Icon ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.mdPlus),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRewarded ? Icons.lock_open_rounded : Icons.lock_outline,
              size: 30,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            l10n.unlockFull,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumBenefits,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Active session chip ───────────────────────────────────
          if (isRewarded) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.rewardedGreenBg,
                border: Border.all(color: AppTheme.rewardedGreenBorder),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${l10n.fullAccessActive} · ${minsLeft}min',
                style: const TextStyle(
                  color: AppTheme.rewardedGreenText,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTextSize.md,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Watch Ad tile ─────────────────────────────────────────
          if (!isRewarded)
            _OptionTile(
              icon: Icons.play_circle_outline,
              title: l10n.watchAd,
              subtitle: '60 min ${l10n.fullAccessActive.toLowerCase()}',
              enabled: canWatch && adReady && !_loading,
              loading: _loading,
              onTap: _watchAd,
              cs: cs,
            ),

          if (!isRewarded) const SizedBox(height: 10),

          // ── Get Premium tile ──────────────────────────────────────
          _OptionTile(
            icon: Icons.star_outline,
            title: _premiumLabel(l10n),
            subtitle: 'No ads · ${l10n.premiumBenefits.split('·').last.trim()}',
            enabled: !_loading,
            onTap: () {
              Navigator.of(context).pop();
              AnalyticsService.instance.logPurchaseStarted();
              IAPService.instance.buy();
            },
            cs: cs,
          ),

          const SizedBox(height: 4),
          TextButton(
            onPressed: () => IAPService.instance.restore(),
            child: Text(
              l10n.restorePurchase,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.maybeLater,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option tile ────────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    required this.cs,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled
                    ? cs.primary.withValues(alpha: 0.4)
                    : cs.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTextSize.bodyMd,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: AppTextSize.md,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
