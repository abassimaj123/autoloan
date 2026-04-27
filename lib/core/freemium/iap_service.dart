import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'freemium_service.dart';
import '../../services/analytics_service.dart';
import '../../services/review_service.dart';

/// Non-null value = IAP error message; reset to null after showing.
final iapErrorNotifier = ValueNotifier<String?>(null);

class IAPService {
  IAPService._();
  static final instance = IAPService._();

  /// Must match the product ID created in Google Play Console.
  static const productId = 'premium_upgrade';

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> initialize() async {
    _sub = InAppPurchase.instance.purchaseStream.listen(_handlePurchases);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore error: $e');
    }
  }

  /// Initiate the purchase flow. Call from a button tap.
  Future<void> buy() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      iapErrorNotifier.value = 'Google Play is unavailable. Check Play Services or your connection.';
      return;
    }
    final ProductDetailsResponse response;
    try {
      response = await InAppPurchase.instance
          .queryProductDetails({productId})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      iapErrorNotifier.value = 'Request timed out. Try again.';
      return;
    } catch (e) {
      iapErrorNotifier.value = 'Could not reach the store. Try again.';
      debugPrint('IAP query error: $e');
      return;
    }
    if (response.productDetails.isEmpty) {
      iapErrorNotifier.value = 'Product not found. Try again later.';
      debugPrint('IAP product not found: $productId — check Play Console');
      return;
    }
    final param =
        PurchaseParam(productDetails: response.productDetails.first);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  /// Restore a previous purchase (required for Google Play policy).
  Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      iapErrorNotifier.value = 'Could not restore purchases. Check your connection and try again.';
      debugPrint('IAP restore error: $e');
    }
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.productID == productId) {
        if (p.status == PurchaseStatus.purchased) {
          freemiumService.activatePremium();
          AnalyticsService.instance.logPurchaseCompleted(
              flavor: const String.fromEnvironment('FLAVOR', defaultValue: 'CA').toLowerCase());
          AnalyticsService.instance.setUserPremium(true);
          ReviewService.instance.requestAfterPremium();
          debugPrint('Premium activated');
        } else if (p.status == PurchaseStatus.restored) {
          freemiumService.activatePremium();
          AnalyticsService.instance.logPurchaseRestored();
          AnalyticsService.instance.setUserPremium(true);
          debugPrint('Premium restored');
        } else if (p.status == PurchaseStatus.pending) {
          iapErrorNotifier.value = 'Purchase pending — awaiting approval or payment confirmation.';
        } else if (p.status == PurchaseStatus.error) {
          AnalyticsService.instance.logPurchaseFailed();
          iapErrorNotifier.value = 'Purchase failed. Please try again.';
          debugPrint('IAP error: ${p.error}');
        }
        if (p.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(p);
        }
      }
    }
  }

  void dispose() => _sub?.cancel();
}
