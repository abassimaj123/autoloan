import 'app_config.dart';

final configUK = AppConfig(
  country: Country.UK,
  currency: 'GBP',
  currencySymbol: '£',
  distanceUnit: 'miles',
  biWeekly: false,
  balloon: false,
  tradeIn: false,
  roadTax: true,
  languages: ['en'],
  taxSystem: TaxSystem.vat, // VAT already included in UK advertised price
  defaultRate: 6.9,
  durations: [24, 36, 48, 60, 72, 84],
);
