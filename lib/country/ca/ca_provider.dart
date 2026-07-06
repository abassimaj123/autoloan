import 'dart:async';

import 'package:flutter/material.dart';
import 'ca_logic.dart';
import '../../core/payment_frequency.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService, ResultHasher, CalcwiseDurations;
import '../../services/analytics_service.dart';
import '../../services/history_service.dart';
import '../../features/history/history_screen.dart';

class InsuranceOptions {
  bool lifeDisability = false;
  double lifeDisabilityAmount = 20;
  bool extendedWarranty = false;
  double warrantyAmount = 0;
  bool gap = false;
  double gapAmount = 0;

  double monthlyTotal(int termMonths) {
    double t = 0;
    if (lifeDisability) t += lifeDisabilityAmount;
    if (extendedWarranty && warrantyAmount > 0)
      t += warrantyAmount / termMonths;
    if (gap && gapAmount > 0) t += gapAmount / termMonths;
    return t;
  }
}

class CAProvider extends ChangeNotifier {
  final CalcwiseAdService _ads;
  final HistoryService _history;

  double vehiclePrice = 30000;
  double downPayment = 5000;
  bool dpIsPercent = false;
  double annualRate = 7.9;
  int termMonths = 60;
  PaymentFrequency frequency = PaymentFrequency.monthly;
  late String provinceCode;

  bool get isBiWeekly => frequency == PaymentFrequency.biWeekly;
  final InsuranceOptions insurance = InsuranceOptions();

  CACalculation? _result;
  CACalculation? get result => _result;

  Timer? _saveTimer;

  // smartProvince: locale-detected default ('QC' for French, 'ON' for English CA).
  CAProvider(this._ads, this._history, {String smartProvince = 'ON'}) {
    provinceCode = smartProvince;
  }

  double get dpAmount =>
      dpIsPercent ? vehiclePrice * downPayment / 100 : downPayment;

  void setVehiclePrice(double v) {
    vehiclePrice = v;
    notifyListeners();
  }

  void setDownPayment(double v) {
    downPayment = v;
    notifyListeners();
  }

  void setDpIsPercent(bool v) {
    dpIsPercent = v;
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

  void setFrequency(PaymentFrequency v) {
    frequency = v;
    notifyListeners();
  }

  void setProvinceCode(String v) {
    provinceCode = v;
    notifyListeners();
  }

  // Insurance setters (notify listeners so UI rebuilds)
  void setLifeDisability(bool v) {
    insurance.lifeDisability = v;
    notifyListeners();
  }

  void setExtendedWarranty(bool v) {
    insurance.extendedWarranty = v;
    notifyListeners();
  }

  void setWarrantyAmount(double v) {
    insurance.warrantyAmount = v;
    notifyListeners();
  }

  void setGap(bool v) {
    insurance.gap = v;
    notifyListeners();
  }

  void setGapAmount(double v) {
    insurance.gapAmount = v;
    notifyListeners();
  }

  void calculate() {
    _result = CACalculation.calculate(
      vehiclePrice: vehiclePrice,
      downPayment: dpAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      provinceCode: provinceCode,
      frequency: frequency,
      insuranceMonthly: insurance.monthlyTotal(termMonths),
    );
    AnalyticsService.instance.logCalculation(
      flavor: 'ca',
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
      'downPayment': ResultHasher.roundTo(dpAmount, 500),
      'annualRate': ResultHasher.roundTo(annualRate, 0.1),
      'termMonths': termMonths,
      'province': provinceCode,
    });
    _history.addAutoSave('ca', _buildData(), hash);
    HistoryScreen.refreshNotifier.value++;
    AnalyticsService.instance.logHistorySaved('ca');
    _ads.onSave();
  }

  /// Immediately pin the current result as a named scenario.
  Future<void> saveScenario({String? label}) async {
    if (_result == null) return;
    final hash = ResultHasher.hashMixed({
      'vehiclePrice': ResultHasher.roundTo(vehiclePrice, 500),
      'downPayment': ResultHasher.roundTo(dpAmount, 500),
      'annualRate': ResultHasher.roundTo(annualRate, 0.1),
      'termMonths': termMonths,
      'province': provinceCode,
    });
    await _history.saveScenario('ca', _buildData(), hash, label: label);
    HistoryScreen.refreshNotifier.value++;
    AnalyticsService.instance.logHistorySaved('ca');
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
        'provinceCode': provinceCode,
        'insuranceTotal': _result!.insuranceTotal,
        'lifeDisability': insurance.lifeDisability,
        if (insurance.lifeDisability)
          'lifeDisabilityAmount': insurance.lifeDisabilityAmount,
        'extendedWarranty': insurance.extendedWarranty,
        if (insurance.extendedWarranty)
          'warrantyAmount': insurance.warrantyAmount,
        'gap': insurance.gap,
        if (insurance.gap) 'gapAmount': insurance.gapAmount,
      };

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
