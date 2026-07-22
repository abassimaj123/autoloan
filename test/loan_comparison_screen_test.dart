import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService, CalcwiseAdConfig, SmartHistoryService, DatabaseAdapter;

import 'package:auto_loan/screens/loan_comparison_screen.dart';
import 'package:auto_loan/country/ca/ca_provider.dart';
import 'package:auto_loan/country/uk/uk_provider.dart';
import 'package:auto_loan/country/us/us_provider.dart';
import 'package:auto_loan/services/history_service.dart';
import 'package:auto_loan/services/analytics_service.dart';
import 'package:auto_loan/core/freemium/freemium_service.dart';
import 'package:auto_loan/core/freemium/iap_service.dart';
import 'package:auto_loan/l10n/app_localizations.dart';
import 'package:auto_loan/main.dart' show smartHistoryService;

/// Wraps [child] with the same localization delegates main.dart configures,
/// so `AppLocalizations.of(context)!` inside LoanComparisonScreen resolves.
Widget _testApp(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// Mirrors the private `_LoanResult.compute` amortization formula in
/// loan_comparison_screen.dart, so the test can independently predict what
/// "Loan 1"'s monthly payment must be once it is genuinely tied to live
/// provider inputs, instead of asserting on brittle TextFormField internals
/// (TextFormField.initialValue is only applied on first build and is not a
/// reliable observation point for a value that changes via setState).
double _expectedMonthlyPayment(
  double principal,
  double annualRate,
  int termMonths,
) {
  if (annualRate <= 0 || termMonths <= 0) {
    return termMonths > 0 ? principal / termMonths : 0;
  }
  final r = annualRate / 100 / 12;
  final powN = pow(1 + r, termMonths).toDouble();
  return principal * (r * powN) / (powN - 1);
}

// ── In-memory adapter (mirrors scenarios/save_history_scenario_test.dart) ────
class _MemoryAdapter implements DatabaseAdapter {
  final List<Map<String, dynamic>> _rows = [];
  int _nextId = 1;

  @override
  Future<int> insertRow(Map<String, dynamic> row) async {
    final id = _nextId++;
    _rows.add({...row, 'id': id});
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getRows({
    required String appKey,
    String? screenId,
    bool? isPinned,
    int? limit,
  }) async => [];

  @override
  Future<Map<String, dynamic>?> getRowByHash({
    required String appKey,
    required String screenId,
    required String resultHash,
  }) async => null;

  @override
  Future<int> updateRow(int id, Map<String, dynamic> values) async => 0;

  @override
  Future<int> deleteRow(int id) async => 0;

  @override
  Future<int> countRows({required String appKey, bool? isPinned}) async => 0;

  @override
  Future<List<Map<String, dynamic>>> getOldestAutoSaves({
    required String appKey,
    required int limit,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getOldestPinned({
    required String appKey,
    required int limit,
  }) async => [];
}

/// Regression test for the loan_comparison_screen hardcoded-defaults bug.
///
/// Before the fix, Loan 1 always started at $25,000 / 5.9% / 60mo regardless
/// of the user's actual loan (entered in the main CA/UK/US calculator and
/// held live in CAProvider/UKProvider/USProvider). This test seeds each
/// flavor provider with clearly non-default values and asserts the rendered
/// "Loan 1" monthly payment matches what those live values must produce —
/// and does NOT match what the old hardcoded $25,000 @ 5.9% / 60mo default
/// would have produced.
void main() {
  const hardcodedDefaultMonthly = 482.158423912906; // old _amount1/_rate1/_term1 = 25000/5.9%/60mo

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // freemiumService is a real global (calcwise_core) shared across the app;
    // force full access so the results section skips the paywall gate.
    freemiumService.isPremiumNotifier.value = true;
    // IAPService.instance._iap is `late final`, only assigned by initialize().
    // _GatedComparisonResults reads IAPService.instance.localizedPrice
    // unconditionally on every build (even when hasFullAccess is true), so it
    // must be initialized once here or every pump throws LateInitializationError.
    // No mock platform channel is registered, so the underlying store queries
    // fail fast (PlatformException) and localizedPrice stays null — harmless
    // for these tests, which don't assert on price text.
    await IAPService.instance.initialize();
    // smartHistoryService is a top-level `late final` in main.dart, normally
    // assigned once in main(). Assign it once here too (LateInitializationError
    // if reassigned) so every test below can exercise the real save path.
    smartHistoryService = SmartHistoryService(
      db: _MemoryAdapter(),
      freemium: freemiumService,
    );
  });

  testWidgets(
    'CA: Loan 1 monthly payment reflects live CAProvider values, not the '
    'hardcoded \$25,000 / 5.9% / 60mo default',
    (tester) async {
      final historyService =
          HistoryService(await SharedPreferences.getInstance());
      final adService = CalcwiseAdService(
        config: CalcwiseAdConfig.test,
        freemium: freemiumService,
        analytics: AnalyticsService.instance,
      );

      // A distinctly non-default loan: $60,000 @ 8.9% / 84 months.
      // None of these values match the hardcoded _amount1=25000/_rate1=5.9/_term1=60.
      const price = 60000.0, rate = 8.9;
      const term = 84;
      final caProvider =
          CAProvider(adService, historyService, smartProvince: 'ON')
            ..vehiclePrice = price
            ..annualRate = rate
            ..termMonths = term;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CalcwiseAdService>.value(value: adService),
            ChangeNotifierProvider<CAProvider>.value(value: caProvider),
          ],
          child: _testApp(const LoanComparisonScreen(flavor: 'ca')),
        ),
      );
      // Let the addPostFrameCallback prefill run.
      await tester.pumpAndSettle();

      final expectedMonthly = _expectedMonthlyPayment(price, rate, term);
      final fmt = NumberFormat.currency(symbol: 'C\$', decimalDigits: 2);

      // The CalcSourceBanner (provenance label shown when seeded from the
      // live calculator) pushes the results table further down the
      // scrollable ListView than the default viewport shows — scroll it
      // into view so the lazily-built Sliver children mount.
      await tester.scrollUntilVisible(
        find.text(fmt.format(expectedMonthly)),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text(fmt.format(expectedMonthly)),
        findsOneWidget,
        reason:
            'Loan 1 monthly payment must be computed from CAProvider live '
            'values (\$60,000 @ 8.9% / 84mo), not the hardcoded default',
      );
      expect(
        expectedMonthly,
        isNot(closeTo(hardcodedDefaultMonthly, 1.0)),
        reason: 'Sanity check: live inputs must actually differ from the '
            'old hardcoded default (else this test would pass vacuously)',
      );
    },
  );

  testWidgets(
    'UK: Loan 1 monthly payment reflects live UKProvider values',
    (tester) async {
      final historyService =
          HistoryService(await SharedPreferences.getInstance());
      final adService = CalcwiseAdService(
        config: CalcwiseAdConfig.test,
        freemium: freemiumService,
        analytics: AnalyticsService.instance,
      );

      const price = 42000.0, rate = 3.4;
      const term = 36;
      final ukProvider = UKProvider(adService, historyService)
        ..vehiclePrice = price
        ..annualRate = rate
        ..termMonths = term;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CalcwiseAdService>.value(value: adService),
            ChangeNotifierProvider<UKProvider>.value(value: ukProvider),
          ],
          child: _testApp(const LoanComparisonScreen(flavor: 'uk')),
        ),
      );
      await tester.pumpAndSettle();

      final expectedMonthly = _expectedMonthlyPayment(price, rate, term);
      final fmt = NumberFormat.currency(symbol: '£', decimalDigits: 2);

      await tester.scrollUntilVisible(
        find.text(fmt.format(expectedMonthly)),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text(fmt.format(expectedMonthly)),
        findsOneWidget,
        reason:
            'Loan 1 monthly payment must be computed from UKProvider live '
            'values (£42,000 @ 3.4% / 36mo), not the hardcoded default',
      );
    },
  );

  testWidgets(
    'US: Loan 1 monthly payment reflects live USProvider values',
    (tester) async {
      final historyService =
          HistoryService(await SharedPreferences.getInstance());
      final adService = CalcwiseAdService(
        config: CalcwiseAdConfig.test,
        freemium: freemiumService,
        analytics: AnalyticsService.instance,
      );

      const price = 51000.0, rate = 11.2;
      const term = 72;
      final usProvider = USProvider(adService, historyService)
        ..vehiclePrice = price
        ..annualRate = rate
        ..termMonths = term;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CalcwiseAdService>.value(value: adService),
            ChangeNotifierProvider<USProvider>.value(value: usProvider),
          ],
          child: _testApp(const LoanComparisonScreen(flavor: 'us')),
        ),
      );
      await tester.pumpAndSettle();

      final expectedMonthly = _expectedMonthlyPayment(price, rate, term);
      final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      await tester.scrollUntilVisible(
        find.text(fmt.format(expectedMonthly)),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text(fmt.format(expectedMonthly)),
        findsOneWidget,
        reason:
            'Loan 1 monthly payment must be computed from USProvider live '
            'values (\$51,000 @ 11.2% / 72mo), not the hardcoded default',
      );
    },
  );
}
