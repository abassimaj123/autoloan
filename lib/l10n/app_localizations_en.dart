// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appNameCA => 'Auto Loan Canada';

  @override
  String get appNameUK => 'Auto Loan UK';

  @override
  String get appNameUS => 'Auto Loan USA';

  @override
  String get calculate => 'Calculate';

  @override
  String get vehiclePrice => 'Vehicle Price';

  @override
  String get downPayment => 'Down Payment';

  @override
  String get annualRate => 'Annual Interest Rate';

  @override
  String get termMonths => 'Loan Term';

  @override
  String get monthlyPayment => 'Monthly Payment';

  @override
  String get biWeeklyPayment => 'Bi-weekly Payment';

  @override
  String get weeklyPayment => 'Weekly Payment';

  @override
  String get paymentFrequency => 'Payment Frequency';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyBiWeekly => 'Bi-weekly';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get totalInterest => 'Total Interest';

  @override
  String get totalCost => 'Total Vehicle Cost';

  @override
  String get financedAmount => 'Financed Amount';

  @override
  String get totalInsurances => 'Total Insurances';

  @override
  String get loanAmount => 'Loan Amount';

  @override
  String get tradeInValue => 'Trade-in Value';

  @override
  String get dealerFees => 'Dealer Fees';

  @override
  String get salesTax => 'Sales Tax';

  @override
  String get taxAmount => 'Tax Amount';

  @override
  String get results => 'Results';

  @override
  String get loanTerms => 'Loan Terms';

  @override
  String get province => 'Province / Territory';

  @override
  String get state => 'State / Territory';

  @override
  String get creditScore => 'Credit Score';

  @override
  String get effectiveRate => 'Effective Rate';

  @override
  String get balloonPayment => 'Balloon Payment';

  @override
  String get balloonPercent => 'Balloon % of vehicle price';

  @override
  String get balloonAmount => 'Balloon Amount';

  @override
  String get driveAwayPrice => 'Drive-away Price';

  @override
  String get gst => 'GST (10%)';

  @override
  String get insurance => 'Optional Insurance';

  @override
  String get lifeDisability => 'Life & Disability';

  @override
  String get extendedWarranty => 'Extended Warranty';

  @override
  String get gap => 'GAP Insurance';

  @override
  String get history => 'History';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get noHistory => 'No calculations yet.';

  @override
  String get historyEmptyBody => 'Your saved calculations will appear here.';

  @override
  String get amortization => 'Amortization Schedule';

  @override
  String get unlockFull => 'Unlock full results:';

  @override
  String get watchAd => 'Watch ad for full access (60 min)';

  @override
  String get adNotAvailable => 'Ad not available. Try again later.';

  @override
  String get fullAccessActive => 'Full access active';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$days trial day$_temp0 remaining';
  }

  @override
  String get biWeeklyToggle => 'Bi-weekly payments';

  @override
  String get biWeeklySubtitle => '26 payments per year';

  @override
  String get noAdjustment => 'No adjustment';

  @override
  String rateDiscount(String rate) {
    return '-$rate% rate discount';
  }

  @override
  String ratePremium(String rate) {
    return '+$rate% rate premium';
  }

  @override
  String get loanOnly => 'Loan only /mo';

  @override
  String get totalCostShort => 'Total Cost';

  @override
  String get usePercentage => 'Use % of price';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get month => 'mo';

  @override
  String get year => 'yr';

  @override
  String get payment => 'Payment';

  @override
  String get principal => 'Principal';

  @override
  String get interest => 'Interest';

  @override
  String get balance => 'Balance';

  @override
  String get roadTax => 'Road Tax (VED)';

  @override
  String get vedAnnual => 'Annual Road Tax';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get includeRoadTax => 'Include Road Tax in monthly payment';

  @override
  String get totalVed => 'Total Road Tax';

  @override
  String get getPremiumUS => 'Get Premium';

  @override
  String get getPremiumUK => 'Get Premium';

  @override
  String get getPremiumCA => 'Get Premium';

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get rewardDailyLimit => 'Come back tomorrow for another free hour';

  @override
  String get settings => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsPremiumSubtitle => 'No ads · Unlimited history';

  @override
  String get settingsPremiumActive => '⭐ Premium — Unlimited access';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsContact => 'Contact support';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsOtherApps => 'Our other apps';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get premiumBenefits =>
      'Amortization schedule · PDF export · Unlimited history';

  @override
  String get lockSharing => 'Unlock to share & export';

  @override
  String get compareLoans => 'Compare Loans';

  @override
  String get scenario => 'Scenario';

  @override
  String get betterDeal => 'Better Deal';

  @override
  String get totalSavings => 'Total Savings';

  @override
  String get financingType => 'Financing Type';

  @override
  String get standardLoan => 'Standard Loan';

  @override
  String get pcp => 'PCP';

  @override
  String get gmfv => 'GMFV (Guaranteed Min. Future Value)';

  @override
  String get gmfvPercent => 'GMFV % of vehicle price';

  @override
  String get pcpNote => 'At term end: pay GMFV, trade in, or return vehicle';

  @override
  String get pcpPayment => 'PCP Monthly Payment';

  @override
  String get pcpFinalPayment => 'Final Balloon Payment';

  @override
  String get settingsDisclaimer =>
      'For informational purposes only. Not financial advice. Consult a qualified advisor before making financial decisions.';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get onboardingTitle1 => 'Calculate your auto loan';

  @override
  String get onboardingSubtitle1 =>
      'Get your monthly payment, total interest, and full cost instantly. Supports CA, UK, and US markets.';

  @override
  String get onboardingTitle2 => 'Compare scenarios';

  @override
  String get onboardingSubtitle2 =>
      'Compare two loan scenarios side by side — different terms, down payments, or interest rates. Find the best deal.';

  @override
  String get onboardingTitle3 => 'Go premium';

  @override
  String get onboardingSubtitle3 =>
      'Unlock the amortization schedule, PDF export, and unlimited history. One small purchase, no subscription.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingFeaturePayment => 'Monthly payment';

  @override
  String get onboardingFeatureInterest => 'Total interest';

  @override
  String get onboardingFeatureCost => 'Full loan cost';

  @override
  String get onboardingFeatureAmortization => 'Amortization';

  @override
  String get onboardingFeatureCompare => 'Loan comparison';

  @override
  String get onboardingFeaturePDF => 'PDF export';

  @override
  String get onboardingPremiumBullet1 => 'Full amortization schedule';

  @override
  String get onboardingPremiumBullet2 => 'PDF export & sharing';

  @override
  String get onboardingPremiumBullet3 => 'Unlimited calculation history';

  @override
  String get earlyPayoff => 'Early Payoff';

  @override
  String get loanSummary => 'Loan Summary';

  @override
  String get extraMonthlyPayment => 'Extra Monthly Payment';

  @override
  String get extraAmountPerMonth => 'Extra amount per month';

  @override
  String get withExtraPayment => 'With Extra Payment';

  @override
  String get newMonthlyPayment => 'New Monthly Payment';

  @override
  String get paidOffIn => 'Paid off in';

  @override
  String get youSave => 'You save';

  @override
  String get interestSaved => 'Interest saved';

  @override
  String get monthsSaved => 'Months saved';

  @override
  String get leaseVsBuy => 'Lease vs Buy';

  @override
  String get buyLoanDetails => 'Buy — Loan Details';

  @override
  String get vehiclePriceMsrp => 'Vehicle price (MSRP)';

  @override
  String get interestRateApr => 'Interest rate (APR)';

  @override
  String get residualValuePct => 'Residual value (%)';

  @override
  String get annualInsuranceCost => 'Annual insurance cost';

  @override
  String get leaseDetails => 'Lease Details';

  @override
  String get monthlyLeasePayment => 'Monthly lease payment';

  @override
  String get lvbLeaseTerm => 'Lease term (months)';

  @override
  String get downPaymentCap => 'Down payment / cap reduction';

  @override
  String get acquisitionFee => 'Acquisition fee';

  @override
  String get dispositionFee => 'Disposition fee';

  @override
  String get mileageLimitPerYear => 'Mileage limit per year';

  @override
  String get overageCostPer => 'Overage cost per';

  @override
  String get estimatedAnnualDriven => 'Estimated annual miles driven';

  @override
  String get compareLeaseBuy => 'Compare Lease vs Buy';

  @override
  String get comparisonResults => 'Comparison Results';

  @override
  String get betterBadge => 'BETTER';

  @override
  String get totalLabel => 'Total';

  @override
  String get buyBreakdown => 'Buy Breakdown';

  @override
  String get totalInterestPaid => 'Total interest paid';

  @override
  String get insuranceOverTerm => 'Insurance over term';

  @override
  String get totalBuyCost => 'Total buy cost';

  @override
  String get leaseBreakdown => 'Lease Breakdown';

  @override
  String get estimatedMileageOverage => 'Estimated mileage overage';

  @override
  String get totalLeaseCost => 'Total lease cost';

  @override
  String get mileageExceedsBreakEven =>
      'Mileage exceeds break-even — buying may be cheaper';

  @override
  String get mileageBelowBreakEven =>
      'Mileage below break-even — leasing may be cheaper';

  @override
  String get informationalOnly =>
      'For informational purposes only. Results depend on actual insurance rates, depreciation, and other factors.';

  @override
  String leasingSaves(String amount, int months) {
    return 'Leasing saves $amount over $months months';
  }

  @override
  String buyingSaves(String amount, int months) {
    return 'Buying saves $amount over $months months';
  }

  @override
  String get loan1 => 'Loan 1';

  @override
  String get loan2 => 'Loan 2';

  @override
  String get loan3 => 'Loan 3';

  @override
  String get compare3Loans => 'Compare 3 Loans';

  @override
  String get bestDeal => 'Best Deal';

  @override
  String get lowestTotalCost => 'Lowest Total Cost';

  @override
  String get trueCostOfOwnership => 'True Cost of Ownership';

  @override
  String get ownershipPeriod => 'Ownership Period';

  @override
  String get insurancePerMonth => 'Insurance (per month)';

  @override
  String get maintenancePerMonth => 'Maintenance (per month)';

  @override
  String get depreciationRate => 'Depreciation Rate';

  @override
  String get costBreakdown => 'Cost Breakdown';

  @override
  String get monthlyTrueCost => 'Monthly True Cost';

  @override
  String get totalCostOfOwnership => 'Total Cost of Ownership';

  @override
  String get totalLoanCost => 'Total Loan Cost';

  @override
  String get totalFuel => 'Total Fuel';

  @override
  String get totalMaintenance => 'Total Maintenance';

  @override
  String get depreciationLoss => 'Depreciation Loss';

  @override
  String get totalInsurance => 'Total Insurance';

  @override
  String get runningCosts => 'Running Costs';

  @override
  String get gasPerMonth => 'Gas (per month)';

  @override
  String get loanInputAmount => 'Amount';

  @override
  String get loanInputRate => 'Rate';

  @override
  String get loanInputTerm => 'Term';

  @override
  String get share => 'Share';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportPdfPro => 'Export PDF — PRO';

  @override
  String get cashBackVsLowApr => 'Cash-Back vs Low-APR';

  @override
  String get affordabilityGuide => 'Affordability Guide';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsPrivacySettings => 'Privacy Settings';

  @override
  String get historySavedScenarios => 'Saved Scenarios';

  @override
  String get historyRecentCalc => 'Recent Calculations';

  @override
  String historyClearAll(int count) {
    return 'Clear all $count calculations? This cannot be undone.';
  }

  @override
  String get historyCancel => 'Cancel';

  @override
  String get historyClearAction => 'Clear';

  @override
  String historyLimitNudge(int limit) {
    return 'History limit reached ($limit). Upgrade to keep all future calculations.';
  }

  @override
  String historyLockedCount(int count) {
    return '$count older records locked';
  }

  @override
  String get historyDeleteTitle => 'Delete entry';

  @override
  String get historyDeleteConfirm =>
      'Remove this calculation? Cannot be undone.';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyRename => 'Rename';

  @override
  String get historyRenameTitle => 'Rename scenario';

  @override
  String get historyRenameHint => 'Scenario name';

  @override
  String get historyRemovePin => 'Remove pin';

  @override
  String get histDetailAnnualRate => 'Annual Rate';

  @override
  String get histDetailProvince => 'Province';

  @override
  String get histDetailTotalCost => 'Total Cost of Loan';

  @override
  String histDetailTitle(String country) {
    return '$country Loan Detail';
  }

  @override
  String histDetailSummaryTitle(String country) {
    return 'Auto Loan $country — Loan Summary';
  }

  @override
  String histDetailFooter(String country) {
    return 'Calculated with Auto Loan $country';
  }

  @override
  String get amortScheduleTab => 'Schedule';

  @override
  String get amortPayoffChart => 'Payoff Chart';

  @override
  String get amortRemainingBalance => 'Remaining Balance Over Time';

  @override
  String get amortRemainingBalanceLegend => 'Remaining Balance';

  @override
  String get amortNoData => 'No data to display.';

  @override
  String get amortShareSchedule => 'Share Schedule';

  @override
  String get amortBiWkPayment => 'Bi-wk Payment';

  @override
  String get amortBiWeeklyHeader => 'Bi-weekly payment';

  @override
  String get pdfExportSuccess => 'PDF exported successfully';

  @override
  String get pdfExportFailed => 'Export failed';
}
