import 'package:flutter/material.dart';
import 'ca_logic.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService;
import '../../services/analytics_service.dart';
import '../../services/history_service.dart';

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
  bool isBiWeekly = false;
  String provinceCode = 'ON';
  final InsuranceOptions insurance = InsuranceOptions();

  CACalculation? _result;
  CACalculation? get result => _result;

  CAProvider(this._ads, this._history);

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

  void setIsBiWeekly(bool v) {
    isBiWeekly = v;
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
      isBiWeekly: isBiWeekly,
      insuranceMonthly: insurance.monthlyTotal(termMonths),
    );
    AnalyticsService.instance.logCalculation(
      flavor: 'ca',
      vehiclePrice: vehiclePrice,
      ratePct: annualRate,
      termMonths: termMonths,
    );
    notifyListeners();
  }

  /// Called after user stops editing (2 s inactivity). Saves one entry.
  void saveSnapshot() {
    if (_result == null) return;
    _history.add('ca', {
      'timestamp': DateTime.now().toIso8601String(),
      'vehiclePrice': vehiclePrice,
      'monthlyPayment': _result!.monthlyPayment,
      if (isBiWeekly) 'biWeeklyPayment': _result!.biWeeklyPayment,
      'isBiWeekly': isBiWeekly,
      'totalCost': _result!.totalCost,
      'totalInterest': _result!.totalInterest,
      'termMonths': termMonths,
      'annualRate': annualRate,
      'provinceCode': provinceCode,
    });
    AnalyticsService.instance.logHistorySaved('ca');
    _ads.onAction();
  }
}
