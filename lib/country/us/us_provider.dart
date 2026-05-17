import 'package:flutter/material.dart';
import 'us_logic.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService
    hide SectionCard, ResultTile;
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
  bool isBiWeekly = false;

  USCalculation? _result;
  USCalculation? get result => _result;

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

  void setIsBiWeekly(bool v) {
    isBiWeekly = v;
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
      isBiWeekly: isBiWeekly,
    );
    AnalyticsService.instance.logCalculation(
      flavor: 'us',
      vehiclePrice: vehiclePrice,
      ratePct: annualRate,
      termMonths: termMonths,
    );
    notifyListeners();
  }

  /// Called after user stops editing (2 s inactivity). Saves one entry.
  void saveSnapshot() {
    if (_result == null) return;
    _history.add('us', {
      'timestamp': DateTime.now().toIso8601String(),
      'vehiclePrice': vehiclePrice,
      'tradeInValue': tradeInValue,
      'monthlyPayment': _result!.monthlyPayment,
      if (isBiWeekly) 'biWeeklyPayment': _result!.biWeeklyPayment,
      'isBiWeekly': isBiWeekly,
      'effectiveRate': _result!.effectiveRate,
      'totalCost': _result!.totalCost,
      'totalInterest': _result!.totalInterest,
      'termMonths': termMonths,
      'annualRate': annualRate,
    });
    AnalyticsService.instance.logHistorySaved('us');
    _ads.onAction();
  }
}
