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
