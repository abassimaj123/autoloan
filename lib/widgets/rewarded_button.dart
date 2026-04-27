import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../core/freemium/freemium_service.dart';

/// Rewarded ad button that unlocks history access for 60 minutes.
///
/// States:
///   - Active session / Premium  → "Full access active" chip
///   - Daily limit reached       → "Come back tomorrow" chip
///   - Ready to watch            → "Watch ad" FilledButton
class RewardedButton extends StatefulWidget {
  final AdService adService;
  final VoidCallback onUnlocked;

  const RewardedButton({
    super.key,
    required this.adService,
    required this.onUnlocked,
  });

  @override
  State<RewardedButton> createState() => _RewardedButtonState();
}

class _RewardedButtonState extends State<RewardedButton> {
  bool _loading = false;

  Future<void> _tap() async {
    if (_loading) return;
    if (!freemiumService.canWatchRewarded()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily limit reached. Come back tomorrow for another hour of free access.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final got = await widget.adService.showRewarded();
      if (got) {
        await freemiumService.activateRewarded();
        if (mounted) widget.onUnlocked();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.adNotAvailable)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: freemiumService.isRewardedNotifier,
      builder: (context, isRewarded, _) {
        if (freemiumService.isPremium || isRewarded) {
          return Chip(
            avatar: const Icon(Icons.check_circle, size: 16),
            label: Text(l10n.fullAccessActive),
          );
        }
        if (!freemiumService.canWatchRewarded()) {
          return Chip(
            avatar: const Icon(Icons.schedule, size: 16),
            label: Text(l10n.rewardDailyLimit),
          );
        }
        final adReady = widget.adService.isRewardedReady;
        return FilledButton.icon(
          onPressed: (_loading || !adReady) ? null : _tap,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ))
              : const Icon(Icons.play_circle_outline),
          label: Text(adReady ? l10n.watchAd : l10n.adNotAvailable),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
        );
      },
    );
  }
}
