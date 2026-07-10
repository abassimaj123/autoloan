/// Thin wrapper — delegates to calcwise_core's PaywallSoft.
/// Keeps the same API so no screen files need to change.
import 'package:calcwise_core/calcwise_core.dart' as cw;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/locale_notifier.dart';

class PaywallSoft extends StatelessWidget {
  const PaywallSoft({super.key});

  static void setAnalytics(cw.CalcwiseAnalytics analytics) {
    cw.PaywallSoft.setAnalytics(analytics);
  }

  static Future<void> show(BuildContext context, {String? priceLabel}) {
    final localeNotifier =
        Provider.of<LocaleNotifier>(context, listen: false);
    return cw.PaywallSoft.show(
      context,
      isFrench: localeNotifier.isFrench,
      isSpanish: localeNotifier.isSpanish,
      priceLabel: priceLabel,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
