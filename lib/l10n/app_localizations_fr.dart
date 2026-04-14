// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appNameCA => 'Prêt Auto Canada';

  @override
  String get appNameUK => 'Prêt Auto UK';

  @override
  String get appNameUS => 'Prêt Auto USA';

  @override
  String get calculate => 'Calculer';

  @override
  String get vehiclePrice => 'Prix du véhicule';

  @override
  String get downPayment => 'Mise de fonds';

  @override
  String get annualRate => 'Taux d\'intérêt annuel';

  @override
  String get termMonths => 'Durée du prêt';

  @override
  String get monthlyPayment => 'Paiement mensuel';

  @override
  String get biWeeklyPayment => 'Paiement aux 2 semaines';

  @override
  String get totalInterest => 'Intérêts totaux';

  @override
  String get totalCost => 'Coût total véhicule';

  @override
  String get financedAmount => 'Montant financé';

  @override
  String get totalInsurances => 'Total assurances';

  @override
  String get loanAmount => 'Montant du prêt';

  @override
  String get tradeInValue => 'Valeur de reprise';

  @override
  String get dealerFees => 'Frais du concessionnaire';

  @override
  String get salesTax => 'Taxe de vente';

  @override
  String get taxAmount => 'Montant de taxe';

  @override
  String get results => 'Résultats';

  @override
  String get loanTerms => 'Conditions du prêt';

  @override
  String get province => 'Province / Territoire';

  @override
  String get state => 'État / Territoire';

  @override
  String get creditScore => 'Cote de crédit';

  @override
  String get effectiveRate => 'Taux effectif';

  @override
  String get balloonPayment => 'Paiement ballon';

  @override
  String get balloonPercent => '% ballon du prix du véhicule';

  @override
  String get balloonAmount => 'Montant ballon';

  @override
  String get driveAwayPrice => 'Prix tout inclus';

  @override
  String get gst => 'TPS (10%)';

  @override
  String get insurance => 'Assurances optionnelles';

  @override
  String get lifeDisability => 'Vie et invalidité';

  @override
  String get extendedWarranty => 'Garantie prolongée';

  @override
  String get gap => 'Assurance GAP';

  @override
  String get history => 'Historique';

  @override
  String get clearHistory => 'Effacer l\'historique';

  @override
  String get noHistory => 'Aucun calcul pour l\'instant.';

  @override
  String get amortization => 'Tableau d\'amortissement';

  @override
  String get unlockFull => 'Déverrouiller les résultats complets :';

  @override
  String get watchAd => 'Regarder une pub pour 60 min d\'accès';

  @override
  String get adNotAvailable => 'Pub non disponible. Réessayez plus tard.';

  @override
  String get fullAccessActive => 'Accès complet actif';

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
    return '$days jour$_temp0 d\'essai restant$_temp1';
  }

  @override
  String get biWeeklyToggle => 'Paiements aux 2 semaines';

  @override
  String get biWeeklySubtitle => '26 paiements par année';

  @override
  String get noAdjustment => 'Sans ajustement';

  @override
  String rateDiscount(String rate) {
    return '-$rate% de réduction de taux';
  }

  @override
  String ratePremium(String rate) {
    return '+$rate% de prime de taux';
  }

  @override
  String get loanOnly => 'Prêt seulement /mois';

  @override
  String get totalCostShort => 'Coût total';

  @override
  String get usePercentage => 'Utiliser % du prix';

  @override
  String get vehicle => 'Véhicule';

  @override
  String get month => 'mois';

  @override
  String get year => 'ans';

  @override
  String get payment => 'Paiement';

  @override
  String get principal => 'Capital';

  @override
  String get interest => 'Intérêts';

  @override
  String get balance => 'Solde';

  @override
  String get roadTax => 'Taxe routière (VED)';

  @override
  String get vedAnnual => 'Taxe routière annuelle';

  @override
  String get vehicleType => 'Type de véhicule';

  @override
  String get includeRoadTax => 'Inclure la taxe routière dans le paiement';

  @override
  String get totalVed => 'Total taxe routière';
}
