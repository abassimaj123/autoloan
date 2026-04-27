import 'package:flutter/material.dart';
import '../core/freemium/iap_service.dart';
import '../core/theme/app_theme.dart';
import '../services/analytics_service.dart';

/// AutoLoan uses app_localizations — paywall uses English as default.
/// Price shown dynamically based on country flavor (US=$2.99, UK=£2.99, CA=$3.99).
class PaywallSoft extends StatelessWidget {
  final String priceLabel;
  const PaywallSoft({super.key, this.priceLabel = r'$2.99'});

  static Future<void> show(BuildContext context, {String priceLabel = r'$2.99'}) {
    AnalyticsService.instance.logPaywallShown('soft');
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PaywallSoft(priceLabel: priceLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Make smarter auto loan decisions',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Unlock full access — no ads',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.labelGray)),
            const SizedBox(height: 18),
            ...['📊 Unlimited history', '⚡ Compare loan offers side-by-side',
                    '🚫 Zero ads forever', '📄 PDF export']
                .map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                      ]),
                    )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  AnalyticsService.instance.logPurchaseStarted();
                  IAPService.instance.buy();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Unlock Premium\n$priceLabel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, height: 1.4)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                AnalyticsService.instance.logPaywallDismissed();
                Navigator.pop(context);
              },
              child: const Text('Maybe later',
                  style: TextStyle(color: AppTheme.labelGray, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
