// ignore: constant_identifier_names
enum Country { CA, UK, US }

enum TaxSystem { provincial, gst, vat, manual }

class AppConfig {
  final Country country;
  final String currency;
  final String currencySymbol;
  final String distanceUnit;
  final bool biWeekly;
  final bool balloon;
  final bool tradeIn;
  final bool roadTax;
  final List<String> languages;
  final TaxSystem taxSystem;
  final double defaultRate;
  final List<int> durations;

  const AppConfig({
    required this.country,
    required this.currency,
    required this.currencySymbol,
    required this.distanceUnit,
    required this.biWeekly,
    required this.balloon,
    required this.tradeIn,
    this.roadTax = false,
    required this.languages,
    required this.taxSystem,
    required this.defaultRate,
    required this.durations,
  });

  bool get isCA => country == Country.CA;
  bool get isUK => country == Country.UK;
  bool get isUS => country == Country.US;
}
