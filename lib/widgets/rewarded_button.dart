import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/trial_service.dart';

/// Shows a rewarded ad button that unlocks premium access for 60 minutes.
/// States: loading, ready, already-unlocked.
class RewardedButton extends StatefulWidget {
  final AdService adService;
  final TrialService trialService;
  final VoidCallback onUnlocked;

  const RewardedButton({
    super.key,
    required this.adService,
    required this.trialService,
    required this.onUnlocked,
  });

  @override
  State<RewardedButton> createState() => _RewardedButtonState();
}

class _RewardedButtonState extends State<RewardedButton> {
  bool _loading = false;

  Future<void> _tap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final got = await widget.adService.showRewarded();
      if (got) {
        await widget.trialService.activateReward();
        if (mounted) widget.onUnlocked();
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adNotAvailable)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context)!;
    final unlocked = widget.trialService.isRewardedActive;
    if (unlocked) {
      return Chip(
        avatar: const Icon(Icons.check_circle, size: 16),
        label: Text(l10n.fullAccessActive),
      );
    }
    return FilledButton.icon(
      onPressed: _loading ? null : _tap,
      icon: _loading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.play_circle_outline),
      label: Text(l10n.watchAd),
    );
  }
}
