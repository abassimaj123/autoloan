import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appNameCA.
  ///
  /// In en, this message translates to:
  /// **'Auto Loan Canada'**
  String get appNameCA;

  /// No description provided for @appNameUK.
  ///
  /// In en, this message translates to:
  /// **'Auto Loan UK'**
  String get appNameUK;

  /// No description provided for @appNameUS.
  ///
  /// In en, this message translates to:
  /// **'Auto Loan USA'**
  String get appNameUS;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @vehiclePrice.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Price'**
  String get vehiclePrice;

  /// No description provided for @downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down Payment'**
  String get downPayment;

  /// No description provided for @annualRate.
  ///
  /// In en, this message translates to:
  /// **'Annual Interest Rate'**
  String get annualRate;

  /// No description provided for @termMonths.
  ///
  /// In en, this message translates to:
  /// **'Loan Term'**
  String get termMonths;

  /// No description provided for @monthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment'**
  String get monthlyPayment;

  /// No description provided for @biWeeklyPayment.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly Payment'**
  String get biWeeklyPayment;

  /// No description provided for @weeklyPayment.
  ///
  /// In en, this message translates to:
  /// **'Weekly Payment'**
  String get weeklyPayment;

  /// No description provided for @paymentFrequency.
  ///
  /// In en, this message translates to:
  /// **'Payment Frequency'**
  String get paymentFrequency;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyBiWeekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get frequencyBiWeekly;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total Interest'**
  String get totalInterest;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Vehicle Cost'**
  String get totalCost;

  /// No description provided for @financedAmount.
  ///
  /// In en, this message translates to:
  /// **'Financed Amount'**
  String get financedAmount;

  /// No description provided for @totalInsurances.
  ///
  /// In en, this message translates to:
  /// **'Total Insurances'**
  String get totalInsurances;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get loanAmount;

  /// No description provided for @tradeInValue.
  ///
  /// In en, this message translates to:
  /// **'Trade-in Value'**
  String get tradeInValue;

  /// No description provided for @dealerFees.
  ///
  /// In en, this message translates to:
  /// **'Dealer Fees'**
  String get dealerFees;

  /// No description provided for @salesTax.
  ///
  /// In en, this message translates to:
  /// **'Sales Tax'**
  String get salesTax;

  /// No description provided for @taxAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax Amount'**
  String get taxAmount;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @loanTerms.
  ///
  /// In en, this message translates to:
  /// **'Loan Terms'**
  String get loanTerms;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province / Territory'**
  String get province;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State / Territory'**
  String get state;

  /// No description provided for @creditScore.
  ///
  /// In en, this message translates to:
  /// **'Credit Score'**
  String get creditScore;

  /// No description provided for @effectiveRate.
  ///
  /// In en, this message translates to:
  /// **'Effective Rate'**
  String get effectiveRate;

  /// No description provided for @balloonPayment.
  ///
  /// In en, this message translates to:
  /// **'Balloon Payment'**
  String get balloonPayment;

  /// No description provided for @balloonPercent.
  ///
  /// In en, this message translates to:
  /// **'Balloon % of vehicle price'**
  String get balloonPercent;

  /// No description provided for @balloonAmount.
  ///
  /// In en, this message translates to:
  /// **'Balloon Amount'**
  String get balloonAmount;

  /// No description provided for @driveAwayPrice.
  ///
  /// In en, this message translates to:
  /// **'Drive-away Price'**
  String get driveAwayPrice;

  /// No description provided for @gst.
  ///
  /// In en, this message translates to:
  /// **'GST (10%)'**
  String get gst;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Optional Insurance'**
  String get insurance;

  /// No description provided for @lifeDisability.
  ///
  /// In en, this message translates to:
  /// **'Life & Disability'**
  String get lifeDisability;

  /// No description provided for @extendedWarranty.
  ///
  /// In en, this message translates to:
  /// **'Extended Warranty'**
  String get extendedWarranty;

  /// No description provided for @gap.
  ///
  /// In en, this message translates to:
  /// **'GAP Insurance'**
  String get gap;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No calculations yet.'**
  String get noHistory;

  /// No description provided for @amortization.
  ///
  /// In en, this message translates to:
  /// **'Amortization Schedule'**
  String get amortization;

  /// No description provided for @unlockFull.
  ///
  /// In en, this message translates to:
  /// **'Unlock full results:'**
  String get unlockFull;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for full access (60 min)'**
  String get watchAd;

  /// No description provided for @adNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ad not available. Try again later.'**
  String get adNotAvailable;

  /// No description provided for @fullAccessActive.
  ///
  /// In en, this message translates to:
  /// **'Full access active'**
  String get fullAccessActive;

  /// No description provided for @trialDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} trial day{days, plural, one{} other{s}} remaining'**
  String trialDaysRemaining(int days);

  /// No description provided for @biWeeklyToggle.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly payments'**
  String get biWeeklyToggle;

  /// No description provided for @biWeeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'26 payments per year'**
  String get biWeeklySubtitle;

  /// No description provided for @noAdjustment.
  ///
  /// In en, this message translates to:
  /// **'No adjustment'**
  String get noAdjustment;

  /// No description provided for @rateDiscount.
  ///
  /// In en, this message translates to:
  /// **'-{rate}% rate discount'**
  String rateDiscount(String rate);

  /// No description provided for @ratePremium.
  ///
  /// In en, this message translates to:
  /// **'+{rate}% rate premium'**
  String ratePremium(String rate);

  /// No description provided for @loanOnly.
  ///
  /// In en, this message translates to:
  /// **'Loan only /mo'**
  String get loanOnly;

  /// No description provided for @totalCostShort.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCostShort;

  /// No description provided for @usePercentage.
  ///
  /// In en, this message translates to:
  /// **'Use % of price'**
  String get usePercentage;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get year;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @principal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get principal;

  /// No description provided for @interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interest;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @roadTax.
  ///
  /// In en, this message translates to:
  /// **'Road Tax (VED)'**
  String get roadTax;

  /// No description provided for @vedAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual Road Tax'**
  String get vedAnnual;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @includeRoadTax.
  ///
  /// In en, this message translates to:
  /// **'Include Road Tax in monthly payment'**
  String get includeRoadTax;

  /// No description provided for @totalVed.
  ///
  /// In en, this message translates to:
  /// **'Total Road Tax'**
  String get totalVed;

  /// No description provided for @getPremiumUS.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get getPremiumUS;

  /// No description provided for @getPremiumUK.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get getPremiumUK;

  /// No description provided for @getPremiumCA.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get getPremiumCA;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get restorePurchase;

  /// No description provided for @rewardDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for another free hour'**
  String get rewardDailyLimit;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No ads · Unlimited history'**
  String get settingsPremiumSubtitle;

  /// No description provided for @settingsPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'⭐ Premium — Unlimited access'**
  String get settingsPremiumActive;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsContact;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Our other apps'**
  String get settingsOtherApps;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @premiumBenefits.
  ///
  /// In en, this message translates to:
  /// **'Amortization schedule · PDF export · Unlimited history'**
  String get premiumBenefits;

  /// No description provided for @lockSharing.
  ///
  /// In en, this message translates to:
  /// **'Unlock to share & export'**
  String get lockSharing;

  /// No description provided for @compareLoans.
  ///
  /// In en, this message translates to:
  /// **'Compare Loans'**
  String get compareLoans;

  /// No description provided for @scenario.
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get scenario;

  /// No description provided for @betterDeal.
  ///
  /// In en, this message translates to:
  /// **'Better Deal'**
  String get betterDeal;

  /// No description provided for @totalSavings.
  ///
  /// In en, this message translates to:
  /// **'Total Savings'**
  String get totalSavings;

  /// No description provided for @financingType.
  ///
  /// In en, this message translates to:
  /// **'Financing Type'**
  String get financingType;

  /// No description provided for @standardLoan.
  ///
  /// In en, this message translates to:
  /// **'Standard Loan'**
  String get standardLoan;

  /// No description provided for @pcp.
  ///
  /// In en, this message translates to:
  /// **'PCP'**
  String get pcp;

  /// No description provided for @gmfv.
  ///
  /// In en, this message translates to:
  /// **'GMFV (Guaranteed Min. Future Value)'**
  String get gmfv;

  /// No description provided for @gmfvPercent.
  ///
  /// In en, this message translates to:
  /// **'GMFV % of vehicle price'**
  String get gmfvPercent;

  /// No description provided for @pcpNote.
  ///
  /// In en, this message translates to:
  /// **'At term end: pay GMFV, trade in, or return vehicle'**
  String get pcpNote;

  /// No description provided for @pcpPayment.
  ///
  /// In en, this message translates to:
  /// **'PCP Monthly Payment'**
  String get pcpPayment;

  /// No description provided for @pcpFinalPayment.
  ///
  /// In en, this message translates to:
  /// **'Final Balloon Payment'**
  String get pcpFinalPayment;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'For informational purposes only. Not financial advice. Consult a qualified advisor before making financial decisions.'**
  String get settingsDisclaimer;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Calculate your auto loan'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Get your monthly payment, total interest, and full cost instantly. Supports CA, UK, and US markets.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Compare scenarios'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Compare two loan scenarios side by side — different terms, down payments, or interest rates. Find the best deal.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Go premium'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Unlock the amortization schedule, PDF export, and unlimited history. One small purchase, no subscription.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingFeaturePayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get onboardingFeaturePayment;

  /// No description provided for @onboardingFeatureInterest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get onboardingFeatureInterest;

  /// No description provided for @onboardingFeatureCost.
  ///
  /// In en, this message translates to:
  /// **'Full loan cost'**
  String get onboardingFeatureCost;

  /// No description provided for @onboardingFeatureAmortization.
  ///
  /// In en, this message translates to:
  /// **'Amortization'**
  String get onboardingFeatureAmortization;

  /// No description provided for @onboardingFeatureCompare.
  ///
  /// In en, this message translates to:
  /// **'Loan comparison'**
  String get onboardingFeatureCompare;

  /// No description provided for @onboardingFeaturePDF.
  ///
  /// In en, this message translates to:
  /// **'PDF export'**
  String get onboardingFeaturePDF;

  /// No description provided for @onboardingPremiumBullet1.
  ///
  /// In en, this message translates to:
  /// **'Full amortization schedule'**
  String get onboardingPremiumBullet1;

  /// No description provided for @onboardingPremiumBullet2.
  ///
  /// In en, this message translates to:
  /// **'PDF export & sharing'**
  String get onboardingPremiumBullet2;

  /// No description provided for @onboardingPremiumBullet3.
  ///
  /// In en, this message translates to:
  /// **'Unlimited calculation history'**
  String get onboardingPremiumBullet3;

  /// No description provided for @earlyPayoff.
  ///
  /// In en, this message translates to:
  /// **'Early Payoff'**
  String get earlyPayoff;

  /// No description provided for @loanSummary.
  ///
  /// In en, this message translates to:
  /// **'Loan Summary'**
  String get loanSummary;

  /// No description provided for @extraMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Extra Monthly Payment'**
  String get extraMonthlyPayment;

  /// No description provided for @extraAmountPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Extra amount per month'**
  String get extraAmountPerMonth;

  /// No description provided for @withExtraPayment.
  ///
  /// In en, this message translates to:
  /// **'With Extra Payment'**
  String get withExtraPayment;

  /// No description provided for @newMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'New Monthly Payment'**
  String get newMonthlyPayment;

  /// No description provided for @paidOffIn.
  ///
  /// In en, this message translates to:
  /// **'Paid off in'**
  String get paidOffIn;

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get youSave;

  /// No description provided for @interestSaved.
  ///
  /// In en, this message translates to:
  /// **'Interest saved'**
  String get interestSaved;

  /// No description provided for @monthsSaved.
  ///
  /// In en, this message translates to:
  /// **'Months saved'**
  String get monthsSaved;

  /// No description provided for @leaseVsBuy.
  ///
  /// In en, this message translates to:
  /// **'Lease vs Buy'**
  String get leaseVsBuy;

  /// No description provided for @buyLoanDetails.
  ///
  /// In en, this message translates to:
  /// **'Buy — Loan Details'**
  String get buyLoanDetails;

  /// No description provided for @vehiclePriceMsrp.
  ///
  /// In en, this message translates to:
  /// **'Vehicle price (MSRP)'**
  String get vehiclePriceMsrp;

  /// No description provided for @interestRateApr.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (APR)'**
  String get interestRateApr;

  /// No description provided for @residualValuePct.
  ///
  /// In en, this message translates to:
  /// **'Residual value (%)'**
  String get residualValuePct;

  /// No description provided for @annualInsuranceCost.
  ///
  /// In en, this message translates to:
  /// **'Annual insurance cost'**
  String get annualInsuranceCost;

  /// No description provided for @leaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Lease Details'**
  String get leaseDetails;

  /// No description provided for @monthlyLeasePayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly lease payment'**
  String get monthlyLeasePayment;

  /// No description provided for @lvbLeaseTerm.
  ///
  /// In en, this message translates to:
  /// **'Lease term (months)'**
  String get lvbLeaseTerm;

  /// No description provided for @downPaymentCap.
  ///
  /// In en, this message translates to:
  /// **'Down payment / cap reduction'**
  String get downPaymentCap;

  /// No description provided for @acquisitionFee.
  ///
  /// In en, this message translates to:
  /// **'Acquisition fee'**
  String get acquisitionFee;

  /// No description provided for @dispositionFee.
  ///
  /// In en, this message translates to:
  /// **'Disposition fee'**
  String get dispositionFee;

  /// No description provided for @mileageLimitPerYear.
  ///
  /// In en, this message translates to:
  /// **'Mileage limit per year'**
  String get mileageLimitPerYear;

  /// No description provided for @overageCostPer.
  ///
  /// In en, this message translates to:
  /// **'Overage cost per'**
  String get overageCostPer;

  /// No description provided for @estimatedAnnualDriven.
  ///
  /// In en, this message translates to:
  /// **'Estimated annual miles driven'**
  String get estimatedAnnualDriven;

  /// No description provided for @compareLeaseBuy.
  ///
  /// In en, this message translates to:
  /// **'Compare Lease vs Buy'**
  String get compareLeaseBuy;

  /// No description provided for @comparisonResults.
  ///
  /// In en, this message translates to:
  /// **'Comparison Results'**
  String get comparisonResults;

  /// No description provided for @betterBadge.
  ///
  /// In en, this message translates to:
  /// **'BETTER'**
  String get betterBadge;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @buyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Buy Breakdown'**
  String get buyBreakdown;

  /// No description provided for @totalInterestPaid.
  ///
  /// In en, this message translates to:
  /// **'Total interest paid'**
  String get totalInterestPaid;

  /// No description provided for @insuranceOverTerm.
  ///
  /// In en, this message translates to:
  /// **'Insurance over term'**
  String get insuranceOverTerm;

  /// No description provided for @totalBuyCost.
  ///
  /// In en, this message translates to:
  /// **'Total buy cost'**
  String get totalBuyCost;

  /// No description provided for @leaseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Lease Breakdown'**
  String get leaseBreakdown;

  /// No description provided for @estimatedMileageOverage.
  ///
  /// In en, this message translates to:
  /// **'Estimated mileage overage'**
  String get estimatedMileageOverage;

  /// No description provided for @totalLeaseCost.
  ///
  /// In en, this message translates to:
  /// **'Total lease cost'**
  String get totalLeaseCost;

  /// No description provided for @mileageExceedsBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Mileage exceeds break-even — buying may be cheaper'**
  String get mileageExceedsBreakEven;

  /// No description provided for @mileageBelowBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Mileage below break-even — leasing may be cheaper'**
  String get mileageBelowBreakEven;

  /// No description provided for @informationalOnly.
  ///
  /// In en, this message translates to:
  /// **'For informational purposes only. Results depend on actual insurance rates, depreciation, and other factors.'**
  String get informationalOnly;

  /// No description provided for @leasingSaves.
  ///
  /// In en, this message translates to:
  /// **'Leasing saves {amount} over {months} months'**
  String leasingSaves(String amount, int months);

  /// No description provided for @buyingSaves.
  ///
  /// In en, this message translates to:
  /// **'Buying saves {amount} over {months} months'**
  String buyingSaves(String amount, int months);

  /// No description provided for @loan1.
  ///
  /// In en, this message translates to:
  /// **'Loan 1'**
  String get loan1;

  /// No description provided for @loan2.
  ///
  /// In en, this message translates to:
  /// **'Loan 2'**
  String get loan2;

  /// No description provided for @loan3.
  ///
  /// In en, this message translates to:
  /// **'Loan 3'**
  String get loan3;

  /// No description provided for @compare3Loans.
  ///
  /// In en, this message translates to:
  /// **'Compare 3 Loans'**
  String get compare3Loans;

  /// No description provided for @bestDeal.
  ///
  /// In en, this message translates to:
  /// **'Best Deal'**
  String get bestDeal;

  /// No description provided for @lowestTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Lowest Total Cost'**
  String get lowestTotalCost;

  /// No description provided for @trueCostOfOwnership.
  ///
  /// In en, this message translates to:
  /// **'True Cost of Ownership'**
  String get trueCostOfOwnership;

  /// No description provided for @ownershipPeriod.
  ///
  /// In en, this message translates to:
  /// **'Ownership Period'**
  String get ownershipPeriod;

  /// No description provided for @insurancePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Insurance (per month)'**
  String get insurancePerMonth;

  /// No description provided for @maintenancePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Maintenance (per month)'**
  String get maintenancePerMonth;

  /// No description provided for @depreciationRate.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Rate'**
  String get depreciationRate;

  /// No description provided for @costBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cost Breakdown'**
  String get costBreakdown;

  /// No description provided for @monthlyTrueCost.
  ///
  /// In en, this message translates to:
  /// **'Monthly True Cost'**
  String get monthlyTrueCost;

  /// No description provided for @totalCostOfOwnership.
  ///
  /// In en, this message translates to:
  /// **'Total Cost of Ownership'**
  String get totalCostOfOwnership;

  /// No description provided for @totalLoanCost.
  ///
  /// In en, this message translates to:
  /// **'Total Loan Cost'**
  String get totalLoanCost;

  /// No description provided for @totalFuel.
  ///
  /// In en, this message translates to:
  /// **'Total Fuel'**
  String get totalFuel;

  /// No description provided for @totalMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Total Maintenance'**
  String get totalMaintenance;

  /// No description provided for @depreciationLoss.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Loss'**
  String get depreciationLoss;

  /// No description provided for @totalInsurance.
  ///
  /// In en, this message translates to:
  /// **'Total Insurance'**
  String get totalInsurance;

  /// No description provided for @runningCosts.
  ///
  /// In en, this message translates to:
  /// **'Running Costs'**
  String get runningCosts;

  /// No description provided for @gasPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Gas (per month)'**
  String get gasPerMonth;

  /// No description provided for @loanInputAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get loanInputAmount;

  /// No description provided for @loanInputRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get loanInputRate;

  /// No description provided for @loanInputTerm.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get loanInputTerm;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportPdfPro.
  ///
  /// In en, this message translates to:
  /// **'Export PDF — PRO'**
  String get exportPdfPro;

  /// No description provided for @cashBackVsLowApr.
  ///
  /// In en, this message translates to:
  /// **'Cash-Back vs Low-APR'**
  String get cashBackVsLowApr;

  /// No description provided for @affordabilityGuide.
  ///
  /// In en, this message translates to:
  /// **'Affordability Guide'**
  String get affordabilityGuide;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
