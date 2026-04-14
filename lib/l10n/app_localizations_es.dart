// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appNameCA => 'Préstamo Auto Canadá';

  @override
  String get appNameUK => 'Préstamo Auto UK';

  @override
  String get appNameUS => 'Préstamo Auto USA';

  @override
  String get calculate => 'Calcular';

  @override
  String get vehiclePrice => 'Precio del vehículo';

  @override
  String get downPayment => 'Enganche';

  @override
  String get annualRate => 'Tasa de interés anual';

  @override
  String get termMonths => 'Plazo del préstamo';

  @override
  String get monthlyPayment => 'Pago mensual';

  @override
  String get biWeeklyPayment => 'Pago quincenal';

  @override
  String get totalInterest => 'Interés total';

  @override
  String get totalCost => 'Costo total del vehículo';

  @override
  String get financedAmount => 'Monto financiado';

  @override
  String get totalInsurances => 'Total seguros';

  @override
  String get loanAmount => 'Monto del préstamo';

  @override
  String get tradeInValue => 'Valor de intercambio';

  @override
  String get dealerFees => 'Cargos del concesionario';

  @override
  String get salesTax => 'Impuesto sobre ventas';

  @override
  String get taxAmount => 'Monto de impuesto';

  @override
  String get results => 'Resultados';

  @override
  String get loanTerms => 'Condiciones del préstamo';

  @override
  String get province => 'Provincia / Territorio';

  @override
  String get state => 'Estado / Territorio';

  @override
  String get creditScore => 'Puntaje de crédito';

  @override
  String get effectiveRate => 'Tasa efectiva';

  @override
  String get balloonPayment => 'Pago globo';

  @override
  String get balloonPercent => '% globo del precio del vehículo';

  @override
  String get balloonAmount => 'Monto globo';

  @override
  String get driveAwayPrice => 'Precio total';

  @override
  String get gst => 'GST (10%)';

  @override
  String get insurance => 'Seguros opcionales';

  @override
  String get lifeDisability => 'Vida e incapacidad';

  @override
  String get extendedWarranty => 'Garantía extendida';

  @override
  String get gap => 'Seguro GAP';

  @override
  String get history => 'Historial';

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get noHistory => 'Sin cálculos aún.';

  @override
  String get amortization => 'Tabla de amortización';

  @override
  String get unlockFull => 'Desbloquear resultados completos:';

  @override
  String get watchAd => 'Ver anuncio por 60 min de acceso';

  @override
  String get adNotAvailable => 'Anuncio no disponible. Inténtelo más tarde.';

  @override
  String get fullAccessActive => 'Acceso completo activo';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 's',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$days día$_temp0 de prueba restante$_temp1';
  }

  @override
  String get biWeeklyToggle => 'Pagos quincenales';

  @override
  String get biWeeklySubtitle => '26 pagos por año';

  @override
  String get noAdjustment => 'Sin ajuste';

  @override
  String rateDiscount(String rate) {
    return '-$rate% descuento en tasa';
  }

  @override
  String ratePremium(String rate) {
    return '+$rate% prima sobre tasa';
  }

  @override
  String get loanOnly => 'Solo préstamo /mes';

  @override
  String get totalCostShort => 'Costo total';

  @override
  String get usePercentage => 'Usar % del precio';

  @override
  String get vehicle => 'Vehículo';

  @override
  String get month => 'mes';

  @override
  String get year => 'años';

  @override
  String get payment => 'Pago';

  @override
  String get principal => 'Capital';

  @override
  String get interest => 'Intereses';

  @override
  String get balance => 'Saldo';

  @override
  String get roadTax => 'Impuesto de circulación (VED)';

  @override
  String get vedAnnual => 'Impuesto anual de circulación';

  @override
  String get vehicleType => 'Tipo de vehículo';

  @override
  String get includeRoadTax => 'Incluir impuesto de circulación en el pago';

  @override
  String get totalVed => 'Total impuesto de circulación';
}
