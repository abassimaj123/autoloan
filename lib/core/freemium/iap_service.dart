/// IAP service — re-exports CalcwiseIAP from library with app-specific configuration.
/// This file maintains backward compatibility while using the shared library implementation.
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import 'freemium_service.dart';
import '../../services/analytics_service.dart';

// Re-export the iapErrorNotifier and iapRestoreResultNotifier from library for backward compatibility
export 'package:calcwise_core/services/iap_service.dart' show iapErrorNotifier, iapRestoreResultNotifier;

/// Global IAP singleton with ReviewService callback for AutoLoan.
class IAPService {
  IAPService._();
  static final instance = IAPService._();

  static const productId = 'premium_upgrade';

  late final CalcwiseIAP _iap;

  /// Localized price notifier — exposed for UI to listen.
  ValueNotifier<String?> get localizedPrice => _iap.localizedPrice;

  Future<void> initialize() async {
    _iap = CalcwiseIAP(
      productId: productId,
      freemium: freemiumService,
      analytics: AnalyticsService.instance,
      onPurchaseCompleted: () =>
          CalcwiseReviewService.instance.requestAfterPurchase(),
    );
    await _iap.initialize();
    PaywallHard.registerPrice(_iap.localizedPrice);
  }

  Future<void> buy() => _iap.buy();

  Future<void> restore() => _iap.restore();

  void dispose() => _iap.dispose();
}
