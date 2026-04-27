import 'package:flutter/material.dart';
import '../core/freemium/iap_service.dart';
import '../core/theme/app_theme.dart';
import '../services/analytics_service.dart';

class PaywallHard extends StatelessWidget {
  final String priceLabel;
  final String savingsLabel;
  const PaywallHard({super.key, this.priceLabel = r'$2.99', this.savingsLabel = r'save $100+'});

  static Future<void> show(BuildContext context, {String priceLabel = r'$2.99', String savingsLabel = r'save $100+'}) {
    AnalyticsService.instance.logPaywallShown('hard');
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PaywallHard(priceLabel: priceLabel, savingsLabel: savingsLabel),
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
                color: AppTheme.warningOrangeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up_rounded, color: AppTheme.warningOrangeIcon, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Don\'t overpay on your auto loan',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 6),
            const Text('Premium shows exactly how to save more',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.labelGray)),
            const SizedBox(height: 18),
            ...['💰 Compare loan offers side by side',
                    '📉 Find optimal down payment & term',
                    '📊 Unlimited history & PDF export',
                    '🚫 Zero ads — ever']
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
                child: Text('Start saving now\n$priceLabel ($savingsLabel)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, height: 1.4)),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                AnalyticsService.instance.logPaywallDismissed();
                Navigator.pop(context);
              },
              child: Opacity(
                opacity: 0.5,
                child: const Text('Not now',
                    style: TextStyle(color: AppTheme.labelGray, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
