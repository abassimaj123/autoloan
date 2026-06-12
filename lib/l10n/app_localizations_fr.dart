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
  String get weeklyPayment => 'Paiement hebdomadaire';

  @override
  String get paymentFrequency => 'Fréquence de paiement';

  @override
  String get frequencyMonthly => 'Mensuel';

  @override
  String get frequencyBiWeekly => 'Aux 2 semaines';

  @override
  String get frequencyWeekly => 'Hebdomadaire';

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

  @override
  String get getPremiumUS => 'Obtenir Premium — 2,99 \$';

  @override
  String get getPremiumUK => 'Obtenir Premium — £2,99';

  @override
  String get getPremiumCA => 'Obtenir Premium — 3,99 \$ CAD';

  @override
  String get restorePurchase => 'Restaurer l\'achat';

  @override
  String get rewardDailyLimit => 'Reviens demain pour une autre heure gratuite';

  @override
  String get settings => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsPremiumSubtitle => 'Sans pub · Historique illimité';

  @override
  String get settingsPremiumActive => '⭐ Premium — Accès illimité';

  @override
  String get settingsSupport => 'Assistance';

  @override
  String get settingsContact => 'Contacter le support';

  @override
  String get settingsPrivacy => 'Politique de confidentialité';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsOtherApps => 'Nos autres applications';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get premiumBenefits =>
      'Tableau d\'amortissement · Export PDF · Historique illimité';

  @override
  String get lockSharing => 'Déverrouiller pour partager et exporter';

  @override
  String get compareLoans => 'Comparer les prêts';

  @override
  String get scenario => 'Scénario';

  @override
  String get betterDeal => 'Meilleure offre';

  @override
  String get totalSavings => 'Économies totales';

  @override
  String get financingType => 'Type de financement';

  @override
  String get standardLoan => 'Prêt standard';

  @override
  String get pcp => 'PCP';

  @override
  String get gmfv => 'VMFG (Valeur Min. Future Garantie)';

  @override
  String get gmfvPercent => 'VMFG en % du prix du véhicule';

  @override
  String get pcpNote =>
      'En fin de contrat : payer la VMFG, échanger ou rendre le véhicule';

  @override
  String get pcpPayment => 'Paiement mensuel PCP';

  @override
  String get pcpFinalPayment => 'Paiement ballon final';

  @override
  String get settingsDisclaimer =>
      'À titre informatif seulement. Ce n\'est pas un conseil financier. Consultez un conseiller qualifié avant de prendre des décisions financières.';

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get onboardingTitle1 => 'Calculez votre prêt auto';

  @override
  String get onboardingSubtitle1 =>
      'Obtenez instantanément vos paiements mensuels, les intérêts totaux et le coût complet. Disponible pour CA, UK et US.';

  @override
  String get onboardingTitle2 => 'Comparez les scénarios';

  @override
  String get onboardingSubtitle2 =>
      'Comparez deux prêts côte à côte — différentes durées, mises de fonds ou taux d\'intérêt. Trouvez la meilleure offre.';

  @override
  String get onboardingTitle3 => 'Passez en premium';

  @override
  String get onboardingSubtitle3 =>
      'Déverrouillez le tableau d\'amortissement, l\'export PDF et l\'historique illimité. Un seul achat, sans abonnement.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingFeaturePayment => 'Paiement mensuel';

  @override
  String get onboardingFeatureInterest => 'Intérêts totaux';

  @override
  String get onboardingFeatureCost => 'Coût total';

  @override
  String get onboardingFeatureAmortization => 'Amortissement';

  @override
  String get onboardingFeatureCompare => 'Comparaison';

  @override
  String get onboardingFeaturePDF => 'Export PDF';

  @override
  String get onboardingPremiumBullet1 => 'Tableau d\'amortissement complet';

  @override
  String get onboardingPremiumBullet2 => 'Export PDF et partage';

  @override
  String get onboardingPremiumBullet3 => 'Historique de calculs illimité';

  @override
  String get earlyPayoff => 'Remboursement anticipé';

  @override
  String get loanSummary => 'Résumé du prêt';

  @override
  String get extraMonthlyPayment => 'Paiement mensuel supplémentaire';

  @override
  String get extraAmountPerMonth => 'Montant supplémentaire par mois';

  @override
  String get withExtraPayment => 'Avec paiement supplémentaire';

  @override
  String get newMonthlyPayment => 'Nouveau paiement mensuel';

  @override
  String get paidOffIn => 'Remboursé en';

  @override
  String get youSave => 'Vous économisez';

  @override
  String get interestSaved => 'Intérêts économisés';

  @override
  String get monthsSaved => 'Mois économisés';

  @override
  String get leaseVsBuy => 'Location vs Achat';

  @override
  String get buyLoanDetails => 'Achat — Détails du prêt';

  @override
  String get vehiclePriceMsrp => 'Prix du véhicule (PDSF)';

  @override
  String get interestRateApr => 'Taux d\'intérêt (APR)';

  @override
  String get residualValuePct => 'Valeur résiduelle (%)';

  @override
  String get annualInsuranceCost => 'Coût annuel d\'assurance';

  @override
  String get leaseDetails => 'Détails de la location';

  @override
  String get monthlyLeasePayment => 'Paiement mensuel de location';

  @override
  String get lvbLeaseTerm => 'Durée de location (mois)';

  @override
  String get downPaymentCap => 'Mise de fonds / réduction cap';

  @override
  String get acquisitionFee => 'Frais d\'acquisition';

  @override
  String get dispositionFee => 'Frais de disposition';

  @override
  String get mileageLimitPerYear => 'Limite de kilométrage par an';

  @override
  String get overageCostPer => 'Coût de dépassement par';

  @override
  String get estimatedAnnualDriven => 'Kilométrage annuel estimé';

  @override
  String get compareLeaseBuy => 'Comparer Location vs Achat';

  @override
  String get comparisonResults => 'Résultats de comparaison';

  @override
  String get betterBadge => 'MIEUX';

  @override
  String get totalLabel => 'Total';

  @override
  String get buyBreakdown => 'Détail Achat';

  @override
  String get totalInterestPaid => 'Total des intérêts payés';

  @override
  String get insuranceOverTerm => 'Assurance sur la durée';

  @override
  String get totalBuyCost => 'Coût total d\'achat';

  @override
  String get leaseBreakdown => 'Détail Location';

  @override
  String get estimatedMileageOverage => 'Dépassement kilométrique estimé';

  @override
  String get totalLeaseCost => 'Coût total de location';

  @override
  String get mileageExceedsBreakEven =>
      'Kilométrage dépasse le seuil — l\'achat peut être plus économique';

  @override
  String get mileageBelowBreakEven =>
      'Kilométrage sous le seuil — la location peut être plus économique';

  @override
  String get informationalOnly =>
      'À titre informatif seulement. Les résultats dépendent des taux d\'assurance réels, de la dépréciation et d\'autres facteurs.';

  @override
  String leasingSaves(String amount, int months) {
    return 'La location économise $amount sur $months mois';
  }

  @override
  String buyingSaves(String amount, int months) {
    return 'L\'achat économise $amount sur $months mois';
  }

  @override
  String get loan1 => 'Prêt 1';

  @override
  String get loan2 => 'Prêt 2';

  @override
  String get loan3 => 'Prêt 3';

  @override
  String get compare3Loans => 'Comparer 3 Prêts';

  @override
  String get bestDeal => 'Meilleure Offre';

  @override
  String get lowestTotalCost => 'Coût Total le Plus Bas';

  @override
  String get trueCostOfOwnership => 'Coût Réel de Possession';

  @override
  String get ownershipPeriod => 'Période de Possession';

  @override
  String get insurancePerMonth => 'Assurance (par mois)';

  @override
  String get maintenancePerMonth => 'Entretien (par mois)';

  @override
  String get depreciationRate => 'Taux de Dépréciation';

  @override
  String get costBreakdown => 'Répartition des Coûts';

  @override
  String get monthlyTrueCost => 'Coût Réel Mensuel';

  @override
  String get totalCostOfOwnership => 'Coût Total de Possession';

  @override
  String get totalLoanCost => 'Coût Total du Prêt';

  @override
  String get totalFuel => 'Carburant Total';

  @override
  String get totalMaintenance => 'Entretien Total';

  @override
  String get depreciationLoss => 'Perte en Dépréciation';

  @override
  String get totalInsurance => 'Assurance Totale';

  @override
  String get runningCosts => 'Coûts de Fonctionnement';

  @override
  String get gasPerMonth => 'Carburant (par mois)';

  @override
  String get loanInputAmount => 'Montant';

  @override
  String get loanInputRate => 'Taux';

  @override
  String get loanInputTerm => 'Durée';

  @override
  String get share => 'Partager';

  @override
  String get exportPdf => 'Exporter PDF';

  @override
  String get exportPdfPro => 'Exporter PDF — PRO';

  @override
  String get cashBackVsLowApr => 'Remise vs Taux Bas';

  @override
  String get affordabilityGuide => 'Guide d\'accessibilité financière';
}
