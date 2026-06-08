import 'app_config.dart';

final configUS = AppConfig(
  country: Country.US,
  currency: 'USD',
  currencySymbol: '\$',
  distanceUnit: 'miles',
  biWeekly: false,
  balloon: false,
  tradeIn: true,
  languages: ['en', 'es'],
  taxSystem: TaxSystem.manual,
  defaultRate: 8.9,
  durations: [24, 36, 48, 60, 72, 84],
);
