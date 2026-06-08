import 'app_config.dart';

final configCA = AppConfig(
  country: Country.CA,
  currency: 'CAD',
  currencySymbol: 'C\$',
  distanceUnit: 'km',
  biWeekly: true,
  balloon: false,
  tradeIn: false,
  languages: ['fr', 'en'],
  taxSystem: TaxSystem.provincial,
  defaultRate: 7.9,
  durations: [24, 36, 48, 60, 72, 84],
);
