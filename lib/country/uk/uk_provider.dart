import 'dart:async';

import 'package:flutter/material.dart';
import 'uk_logic.dart';
import '../../core/payment_frequency.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService, ResultHasher, CalcwiseDurations;
import '../../services/analytics_service.dart';
import '../../services/history_service.dart';
import '../../features/history/history_screen.dart';

class UKProvider extends ChangeNotifier {
  final CalcwiseAdService _ads;
  final HistoryService _history;

  double vehiclePrice = 25000;
  double downPayment = 5000;
  double annualRate = 6.9;
  int termMonths = 60;
  bool includeRoadTax = false;
  VehicleType vehicleType = VehicleType.petrolLarge;
  double customVedAnnual = 0.0;
  bool isPcp = false;
  double gmfvPercent = 30.0;
  PaymentFrequency frequency = PaymentFrequency.monthly;

  bool get isBiWeekly => frequency == PaymentFrequency.biWeekly;

  /// Financing type: standardLoan / hp / pcp
  UKFinancingType financingType = UKFinancingType.standardLoan;

  /// CO2 emissions (g/km) — optional. 0 = not entered (use category VED).
  double co2GPerKm = 0.0;

  UKCalculation? _result;
  UKCalculation? get result => _result;

  Timer? _saveTimer;

  UKProvider(this._ads, this._history);

  void setVehiclePrice(double v) {
    vehiclePrice = v;
    notifyListeners();
  }

  void setDownPayment(double v) {
    downPayment = v;
    notifyListeners();
  }

  void setAnnualRate(double v) {
    annualRate = v;
    notifyListeners();
  }

  void setTermMonths(int v) {
    termMonths = v;
    notifyListeners();
  }

  void setIncludeRoadTax(bool v) {
    includeRoadTax = v;
    notifyListeners();
  }

  void setVehicleType(VehicleType v) {
    vehicleType = v;
    notifyListeners();
  }

  void setCustomVedAnnual(double v) {
    customVedAnnual = v;
    notifyListeners();
  }

  void setIsPcp(bool v) {
    isPcp = v;
    notifyListeners();
  }

  void setGmfvPercent(double v) {
    gmfvPercent = v;
    notifyListeners();
  }

  void setFrequency(PaymentFrequency v) {
    frequency = v;
    notifyListeners();
  }

  void setFinancingType(UKFinancingType v) {
    financingType = v;
    isPcp = v.isPcpType;
    notifyListeners();
  }

  void setCo2GPerKm(double v) {
    co2GPerKm = v;
    notifyListeners();
  }

  /// First-year VED based on CO2 (if entered), else null
  double? get co2FirstYearVed =>
      co2GPerKm > 0 ? ukCo2FirstYearVed(co2GPerKm) : null;

  /// Year 2+ standard VED based on CO2 (if entered), else null
  double? get co2StandardVed =>
      co2GPerKm > 0 ? ukCo2StandardRateVed(co2GPerKm) : null;

  void calculate() {
    // For HP: use same calculation as standard loan (no balloon)
    final effectiveIsPcp = financingType == UKFinancingType.pcp;
    _result = UKCalculation.calculate(
      vehiclePrice: vehiclePrice,
      downPayment: downPayment,
      annualRate: annualRate,
      termMonths: termMonths,
      includeRoadTax: includeRoadTax,
      vehicleType: vehicleType,
      customVedAnnual: customVedAnnual,
      isPcp: effectiveIsPcp,
      gmfvPercent: gmfvPercent,
      frequency: frequency,
    );
    AnalyticsService.instance.logCalculation(
      flavor: 'uk',
      vehiclePrice: vehiclePrice,
      ratePct: annualRate,
      termMonths: termMonths,
    );
    AnalyticsService.instance.maybeLogFirstCalculate();
    _ads.onAction();
    notifyListeners();
  }

  /// Schedule a debounced auto-save (5 s after the last call).
  /// Call this immediately after [calculate] is triggered from the screen.
  void scheduleAutoSave() {
    if (_result == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(CalcwiseDurations.saveDebounce, _doAutoSave);
  }

  void _doAutoSave() {
    if (_result == null) return;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': ResultHasher.roundTo(vehiclePrice, 500),
      'downPayment': ResultHasher.roundTo(downPayment, 500),
      'annualRate': ResultHasher.roundTo(annualRate, 0.1),
      'termMonths': termMonths,
    });
    _history.addAutoSave('uk', _buildData(), hash);
    HistoryScreen.refreshNotifier.value++;
    AnalyticsService.instance.logHistorySaved('uk');
    _ads.onSave();
  }

  /// Immediately pin the current result as a named scenario.
  Future<void> saveScenario({String? label}) async {
    if (_result == null) return;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': ResultHasher.roundTo(vehiclePrice, 500),
      'downPayment': ResultHasher.roundTo(downPayment, 500),
      'annualRate': ResultHasher.roundTo(annualRate, 0.1),
      'termMonths': termMonths,
    });
    await _history.saveScenario('uk', _buildData(), hash, label: label);
    HistoryScreen.refreshNotifier.value++;
    AnalyticsService.instance.logHistorySaved('uk');
    _ads.onSave();
    notifyListeners();
  }

  Map<String, dynamic> _buildData() => {
        'timestamp': DateTime.now().toIso8601String(),
        'vehiclePrice': vehiclePrice,
        'downPayment': _result!.downPayment,
        'loanAmount': _result!.loanAmount,
        'monthlyPayment': _result!.monthlyPayment,
        if (frequency == PaymentFrequency.biWeekly)
          'biWeeklyPayment': _result!.biWeeklyPayment,
        if (frequency == PaymentFrequency.weekly)
          'weeklyPayment': _result!.weeklyPayment,
        'isBiWeekly': isBiWeekly,
        'frequency': frequency.name,
        'totalCost': _result!.totalCost,
        'totalInterest': _result!.totalInterest,
        'termMonths': termMonths,
        'annualRate': annualRate,
      };

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
