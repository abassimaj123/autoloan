import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calcwise_core/calcwise_core.dart' show CalcwiseAdService, CalcwiseAdConfig;

import 'package:auto_loan/country/ca/ca_provider.dart';
import 'package:auto_loan/services/history_service.dart';
import 'package:auto_loan/services/analytics_service.dart';
import 'package:auto_loan/core/freemium/freemium_service.dart';

/// Regression test for the CA insurance itemization data-loss bug:
/// life/disability, extended warranty, and GAP insurance selections and
/// amounts were computed into the live result (monthlyPayment/totalCost)
/// but never written into `_buildData()`'s saved map, so a reopened history
/// entry showed a correct total with no way to tell which insurance add-ons
/// produced it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'CA saveScenario persists itemized insurance line items (life/warranty/GAP), '
    'not just the aggregate total',
    () async {
      final historyService =
          HistoryService(await SharedPreferences.getInstance());
      final adService = CalcwiseAdService(
        config: CalcwiseAdConfig.test,
        freemium: freemiumService,
        analytics: AnalyticsService.instance,
      );

      final provider = CAProvider(adService, historyService, smartProvince: 'ON')
        ..vehiclePrice = 30000
        ..downPayment = 5000
        ..annualRate = 6.5
        ..termMonths = 60;

      // Select all three insurance add-ons with distinct, identifiable amounts.
      provider
        ..setLifeDisability(true)
        ..setExtendedWarranty(true)
        ..setWarrantyAmount(1200)
        ..setGap(true)
        ..setGapAmount(800);

      provider.calculate();
      expect(provider.result, isNotNull);

      await provider.saveScenario(label: 'Insurance round-trip test');

      final saved = historyService.getAllForCountry('ca');
      expect(saved, isNotEmpty,
          reason: 'saveScenario must persist an entry for CA');
      final entry = saved.first;

      // Aggregate total was already correct before this fix — sanity-check it
      // still is, so the test would fail loudly if the calc itself regresses.
      expect(entry['totalCost'], provider.result!.totalCost);
      expect((entry['insuranceTotal'] as num).toDouble(),
          provider.result!.insuranceTotal);

      // The itemized breakdown must now round-trip through save/history.
      expect(entry['lifeDisability'], isTrue,
          reason: 'life/disability selection flag must be saved');
      expect((entry['lifeDisabilityAmount'] as num).toDouble(),
          provider.insurance.lifeDisabilityAmount);

      expect(entry['extendedWarranty'], isTrue,
          reason: 'extended warranty selection flag must be saved');
      expect(
          (entry['warrantyAmount'] as num).toDouble(), 1200.0);

      expect(entry['gap'], isTrue,
          reason: 'GAP insurance selection flag must be saved');
      expect((entry['gapAmount'] as num).toDouble(), 800.0);
    },
  );

  test(
    'CA saveScenario omits insurance amount keys when an add-on is not selected',
    () async {
      final historyService =
          HistoryService(await SharedPreferences.getInstance());
      final adService = CalcwiseAdService(
        config: CalcwiseAdConfig.test,
        freemium: freemiumService,
        analytics: AnalyticsService.instance,
      );

      final provider = CAProvider(adService, historyService, smartProvince: 'ON')
        ..vehiclePrice = 25000
        ..downPayment = 2000
        ..annualRate = 5.9
        ..termMonths = 48;
      // No insurance selected — all flags remain false/default.

      provider.calculate();
      await provider.saveScenario(label: 'No insurance');

      final entry = historyService.getAllForCountry('ca').first;
      expect(entry['lifeDisability'], isFalse);
      expect(entry['extendedWarranty'], isFalse);
      expect(entry['gap'], isFalse);
      expect(entry.containsKey('warrantyAmount'), isFalse,
          reason: 'amount keys should not be written when the add-on is off');
      expect(entry.containsKey('gapAmount'), isFalse);
    },
  );
}
