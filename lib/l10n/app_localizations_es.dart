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

  @override
  String get getPremiumUS => 'Obtener Premium — \$2.99';

  @override
  String get getPremiumUK => 'Obtener Premium — £2.99';

  @override
  String get getPremiumCA => 'Obtener Premium — \$3.99 CAD';

  @override
  String get restorePurchase => 'Restaurar compra';

  @override
  String get rewardDailyLimit => 'Vuelve mañana para otra hora gratis';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsPremiumSubtitle => 'Sin anuncios · Historial ilimitado';

  @override
  String get settingsPremiumActive => '⭐ Premium — Acceso ilimitado';

  @override
  String get settingsSupport => 'Soporte';

  @override
  String get settingsContact => 'Contactar soporte';

  @override
  String get settingsPrivacy => 'Política de privacidad';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsOtherApps => 'Nuestras otras aplicaciones';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get premiumBenefits =>
      'Tabla de amortización · Exportar PDF · Historial ilimitado';

  @override
  String get lockSharing => 'Desbloquear para compartir y exportar';

  @override
  String get compareLoans => 'Comparar préstamos';

  @override
  String get scenario => 'Escenario';

  @override
  String get betterDeal => 'Mejor oferta';

  @override
  String get totalSavings => 'Ahorro total';

  @override
  String get financingType => 'Tipo de financiamiento';

  @override
  String get standardLoan => 'Préstamo estándar';

  @override
  String get pcp => 'PCP';

  @override
  String get gmfv => 'VMFG (Valor Mín. Futuro Garantizado)';

  @override
  String get gmfvPercent => 'VMFG % del precio del vehículo';

  @override
  String get pcpNote =>
      'Al final del contrato: pagar VMFG, intercambiar o devolver el vehículo';

  @override
  String get pcpPayment => 'Pago mensual PCP';

  @override
  String get pcpFinalPayment => 'Pago globo final';

  @override
  String get settingsDisclaimer =>
      'Solo con fines informativos. No es asesoramiento financiero. Consulte a un asesor calificado antes de tomar decisiones financieras.';

  @override
  String get maybeLater => 'Quizás más tarde';

  @override
  String get onboardingTitle1 => 'Calcula tu préstamo auto';

  @override
  String get onboardingSubtitle1 =>
      'Obtén tu pago mensual, interés total y costo completo al instante. Compatible con CA, UK y US.';

  @override
  String get onboardingTitle2 => 'Compara escenarios';

  @override
  String get onboardingSubtitle2 =>
      'Compara dos préstamos lado a lado — distintos plazos, enganches o tasas de interés. Encuentra la mejor oferta.';

  @override
  String get onboardingTitle3 => 'Hazte premium';

  @override
  String get onboardingSubtitle3 =>
      'Desbloquea la tabla de amortización, exportación PDF e historial ilimitado. Una sola compra, sin suscripción.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingFeaturePayment => 'Pago mensual';

  @override
  String get onboardingFeatureInterest => 'Interés total';

  @override
  String get onboardingFeatureCost => 'Costo total';

  @override
  String get onboardingFeatureAmortization => 'Amortización';

  @override
  String get onboardingFeatureCompare => 'Comparación';

  @override
  String get onboardingFeaturePDF => 'Exportar PDF';

  @override
  String get onboardingPremiumBullet1 => 'Tabla de amortización completa';

  @override
  String get onboardingPremiumBullet2 => 'Exportación PDF y compartir';

  @override
  String get onboardingPremiumBullet3 => 'Historial de cálculos ilimitado';
}
