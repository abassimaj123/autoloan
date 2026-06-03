class CAProvince {
  final String code, nameEn, nameFr;
  final double gst, pst, hst;
  final bool usesHST;

  const CAProvince({
    required this.code,
    required this.nameEn,
    required this.nameFr,
    this.gst = 0,
    this.pst = 0,
    this.hst = 0,
    this.usesHST = false,
  });

  double get totalRate => usesHST ? hst : gst + pst;
  String get label => '$nameEn (${(totalRate * 100).toStringAsFixed(1)}%)';
}

const kCAProvinces = [
  CAProvince(code: 'AB', nameEn: 'Alberta', nameFr: 'Alberta', gst: 0.05),
  CAProvince(
    code: 'BC',
    nameEn: 'British Columbia',
    nameFr: 'Colombie-Britannique',
    gst: 0.05,
    pst: 0.07,
  ),
  CAProvince(
    code: 'MB',
    nameEn: 'Manitoba',
    nameFr: 'Manitoba',
    gst: 0.05,
    pst: 0.07,
  ),
  CAProvince(
    code: 'NB',
    nameEn: 'New Brunswick',
    nameFr: 'Nouveau-Brunswick',
    hst: 0.15,
    usesHST: true,
  ),
  CAProvince(
    code: 'NL',
    nameEn: 'Newfoundland & Labrador',
    nameFr: 'Terre-Neuve-et-Labrador',
    hst: 0.15,
    usesHST: true,
  ),
  CAProvince(
    code: 'NS',
    nameEn: 'Nova Scotia',
    nameFr: 'Nouvelle-Écosse',
    hst: 0.14, // Reduced from 15% to 14% effective April 2025
    usesHST: true,
  ),
  CAProvince(
    code: 'NT',
    nameEn: 'Northwest Territories',
    nameFr: 'Territoires du Nord-Ouest',
    gst: 0.05,
  ),
  CAProvince(code: 'NU', nameEn: 'Nunavut', nameFr: 'Nunavut', gst: 0.05),
  CAProvince(
    code: 'ON',
    nameEn: 'Ontario',
    nameFr: 'Ontario',
    hst: 0.13,
    usesHST: true,
  ),
  CAProvince(
    code: 'PE',
    nameEn: 'Prince Edward Island',
    nameFr: 'Île-du-Prince-Édouard',
    hst: 0.15,
    usesHST: true,
  ),
  CAProvince(
    code: 'QC',
    nameEn: 'Quebec',
    nameFr: 'Québec',
    gst: 0.05,
    pst: 0.09975,
  ),
  CAProvince(
    code: 'SK',
    nameEn: 'Saskatchewan',
    nameFr: 'Saskatchewan',
    gst: 0.05,
    pst: 0.06,
  ),
  CAProvince(code: 'YT', nameEn: 'Yukon', nameFr: 'Yukon', gst: 0.05),
];

CAProvince caProvinceByCode(String code) => kCAProvinces.firstWhere(
  (p) => p.code == code,
  orElse: () => kCAProvinces.firstWhere(
    (p) => p.code == 'ON',
    orElse: () => kCAProvinces.first,
  ),
);
