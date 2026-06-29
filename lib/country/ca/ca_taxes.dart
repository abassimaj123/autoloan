import 'package:calcwise_core/calcwise_core.dart';

/// A Canadian province/territory for the auto-loan sales-tax calculation.
///
/// Identity (code + display names) lives here; the sales-tax **rate** is sourced
/// from the shared [CalcwiseTax] registry (baked-in floor, remote-updatable), so
/// rates stay in one place across the portfolio. AutoLoan's province codes map
/// to registry jurisdiction codes as `ca_<lowercased code>` (e.g. ON → ca_on).
class CAProvince {
  final String code, nameEn, nameFr;

  const CAProvince({
    required this.code,
    required this.nameEn,
    required this.nameFr,
  });

  /// Registry jurisdiction code, e.g. `ca_on`.
  String get _juris => 'ca_${code.toLowerCase()}';

  SalesTax? get _salesTax => CalcwiseTax.registry.salesTax(_juris);

  /// Goods & Services Tax component (decimal), or 0 if not applicable.
  double get gst => _salesTax?.gst ?? 0;

  /// Provincial Sales Tax / Quebec Sales Tax component (decimal), or 0.
  double get pst => _salesTax?.pst ?? _salesTax?.qst ?? 0;

  /// Harmonized Sales Tax (decimal), or 0 if the province is not harmonized.
  double get hst => _salesTax?.hst ?? 0;

  /// Combined consumption-tax rate applied to a vehicle purchase (decimal).
  /// Reads the registry's pre-computed `combined`, falling back to summing the
  /// individual components if `combined` is absent.
  double get totalRate => _salesTax?.combined ?? (gst + pst + hst);

  String get label => '$nameEn (${(totalRate * 100).toStringAsFixed(1)}%)';
}

const kCAProvinces = [
  CAProvince(code: 'AB', nameEn: 'Alberta', nameFr: 'Alberta'),
  CAProvince(
    code: 'BC',
    nameEn: 'British Columbia',
    nameFr: 'Colombie-Britannique',
  ),
  CAProvince(code: 'MB', nameEn: 'Manitoba', nameFr: 'Manitoba'),
  CAProvince(
    code: 'NB',
    nameEn: 'New Brunswick',
    nameFr: 'Nouveau-Brunswick',
  ),
  CAProvince(
    code: 'NL',
    nameEn: 'Newfoundland & Labrador',
    nameFr: 'Terre-Neuve-et-Labrador',
  ),
  CAProvince(
    code: 'NS',
    nameEn: 'Nova Scotia',
    nameFr: 'Nouvelle-Écosse',
  ),
  CAProvince(
    code: 'NT',
    nameEn: 'Northwest Territories',
    nameFr: 'Territoires du Nord-Ouest',
  ),
  CAProvince(code: 'NU', nameEn: 'Nunavut', nameFr: 'Nunavut'),
  CAProvince(code: 'ON', nameEn: 'Ontario', nameFr: 'Ontario'),
  CAProvince(
    code: 'PE',
    nameEn: 'Prince Edward Island',
    nameFr: 'Île-du-Prince-Édouard',
  ),
  CAProvince(code: 'QC', nameEn: 'Quebec', nameFr: 'Québec'),
  CAProvince(code: 'SK', nameEn: 'Saskatchewan', nameFr: 'Saskatchewan'),
  CAProvince(code: 'YT', nameEn: 'Yukon', nameFr: 'Yukon'),
];

CAProvince caProvinceByCode(String code) => kCAProvinces.firstWhere(
  (p) => p.code == code,
  orElse: () => kCAProvinces.firstWhere(
    (p) => p.code == 'ON',
    orElse: () => kCAProvinces.first,
  ),
);
