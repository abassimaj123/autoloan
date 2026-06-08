import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../amortization/amortization_screen.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

class PdfExportService {
  /// Build and share a PDF with a summary section + full amortization table.
  ///
  /// [summary] is an ordered list of label/value pairs shown before the table
  /// (e.g. Monthly Payment, Loan Amount, Total Interest, Total Cost…).
  ///
  /// [isFrench] / [isSpanish] translate section headers and column labels.
  static Future<void> exportLoanPdf({
    required String title,
    required String currencySymbol,
    required double loanAmount,
    required double annualRate,
    required int termMonths,
    required double downPayment,
    double balloonAmount = 0,
    double insuranceMonthly = 0,
    List<MapEntry<String, String>> summary = const [],
    bool isFrench = false,
    bool isSpanish = false,
  }) async {
    final rows = buildSchedule(
      loanAmount: loanAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      balloonAmount: balloonAmount,
    );

    final fmt = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    final fmtInt = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    final totalInterest = rows.fold(0.0, (s, r) => s + r.interest);
    final totalPayments = rows.fold(0.0, (s, r) => s + r.payment);
    final totalCost =
        totalPayments + downPayment + insuranceMonthly * termMonths;

    // ── Translated labels ────────────────────────────────────────────────────
    final tSummary =
        isFrench ? 'Résumé' : (isSpanish ? 'Resumen' : 'Summary');
    final tTotalInterest = isFrench
        ? 'Intérêt total'
        : (isSpanish ? 'Interés total' : 'Total Interest');
    final tTotalCostLabel =
        isFrench ? 'Coût total' : (isSpanish ? 'Costo total' : 'Total Cost');
    final tAmortization = isFrench
        ? "Tableau d'amortissement"
        : (isSpanish ? 'Tabla de amortización' : 'Amortization Schedule');
    final tPayment =
        isFrench ? 'Paiement' : (isSpanish ? 'Pago' : 'Payment');
    final tPrincipal =
        isFrench ? 'Capital' : (isSpanish ? 'Capital' : 'Principal');
    final tInterest =
        isFrench ? 'Intérêt' : (isSpanish ? 'Interés' : 'Interest');
    final tBalance =
        isFrench ? 'Solde' : (isSpanish ? 'Saldo' : 'Balance');

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: AppTextSize.body,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              DateFormat.yMMMMd().format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              '${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 8),

          // ── Summary ──────────────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  tSummary,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: AppTextSize.sm,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...summary.map((e) => _summaryRow(e.key, e.value)),
                if (summary.isNotEmpty) pw.Divider(color: PdfColors.grey400),
                _summaryRow(tTotalInterest, fmt.format(totalInterest)),
                _summaryRow(
                  tTotalCostLabel,
                  fmtInt.format(totalCost),
                  highlight: true,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Amortization table ────────────────────────────────────────────
          pw.Text(
            tAmortization,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: AppTextSize.sm,
            ),
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(2.2),
              4: pw.FlexColumnWidth(2.2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                ),
                children: [
                  '#',
                  tPayment,
                  tPrincipal,
                  tInterest,
                  tBalance,
                ].map((h) => _cell(h, header: true)).toList(),
              ),
              // Data rows
              ...rows.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColors.grey50;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell('${r.month}'),
                    _cell(fmt.format(r.payment + insuranceMonthly)),
                    _cell(fmt.format(r.principal)),
                    _cell(fmt.format(r.interest)),
                    _cell(fmt.format(r.balance), bold: r.balance < 0.01),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
  }

  /// Export a loan comparison (3 loans) to PDF and share.
  static Future<void> exportLoanComparison({
    required String title,
    required String currency,
    required List<double> amounts,
    required List<double> rates,
    required List<int> terms,
    required List<double> monthlyPayments,
    required List<double> totalInterests,
    required List<double> totalCosts,
    required int winnerIndex,
    bool isFrench = false,
    bool isSpanish = false,
  }) async {
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    final tSummary =
        isFrench ? 'Résumé' : (isSpanish ? 'Resumen' : 'Summary');
    final tInputs = isFrench
        ? 'Paramètres'
        : (isSpanish ? 'Parámetros' : 'Parameters');
    final tMonthly = isFrench
        ? 'Paiement mensuel'
        : (isSpanish ? 'Cuota mensual' : 'Monthly Payment');
    final tTotalInterest = isFrench
        ? 'Intérêt total'
        : (isSpanish ? 'Interés total' : 'Total Interest');
    final tTotalCostLabel =
        isFrench ? 'Coût total' : (isSpanish ? 'Costo total' : 'Total Cost');
    final tBestDeal =
        isFrench ? 'Meilleure offre' : (isSpanish ? 'Mejor oferta' : 'Best Deal');
    final tFooter = isFrench
        ? 'À titre informatif seulement. Les taux et frais varient selon le prêteur.'
        : (isSpanish
            ? 'Solo con fines informativos. Las tasas y cargos varían según el prestamista.'
            : 'For informational purposes only. Rates and fees vary by lender.');
    final tMo = isFrench ? 'mois' : (isSpanish ? 'mes' : 'mo');

    final pdf = pw.Document();

    final loanLabels = <String>[];
    for (int i = 0; i < amounts.length; i++) {
      loanLabels.add(
          isFrench ? 'Prêt ${i + 1}' : (isSpanish ? 'Préstamo ${i + 1}' : 'Loan ${i + 1}'));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Inputs section
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tInputs,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: AppTextSize.sm,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Table header
                  pw.Row(children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold))),
                    for (int i = 0; i < loanLabels.length; i++)
                      pw.Expanded(
                        child: pw.Text(
                          loanLabels[i],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                  ]),
                  pw.SizedBox(height: 4),
                  _compTableRow(
                    isFrench
                        ? 'Montant'
                        : (isSpanish ? 'Monto' : 'Amount'),
                    amounts.map((a) => fmt.format(a)).toList(),
                  ),
                  _compTableRow(
                    isFrench ? 'Taux' : (isSpanish ? 'Tasa' : 'Rate'),
                    rates
                        .map((r) => '${r.toStringAsFixed(2)}%')
                        .toList(),
                  ),
                  _compTableRow(
                    isFrench ? 'Durée' : (isSpanish ? 'Plazo' : 'Term'),
                    terms.map((t) => '$t $tMo').toList(),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Results section
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tSummary,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: AppTextSize.sm,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Header row
                  pw.Row(children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold))),
                    for (int i = 0; i < loanLabels.length; i++)
                      pw.Expanded(
                        child: pw.Text(
                          loanLabels[i],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: i == winnerIndex
                                ? PdfColors.blue800
                                : PdfColors.black,
                          ),
                        ),
                      ),
                  ]),
                  pw.SizedBox(height: 4),
                  _compTableRow(
                    tMonthly,
                    monthlyPayments
                        .map((v) => fmt.format(v))
                        .toList(),
                    winnerIndex: winnerIndex,
                  ),
                  _compTableRow(
                    tTotalInterest,
                    totalInterests
                        .map((v) => fmt.format(v))
                        .toList(),
                    winnerIndex: winnerIndex,
                  ),
                  pw.Divider(color: PdfColors.grey400),
                  _compTableRow(
                    tTotalCostLabel,
                    totalCosts.map((v) => fmt.format(v)).toList(),
                    winnerIndex: winnerIndex,
                    bold: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Winner callout
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.blue800, width: 3),
                ),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.sm),
              child: pw.Text(
                '$tBestDeal: ${loanLabels[winnerIndex]} — ${fmt.format(totalCosts[winnerIndex])}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),

            pw.Spacer(),

            // Footer
            pw.Text(
              tFooter,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
  }

  /// Export total cost of ownership to PDF and share.
  static Future<void> exportTotalCost({
    required String title,
    required String currency,
    required double vehiclePrice,
    required double monthlyPayment,
    required int ownershipYears,
    required double insurance,
    required double fuel,
    required double maintenance,
    required double depreciationRate,
    required double totalLoan,
    required double totalInsurance,
    required double totalFuel,
    required double totalMaintenance,
    required double depreciationLoss,
    required double grandTotal,
    required double costPerMonth,
    required String fuelLabel,
    required String distUnit,
    bool isFrench = false,
    bool isSpanish = false,
  }) async {
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    final tInputs = isFrench
        ? 'Paramètres'
        : (isSpanish ? 'Parámetros' : 'Parameters');
    final tResults =
        isFrench ? 'Résultats' : (isSpanish ? 'Resultados' : 'Results');
    final tVehiclePrice = isFrench
        ? 'Prix du véhicule'
        : (isSpanish ? 'Precio del vehículo' : 'Vehicle Price');
    final tMonthlyPayment = isFrench
        ? 'Paiement mensuel'
        : (isSpanish ? 'Cuota mensual' : 'Monthly Payment');
    final tOwnershipPeriod = isFrench
        ? 'Période de possession'
        : (isSpanish ? 'Período de propiedad' : 'Ownership Period');
    final tInsurance = isFrench
        ? 'Assurance / mois'
        : (isSpanish ? 'Seguro / mes' : 'Insurance / mo');
    final tMaintenance = isFrench
        ? 'Entretien / mois'
        : (isSpanish ? 'Mantenimiento / mes' : 'Maintenance / mo');
    final tDepRate = isFrench
        ? 'Taux de dépréciation'
        : (isSpanish ? 'Tasa de depreciación' : 'Depreciation Rate');
    final tTotalLoan = isFrench
        ? 'Coût total du prêt'
        : (isSpanish ? 'Costo total del préstamo' : 'Total Loan Cost');
    final tTotalInsurance = isFrench
        ? 'Assurance totale'
        : (isSpanish ? 'Seguro total' : 'Total Insurance');
    final tTotalFuel =
        isFrench ? 'Carburant total' : (isSpanish ? 'Combustible total' : 'Total Fuel');
    final tTotalMaintenance = isFrench
        ? 'Entretien total'
        : (isSpanish ? 'Mantenimiento total' : 'Total Maintenance');
    final tDepLoss = isFrench
        ? 'Perte de valeur'
        : (isSpanish ? 'Pérdida por depreciación' : 'Depreciation Loss');
    final tGrandTotal = isFrench
        ? 'Coût total de possession'
        : (isSpanish ? 'Costo total de propiedad' : 'Total Cost of Ownership');
    final tMonthlyCost = isFrench
        ? 'Coût mensuel réel'
        : (isSpanish ? 'Costo mensual real' : 'Monthly True Cost');
    final tYr = isFrench ? 'ans' : (isSpanish ? 'años' : 'yr');
    final tMo = isFrench ? 'mois' : (isSpanish ? 'mes' : 'mo');
    final tFooter = isFrench
        ? 'À titre informatif seulement. La dépréciation varie selon la marque, le modèle et les $distUnit parcourus.'
        : (isSpanish
            ? 'Solo con fines informativos. La depreciación varía según la marca, modelo y $distUnit recorridos.'
            : 'For informational purposes only. Depreciation estimates vary by vehicle make, model, and $distUnit driven.');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Inputs section
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tInputs,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: AppTextSize.sm,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _summaryRow(tVehiclePrice, fmt.format(vehiclePrice)),
                  _summaryRow(tMonthlyPayment, fmt2.format(monthlyPayment)),
                  _summaryRow(
                    tOwnershipPeriod,
                    '$ownershipYears $tYr',
                  ),
                  _summaryRow(tInsurance, fmt2.format(insurance)),
                  _summaryRow(fuelLabel, fmt2.format(fuel)),
                  _summaryRow(tMaintenance, fmt2.format(maintenance)),
                  _summaryRow(
                    tDepRate,
                    '${depreciationRate.toStringAsFixed(0)}% / $tYr',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Results section
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tResults,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: AppTextSize.sm,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _summaryRow(tTotalLoan, fmt.format(totalLoan)),
                  _summaryRow(
                      tTotalInsurance, fmt.format(totalInsurance)),
                  _summaryRow(tTotalFuel, fmt.format(totalFuel)),
                  _summaryRow(
                      tTotalMaintenance, fmt.format(totalMaintenance)),
                  _summaryRow(tDepLoss, fmt.format(depreciationLoss)),
                  pw.Divider(color: PdfColors.grey400),
                  _summaryRow(
                    '$tGrandTotal ($ownershipYears $tYr)',
                    fmt.format(grandTotal),
                    highlight: true,
                  ),
                  _summaryRow(
                    tMonthlyCost,
                    '${fmt.format(costPerMonth)}/$tMo',
                    highlight: true,
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Footer
            pw.Text(
              tFooter,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
  }

  /// Export Lease vs Buy analysis to PDF and share.
  static Future<void> exportLeaseVsBuy({
    required String title,
    required String currency,
    required double vehiclePrice,
    required double buyDown,
    required double buyApr,
    required int buyTerm,
    required double residualPercent,
    required double annualInsurance,
    required double leaseMonthly,
    required int leaseTerm,
    required double leaseDown,
    required double acquisitionFee,
    required double dispositionFee,
    required double buyMonthly,
    required double buyTotalCost,
    required double buyTotalInterest,
    required double buyInsuranceCost,
    required double leaseTotalCost,
    required double breakEvenMiles,
    required bool leaseIsChEaper,
    required double saving,
    required String distLabel,
    bool isFrench = false,
    bool isSpanish = false,
  }) async {
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final fmt0 = NumberFormat.currency(symbol: currency, decimalDigits: 0);

    final tInputs = isFrench ? 'Paramètres' : (isSpanish ? 'Parámetros' : 'Parameters');
    final tResults = isFrench ? 'Résultats' : (isSpanish ? 'Resultados' : 'Results');
    final tVehiclePrice = isFrench ? 'Prix du véhicule (PDSF)' : (isSpanish ? 'Precio del vehículo' : 'Vehicle Price (MSRP)');
    final tBuyDetails = isFrench ? 'Achat — détails' : (isSpanish ? 'Compra — detalles' : 'Purchase — Details');
    final tLeaseDetails = isFrench ? 'Location — détails' : (isSpanish ? 'Arrendamiento — detalles' : 'Lease — Details');
    final tDownPayment = isFrench ? 'Mise de fonds' : (isSpanish ? 'Pago inicial' : 'Down Payment');
    final tApr = isFrench ? 'Taux annuel' : (isSpanish ? 'Tasa APR' : 'Annual Rate (APR)');
    final tTerm = isFrench ? 'Durée' : (isSpanish ? 'Plazo' : 'Term');
    final tResidual = isFrench ? 'Valeur résiduelle' : (isSpanish ? 'Valor residual' : 'Residual Value');
    final tInsurance = isFrench ? 'Assurance annuelle' : (isSpanish ? 'Seguro anual' : 'Annual Insurance');
    final tMonthlyPayment = isFrench ? 'Paiement mensuel' : (isSpanish ? 'Cuota mensual' : 'Monthly Payment');
    final tTotalInterest = isFrench ? 'Intérêt total' : (isSpanish ? 'Interés total' : 'Total Interest');
    final tInsuranceCost = isFrench ? 'Coût assurance' : (isSpanish ? 'Costo seguro' : 'Insurance Cost');
    final tTotalBuyCost = isFrench ? 'Coût total achat' : (isSpanish ? 'Costo total compra' : 'Total Purchase Cost');
    final tLeasePayment = isFrench ? 'Paiement mensuel location' : (isSpanish ? 'Cuota mensual arriendo' : 'Monthly Lease Payment');
    final tAcqFee = isFrench ? 'Frais d\'acquisition' : (isSpanish ? 'Cargo de adquisición' : 'Acquisition Fee');
    final tDispFee = isFrench ? 'Frais de disposition' : (isSpanish ? 'Cargo de disposición' : 'Disposition Fee');
    final tTotalLeaseCost = isFrench ? 'Coût total location' : (isSpanish ? 'Costo total arriendo' : 'Total Lease Cost');
    final tBreakEven = isFrench ? 'Kilométrage seuil de rentabilité' : (isSpanish ? 'Millaje de equilibrio' : 'Break-Even Mileage');
    final tRecommendation = isFrench ? 'Recommandation' : (isSpanish ? 'Recomendación' : 'Recommendation');
    final tSavings = isFrench ? 'Économies' : (isSpanish ? 'Ahorros' : 'Savings');
    final tWinner = leaseIsChEaper
        ? (isFrench ? 'LOUER est plus avantageux' : (isSpanish ? 'ARRENDAR es más ventajoso' : 'LEASING is the better deal'))
        : (isFrench ? 'ACHETER est plus avantageux' : (isSpanish ? 'COMPRAR es más ventajoso' : 'BUYING is the better deal'));
    final tFooter = isFrench
        ? 'À titre informatif seulement. Les frais de dépassement de kilométrage peuvent s\'appliquer.'
        : (isSpanish
            ? 'Solo con fines informativos. Pueden aplicarse cargos por exceso de millaje.'
            : 'For informational purposes only. Mileage overage fees may apply.');
    final tMo = isFrench ? 'mois' : (isSpanish ? 'mes' : 'mo');
    final tYr = isFrench ? 'ans' : (isSpanish ? 'años' : 'yr');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 12),

            // Vehicle price
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tInputs,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: AppTextSize.sm)),
                  pw.SizedBox(height: 8),
                  _summaryRow(tVehiclePrice, fmt0.format(vehiclePrice)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Buy vs Lease side-by-side
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Buy column
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: leaseIsChEaper ? PdfColors.blueGrey50 : PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                      border: leaseIsChEaper
                          ? null
                          : pw.Border.all(color: PdfColors.blue800, width: 1.5),
                    ),
                    padding: const pw.EdgeInsets.all(AppSpacing.sm),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(tBuyDetails,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                                color: leaseIsChEaper
                                    ? PdfColors.grey700
                                    : PdfColors.blue800)),
                        pw.SizedBox(height: 6),
                        _summaryRow(tDownPayment, fmt0.format(buyDown)),
                        _summaryRow(tApr,
                            '${buyApr.toStringAsFixed(2)}%'),
                        _summaryRow(tTerm, '$buyTerm $tMo'),
                        _summaryRow(tResidual,
                            '${residualPercent.toStringAsFixed(0)}%'),
                        _summaryRow(tInsurance, fmt0.format(annualInsurance)),
                        pw.Divider(color: PdfColors.grey400),
                        _summaryRow(tMonthlyPayment, fmt.format(buyMonthly),
                            highlight: !leaseIsChEaper),
                        _summaryRow(tTotalInterest,
                            fmt.format(buyTotalInterest)),
                        _summaryRow(tInsuranceCost,
                            fmt.format(buyInsuranceCost)),
                        _summaryRow(tTotalBuyCost, fmt0.format(buyTotalCost),
                            highlight: !leaseIsChEaper),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Lease column
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: leaseIsChEaper ? PdfColors.blue50 : PdfColors.blueGrey50,
                      borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                      border: leaseIsChEaper
                          ? pw.Border.all(color: PdfColors.blue800, width: 1.5)
                          : null,
                    ),
                    padding: const pw.EdgeInsets.all(AppSpacing.sm),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(tLeaseDetails,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                                color: leaseIsChEaper
                                    ? PdfColors.blue800
                                    : PdfColors.grey700)),
                        pw.SizedBox(height: 6),
                        _summaryRow(tLeasePayment, fmt.format(leaseMonthly)),
                        _summaryRow(tTerm, '$leaseTerm $tMo'),
                        _summaryRow(tDownPayment, fmt0.format(leaseDown)),
                        _summaryRow(tAcqFee, fmt.format(acquisitionFee)),
                        _summaryRow(tDispFee, fmt.format(dispositionFee)),
                        pw.Divider(color: PdfColors.grey400),
                        _summaryRow(tTotalLeaseCost,
                            fmt0.format(leaseTotalCost),
                            highlight: leaseIsChEaper),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Results & recommendation
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tResults,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: AppTextSize.sm)),
                  pw.SizedBox(height: 8),
                  if (breakEvenMiles > 0)
                    _summaryRow(
                        '$tBreakEven / $tYr',
                        '${breakEvenMiles.toStringAsFixed(0)} $distLabel'),
                  pw.Divider(color: PdfColors.grey400),
                  _summaryRow(tSavings, fmt0.format(saving),
                      highlight: true),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Winner callout
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.sm),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tRecommendation,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800)),
                  pw.SizedBox(height: 2),
                  pw.Text(tWinner,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800)),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Text(tFooter,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
  }

  /// Export Cash-Back vs Low-APR analysis to PDF and share.
  static Future<void> exportCashbackVsLowApr({
    required String title,
    required String currency,
    required double vehiclePrice,
    required double downPayment,
    required int termMonths,
    required double cashBack,
    required double rateA,
    required double rateB,
    required double monthlyA,
    required double totalInterestA,
    required double totalCostA,
    required double monthlyB,
    required double totalInterestB,
    required double totalCostB,
    required bool aWins,
    required double savings,
    bool isFrench = false,
    bool isSpanish = false,
  }) async {
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final fmt0 = NumberFormat.currency(symbol: currency, decimalDigits: 0);

    final tInputs = isFrench ? 'Paramètres' : (isSpanish ? 'Parámetros' : 'Parameters');
    final tResults = isFrench ? 'Résultats' : (isSpanish ? 'Resultados' : 'Results');
    final tVehiclePrice = isFrench ? 'Prix du véhicule' : (isSpanish ? 'Precio del vehículo' : 'Vehicle Price');
    final tDownPayment = isFrench ? 'Mise de fonds' : (isSpanish ? 'Pago inicial' : 'Down Payment');
    final tTerm = isFrench ? 'Durée' : (isSpanish ? 'Plazo' : 'Term');
    final tScenarioA = isFrench ? 'Scénario A — Remise' : (isSpanish ? 'Escenario A — Reembolso' : 'Scenario A — Cash-Back');
    final tScenarioB = isFrench ? 'Scénario B — Taux bas' : (isSpanish ? 'Escenario B — Tasa Baja' : 'Scenario B — Low APR');
    final tCashBack = isFrench ? 'Remise en espèces' : (isSpanish ? 'Reembolso en efectivo' : 'Cash-Back Amount');
    final tStdRate = isFrench ? 'Taux standard' : (isSpanish ? 'Tasa estándar' : 'Standard Rate');
    final tPromoRate = isFrench ? 'Taux promotionnel' : (isSpanish ? 'Tasa promocional' : 'Promotional APR');
    final tMonthly = isFrench ? 'Paiement mensuel' : (isSpanish ? 'Cuota mensual' : 'Monthly Payment');
    final tTotalInterest = isFrench ? 'Intérêt total' : (isSpanish ? 'Interés total' : 'Total Interest');
    final tTotalCost = isFrench ? 'Coût total' : (isSpanish ? 'Costo total' : 'Total Cost');
    final tWinner = isFrench ? 'Gagnant' : (isSpanish ? 'Ganador' : 'Winner');
    final tSavings = isFrench ? 'Économies' : (isSpanish ? 'Ahorros' : 'Savings');
    final tWinnerLabel = aWins
        ? (isFrench ? 'Scénario A — Remise' : (isSpanish ? 'Escenario A — Reembolso' : 'Scenario A — Cash-Back'))
        : (isFrench ? 'Scénario B — Taux bas' : (isSpanish ? 'Escenario B — Tasa Baja' : 'Scenario B — Low APR'));
    final tFooter = isFrench
        ? 'À titre informatif seulement. Ne constitue pas un conseil financier.'
        : (isSpanish
            ? 'Solo con fines informativos. No es asesoramiento financiero.'
            : 'For informational purposes only. Not financial advice.');
    final tMo = isFrench ? 'mois' : (isSpanish ? 'mes' : 'mo');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 12),

            // Shared inputs
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tInputs,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: AppTextSize.sm)),
                  pw.SizedBox(height: 8),
                  _summaryRow(tVehiclePrice, fmt0.format(vehiclePrice)),
                  _summaryRow(tDownPayment, fmt0.format(downPayment)),
                  _summaryRow(tTerm, '$termMonths $tMo'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Scenario comparison table
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tResults,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: AppTextSize.sm)),
                  pw.SizedBox(height: 8),
                  // Header row
                  pw.Row(children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        child: pw.Text(tScenarioA,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: aWins
                                    ? PdfColors.blue800
                                    : PdfColors.black))),
                    pw.Expanded(
                        child: pw.Text(tScenarioB,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: !aWins
                                    ? PdfColors.blue800
                                    : PdfColors.black))),
                  ]),
                  pw.SizedBox(height: 4),
                  _compTableRow(
                    isFrench ? 'Remise / Taux promo' : (isSpanish ? 'Reembolso / Tasa promo' : 'Cash-Back / Promo Rate'),
                    [fmt0.format(cashBack), '${rateB.toStringAsFixed(2)}%'],
                  ),
                  _compTableRow(
                    isFrench ? 'Taux standard / Taux' : (isSpanish ? 'Tasa estándar / Tasa' : 'Std Rate / Rate'),
                    ['${rateA.toStringAsFixed(2)}%', '${rateB.toStringAsFixed(2)}%'],
                  ),
                  _compTableRow(tMonthly, [fmt.format(monthlyA), fmt.format(monthlyB)],
                      winnerIndex: aWins ? 0 : 1),
                  _compTableRow(tTotalInterest,
                      [fmt.format(totalInterestA), fmt.format(totalInterestB)],
                      winnerIndex: aWins ? 0 : 1),
                  pw.Divider(color: PdfColors.grey400),
                  _compTableRow(tTotalCost,
                      [fmt0.format(totalCostA), fmt0.format(totalCostB)],
                      winnerIndex: aWins ? 0 : 1,
                      bold: true),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Winner callout
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.sm),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tWinner,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                      '$tWinnerLabel — $tSavings: ${fmt0.format(savings)}',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800)),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Text(tFooter,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
  }

  /// Export Loan Comparison (2 scenarios) to PDF and share.
  static Future<void> exportLoanCompare({
    required String title,
    required String currency,
    required double vehiclePrice,
    required double downPayment,
    required double rateA,
    required int termA,
    required double rateB,
    required int termB,
    required double monthlyA,
    required double totalInterestA,
    required double totalCostA,
    required double monthlyB,
    required double totalInterestB,
    required double totalCostB,
    required bool aBetter,
    required double savings,
    bool isBiWeekly = false,
    bool isFrench = false,
    bool isSpanish = false,
  }) async {
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final fmt0 = NumberFormat.currency(symbol: currency, decimalDigits: 0);

    final tSummary = isFrench ? 'Résumé' : (isSpanish ? 'Resumen' : 'Summary');
    final tInputs = isFrench ? 'Paramètres' : (isSpanish ? 'Parámetros' : 'Parameters');
    final tVehiclePrice = isFrench ? 'Prix du véhicule' : (isSpanish ? 'Precio del vehículo' : 'Vehicle Price');
    final tDownPayment = isFrench ? 'Mise de fonds' : (isSpanish ? 'Pago inicial' : 'Down Payment');
    final tLoanAmount = isFrench ? 'Montant du prêt' : (isSpanish ? 'Monto del préstamo' : 'Loan Amount');
    final tScenarioA = isFrench ? 'Scénario A' : (isSpanish ? 'Escenario A' : 'Scenario A');
    final tScenarioB = isFrench ? 'Scénario B' : (isSpanish ? 'Escenario B' : 'Scenario B');
    final tRate = isFrench ? 'Taux' : (isSpanish ? 'Tasa' : 'Rate');
    final tTerm = isFrench ? 'Durée' : (isSpanish ? 'Plazo' : 'Term');
    final tMonthly = isBiWeekly
        ? (isFrench ? 'Paiement bi-hebdo' : (isSpanish ? 'Pago quincenal' : 'Bi-Weekly Payment'))
        : (isFrench ? 'Paiement mensuel' : (isSpanish ? 'Cuota mensual' : 'Monthly Payment'));
    final tTotalInterest = isFrench ? 'Intérêt total' : (isSpanish ? 'Interés total' : 'Total Interest');
    final tTotalCost = isFrench ? 'Coût total' : (isSpanish ? 'Costo total' : 'Total Cost');
    final tBestDeal = isFrench ? 'Meilleure offre' : (isSpanish ? 'Mejor oferta' : 'Best Deal');
    final tSavings = isFrench ? 'Économies' : (isSpanish ? 'Ahorros' : 'Savings');
    final tFooter = isFrench
        ? 'À titre informatif seulement. Les taux et frais varient selon le prêteur.'
        : (isSpanish
            ? 'Solo con fines informativos. Las tasas y cargos varían según el prestamista.'
            : 'For informational purposes only. Rates and fees vary by lender.');
    final tMo = isFrench ? 'mois' : (isSpanish ? 'mes' : 'mo');

    final loanAmount = (vehiclePrice - downPayment).clamp(0.0, double.infinity);
    final winnerLabel = aBetter ? tScenarioA : tScenarioB;
    final winnerCost = aBetter ? totalCostA : totalCostB;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 12),

            // Inputs
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tInputs,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: AppTextSize.sm)),
                  pw.SizedBox(height: 8),
                  _summaryRow(tVehiclePrice, fmt0.format(vehiclePrice)),
                  _summaryRow(tDownPayment, fmt0.format(downPayment)),
                  _summaryRow(tLoanAmount, fmt0.format(loanAmount)),
                  pw.SizedBox(height: 4),
                  // Scenario params side-by-side
                  pw.Row(children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('',
                            style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(
                        child: pw.Text(tScenarioA,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: aBetter
                                    ? PdfColors.blue800
                                    : PdfColors.black))),
                    pw.Expanded(
                        child: pw.Text(tScenarioB,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: !aBetter
                                    ? PdfColors.blue800
                                    : PdfColors.black))),
                  ]),
                  pw.SizedBox(height: 4),
                  _compTableRow(tRate,
                      ['${rateA.toStringAsFixed(2)}%', '${rateB.toStringAsFixed(2)}%']),
                  _compTableRow(tTerm, ['$termA $tMo', '$termB $tMo']),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Results
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.md),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tSummary,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: AppTextSize.sm)),
                  pw.SizedBox(height: 8),
                  pw.Row(children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('',
                            style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(
                        child: pw.Text(tScenarioA,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: aBetter
                                    ? PdfColors.blue800
                                    : PdfColors.black))),
                    pw.Expanded(
                        child: pw.Text(tScenarioB,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: !aBetter
                                    ? PdfColors.blue800
                                    : PdfColors.black))),
                  ]),
                  pw.SizedBox(height: 4),
                  _compTableRow(tMonthly,
                      [fmt.format(monthlyA), fmt.format(monthlyB)],
                      winnerIndex: aBetter ? 0 : 1),
                  _compTableRow(tTotalInterest,
                      [fmt.format(totalInterestA), fmt.format(totalInterestB)],
                      winnerIndex: aBetter ? 0 : 1),
                  pw.Divider(color: PdfColors.grey400),
                  _compTableRow(tTotalCost,
                      [fmt0.format(totalCostA), fmt0.format(totalCostB)],
                      winnerIndex: aBetter ? 0 : 1,
                      bold: true),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Winner callout
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
              ),
              padding: const pw.EdgeInsets.all(AppSpacing.sm),
              child: pw.Text(
                '$tBestDeal: $winnerLabel — ${fmt0.format(winnerCost)} ($tSavings: ${fmt0.format(savings)})',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800),
              ),
            ),

            pw.Spacer(),
            pw.Text(tFooter,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
  }

  static pw.Widget _compTableRow(
    String label,
    List<String> values, {
    int? winnerIndex,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey800),
            ),
          ),
          for (int i = 0; i < values.length; i++)
            pw.Expanded(
              child: pw.Text(
                values[i],
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: (bold || i == winnerIndex)
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: i == winnerIndex
                      ? PdfColors.blue800
                      : PdfColors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? PdfColors.blue800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool header = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: header ? 9 : 8,
          fontWeight: (header || bold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
