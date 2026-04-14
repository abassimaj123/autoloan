import 'package:flutter/material.dart';
import 'uk_logic.dart';
import '../../services/ad_service.dart';
import '../../services/history_service.dart';

class UKProvider extends ChangeNotifier {
  final AdService      _ads;
  final HistoryService _history;

  double      vehiclePrice    = 25000;
  double      downPayment     = 5000;
  double      annualRate      = 6.9;
  int         termMonths      = 60;
  bool        includeRoadTax  = false;
  VehicleType vehicleType     = VehicleType.petrolLarge;
  double      customVedAnnual = 0.0;

  UKCalculation? _result;
  UKCalculation? get result => _result;

  UKProvider(this._ads, this._history);

  void setVehiclePrice(double v)      { vehiclePrice    = v; notifyListeners(); }
  void setDownPayment(double v)       { downPayment     = v; notifyListeners(); }
  void setAnnualRate(double v)        { annualRate      = v; notifyListeners(); }
  void setTermMonths(int v)           { termMonths      = v; notifyListeners(); }
  void setIncludeRoadTax(bool v)      { includeRoadTax  = v; notifyListeners(); }
  void setVehicleType(VehicleType v)  { vehicleType     = v; notifyListeners(); }
  void setCustomVedAnnual(double v)   { customVedAnnual = v; notifyListeners(); }

  void calculate() {
    _result = UKCalculation.calculate(
      vehiclePrice: vehiclePrice, downPayment: downPayment,
      annualRate: annualRate, termMonths: termMonths,
      includeRoadTax: includeRoadTax, vehicleType: vehicleType,
      customVedAnnual: customVedAnnual,
    );
    _history.add('uk', {
      'timestamp': DateTime.now().toIso8601String(),
      'vehiclePrice': vehiclePrice,
      'monthlyPayment': _result!.monthlyPayment,
      'totalCost': _result!.totalCost,
      'termMonths': termMonths,
      'annualRate': annualRate,
    });
    _ads.onCalculation();
    notifyListeners();
  }
}
