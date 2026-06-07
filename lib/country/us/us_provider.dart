import 'dart:async';

import 'package:flutter/material.dart';
import 'us_logic.dart';
import '../../core/payment_frequency.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService, ResultHasher, CalcwiseDurations;
import '../../services/analytics_service.dart';
import '../../services/history_service.dart';

class USProvider extends ChangeNotifier {
  final CalcwiseAdService _ads;
  final HistoryService _history;

  double vehiclePrice = 35000;
  double tradeInValue = 0;
  double downPayment = 5000;
  double dealerFees = 500;
  double salesTaxPercent = 8.0;
  double annualRate = 7.5;
  int termMonths = 60;
  CreditScore creditScore = CreditScore.good;
  PaymentFrequency frequency = PaymentFrequency.monthly;

  bool get isBiWeekly => frequency == PaymentFrequency.biWeekly;

  USCalculation? _result;
  USCalculation? get result => _result;

  Timer? _saveTimer;

  USProvider(this._ads, this._history);

  void setVehiclePrice(double v) {
    vehiclePrice = v;
    notifyListeners();
  }

  void setTradeInValue(double v) {
    tradeInValue = v;
    notifyListeners();
  }

  void setDownPayment(double v) {
    downPayment = v;
    notifyListeners();
  }

  void setDealerFees(double v) {
    dealerFees = v;
    notifyListeners();
  }

  void setSalesTax(double v) {
    salesTaxPercent = v;
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

  void setCreditScore(CreditScore v) {
    creditScore = v;
    notifyListeners();
  }

  void setFrequency(PaymentFrequency v) {
    frequency = v;
    notifyListeners();
  }

  void calculate() {
    _result = USCalculation.calculate(
      vehiclePrice: vehiclePrice,
      tradeInValue: tradeInValue,
      downPayment: downPayment,
      dealerFees: dealerFees,
      salesTaxPercent: salesTaxPercent,
      annualRate: annualRate,
      termMonths: termMonths,
      creditScore: creditScore,
      frequency: frequency,
    );
    AnalyticsService.instance.logCalculation(
      flavor: 'us',
      vehiclePrice: vehiclePrice,
      ratePct: annualRate,
      termMonths: termMonths,
    );
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
      'tradeIn': ResultHasher.roundTo(tradeInValue, 500),
      'annualRate': ResultHasher.roundTo(annualRate, 0.1),
      'termMonths': termMonths,
    });
    _history.addAutoSave('us', _buildData(), hash);
    AnalyticsService.instance.logHistorySaved('us');
    _ads.onAction();
  }

  /// Immediately pin the current result as a named scenario.
  Future<void> saveScenario({String? label}) async {
    if (_result == null) return;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': ResultHasher.roundTo(vehiclePrice, 500),
      'tradeIn': ResultHasher.roundTo(tradeInValue, 500),
      'annualRate': ResultHasher.roundTo(annualRate, 0.1),
      'termMonths': termMonths,
    });
    await _history.saveScenario('us', _buildData(), hash, label: label);
    AnalyticsService.instance.logHistorySaved('us');
    _ads.onAction();
    notifyListeners();
  }

  Map<String, dynamic> _buildData() => {
        'timestamp': DateTime.now().toIso8601String(),
        'vehiclePrice': vehiclePrice,
        'tradeInValue': tradeInValue,
        'downPayment': _result!.downPayment,
        'financedAmount': _result!.financedAmount,
        'monthlyPayment': _result!.monthlyPayment,
        if (frequency == PaymentFrequency.biWeekly)
          'biWeeklyPayment': _result!.biWeeklyPayment,
        if (frequency == PaymentFrequency.weekly)
          'weeklyPayment': _result!.weeklyPayment,
        'isBiWeekly': isBiWeekly,
        'frequency': frequency.name,
        'effectiveRate': _result!.effectiveRate,
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
