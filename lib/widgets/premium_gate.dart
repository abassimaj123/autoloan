import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/freemium/freemium_service.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService
    hide SectionCard, ResultTile;
import 'unlock_sheet.dart';

/// Single "🔒 Unlock" button. Tapping opens the UnlockSheet bottom sheet.
/// Auto-hides when premium or rewarded session is active.
class PremiumGate extends StatelessWidget {
  final CalcwiseAdService adService;
  final String flavor;
  final VoidCallback? onUnlocked;

  const PremiumGate({
    super.key,
    required this.adService,
    required this.flavor,
    this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.isPremiumNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        if (freemiumService.hasFullAccess || freemiumService.isRewarded) {
          return const SizedBox.shrink();
        }
        return OutlinedButton.icon(
          onPressed: () => UnlockSheet.show(
            context,
            adService: adService,
            flavor: flavor,
            onUnlocked: onUnlocked,
          ),
          icon: const Icon(Icons.lock_outline, size: 18),
          label: Text(l10n.unlockFull),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
          ),
        );
      },
    );
  }
}
