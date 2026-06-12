import 'dart:isolate';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../amortization/amortization_screen.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;

// ─────────────────────────────────────────────────────────────────────────────
// Params classes — only sendable types (primitives + TypedData)
// ─────────────────────────────────────────────────────────────────────────────

class _LoanPdfParams {
  final String title;
  final String currencySymbol;
  final double loanAmount;
  final double annualRate;
  final int termMonths;
  final double downPayment;
  final double balloonAmount;
  final double insuranceMonthly;
  // summary as two parallel lists (MapEntry is not sendable)
  final List<String> summaryKeys;
  final List<String> summaryValues;
  final bool isFrench;
  final bool isSpanish;

  const _LoanPdfParams({
    required this.title,
    required this.currencySymbol,
    required this.loanAmount,
    required this.annualRate,
    required this.termMonths,
    required this.downPayment,
    required this.balloonAmount,
    required this.insuranceMonthly,
    required this.summaryKeys,
    required this.summaryValues,
    required this.isFrench,
    required this.isSpanish,
  });
}

class _LoanComparisonPdfParams {
  final String title;
  final String currency;
  final List<double> amounts;
  final List<double> rates;
  final List<int> terms;
  final List<double> monthlyPayments;
  final List<double> totalInterests;
  final List<double> totalCosts;
  final int winnerIndex;
  final bool isFrench;
  final bool isSpanish;

  const _LoanComparisonPdfParams({
    required this.title,
    required this.currency,
    required this.amounts,
    required this.rates,
    required this.terms,
    required this.monthlyPayments,
    required this.totalInterests,
    required this.totalCosts,
    required this.winnerIndex,
    required this.isFrench,
    required this.isSpanish,
  });
}

class _TotalCostPdfParams {
  final String title;
  final String currency;
  final double vehiclePrice;
  final double monthlyPayment;
  final int ownershipYears;
  final double insurance;
  final double fuel;
  final double maintenance;
  final double depreciationRate;
  final double totalLoan;
  final double totalInsurance;
  final double totalFuel;
  final double totalMaintenance;
  final double depreciationLoss;
  final double grandTotal;
  final double costPerMonth;
  final String fuelLabel;
  final String distUnit;
  final bool isFrench;
  final bool isSpanish;

  const _TotalCostPdfParams({
    required this.title,
    required this.currency,
    required this.vehiclePrice,
    required this.monthlyPayment,
    required this.ownershipYears,
    required this.insurance,
    required this.fuel,
    required this.maintenance,
    required this.depreciationRate,
    required this.totalLoan,
    required this.totalInsurance,
    required this.totalFuel,
    required this.totalMaintenance,
    required this.depreciationLoss,
    required this.grandTotal,
    required this.costPerMonth,
    required this.fuelLabel,
    required this.distUnit,
    required this.isFrench,
    required this.isSpanish,
  });
}

class _LeaseVsBuyPdfParams {
  final String title;
  final String currency;
  final double vehiclePrice;
  final double buyDown;
  final double buyApr;
  final int buyTerm;
  final double residualPercent;
  final double annualInsurance;
  final double leaseMonthly;
  final int leaseTerm;
  final double leaseDown;
  final double acquisitionFee;
  final double dispositionFee;
  final double buyMonthly;
  final double buyTotalCost;
  final double buyTotalInterest;
  final double buyInsuranceCost;
  final double leaseTotalCost;
  final double breakEvenMiles;
  final bool leaseIsChEaper;
  final double saving;
  final String distLabel;
  final bool isFrench;
  final bool isSpanish;

  const _LeaseVsBuyPdfParams({
    required this.title,
    required this.currency,
    required this.vehiclePrice,
    required this.buyDown,
    required this.buyApr,
    required this.buyTerm,
    required this.residualPercent,
    required this.annualInsurance,
    required this.leaseMonthly,
    required this.leaseTerm,
    required this.leaseDown,
    required this.acquisitionFee,
    required this.dispositionFee,
    required this.buyMonthly,
    required this.buyTotalCost,
    required this.buyTotalInterest,
    required this.buyInsuranceCost,
    required this.leaseTotalCost,
    required this.breakEvenMiles,
    required this.leaseIsChEaper,
    required this.saving,
    required this.distLabel,
    required this.isFrench,
    required this.isSpanish,
  });
}

class _CashbackVsLowAprPdfParams {
  final String title;
  final String currency;
  final double vehiclePrice;
  final double downPayment;
  final int termMonths;
  final double cashBack;
  final double rateA;
  final double rateB;
  final double monthlyA;
  final double totalInterestA;
  final double totalCostA;
  final double monthlyB;
  final double totalInterestB;
  final double totalCostB;
  final bool aWins;
  final double savings;
  final bool isFrench;
  final bool isSpanish;

  const _CashbackVsLowAprPdfParams({
    required this.title,
    required this.currency,
    required this.vehiclePrice,
    required this.downPayment,
    required this.termMonths,
    required this.cashBack,
    required this.rateA,
    required this.rateB,
    required this.monthlyA,
    required this.totalInterestA,
    required this.totalCostA,
    required this.monthlyB,
    required this.totalInterestB,
    required this.totalCostB,
    required this.aWins,
    required this.savings,
    required this.isFrench,
    required this.isSpanish,
  });
}

class _LoanComparePdfParams {
  final String title;
  final String currency;
  final double vehiclePrice;
  final double downPayment;
  final double rateA;
  final int termA;
  final double rateB;
  final int termB;
  final double monthlyA;
  final double totalInterestA;
  final double totalCostA;
  final double monthlyB;
  final double totalInterestB;
  final double totalCostB;
  final bool aBetter;
  final double savings;
  final bool isBiWeekly;
  final bool isFrench;
  final bool isSpanish;

  const _LoanComparePdfParams({
    required this.title,
    required this.currency,
    required this.vehiclePrice,
    required this.downPayment,
    required this.rateA,
    required this.termA,
    required this.rateB,
    required this.termB,
    required this.monthlyA,
    required this.totalInterestA,
    required this.totalCostA,
    required this.monthlyB,
    required this.totalInterestB,
    required this.totalCostB,
    required this.aBetter,
    required this.savings,
    required this.isBiWeekly,
    required this.isFrench,
    required this.isSpanish,
  });
}

class _HistoryPdfParams {
  final String country;
  final String? timestamp;
  final List<String> rowLabels;
  final List<String> rowValues;

  const _HistoryPdfParams({
    required this.country,
    required this.timestamp,
    required this.rowLabels,
    required this.rowValues,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level builders — run inside Isolate.run()
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildLoanPdf(_LoanPdfParams p) async {
  final rows = buildSchedule(
    loanAmount: p.loanAmount,
    annualRate: p.annualRate,
    termMonths: p.termMonths,
    balloonAmount: p.balloonAmount,
  );

  final fmt = NumberFormat.currency(symbol: p.currencySymbol, decimalDigits: 2);
  final fmtInt = NumberFormat.currency(symbol: p.currencySymbol, decimalDigits: 0);

  final totalInterest = rows.fold(0.0, (s, r) => s + r.interest);
  final totalPayments = rows.fold(0.0, (s, r) => s + r.payment);
  final totalCost = totalPayments + p.downPayment + p.insuranceMonthly * p.termMonths;

  final tSummary = p.isFrench ? 'Résumé' : (p.isSpanish ? 'Resumen' : 'Summary');
  final tTotalInterest = p.isFrench ? 'Intérêt total' : (p.isSpanish ? 'Interés total' : 'Total Interest');
  final tTotalCostLabel = p.isFrench ? 'Coût total' : (p.isSpanish ? 'Costo total' : 'Total Cost');
  final tAmortization = p.isFrench ? "Tableau d'amortissement" : (p.isSpanish ? 'Tabla de amortización' : 'Amortization Schedule');
  final tPayment = p.isFrench ? 'Paiement' : (p.isSpanish ? 'Pago' : 'Payment');
  final tPrincipal = p.isFrench ? 'Capital' : (p.isSpanish ? 'Capital' : 'Principal');
  final tInterest = p.isFrench ? 'Intérêt' : (p.isSpanish ? 'Interés' : 'Interest');
  final tBalance = p.isFrench ? 'Solde' : (p.isSpanish ? 'Saldo' : 'Balance');

  final summary = List.generate(p.summaryKeys.length, (i) => MapEntry(p.summaryKeys[i], p.summaryValues[i]));

  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
      header: (_) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            p.title,
            style: pw.TextStyle(fontSize: AppTextSize.body, fontWeight: pw.FontWeight.bold),
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
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.circular(AppRadius.xs),
          ),
          padding: const pw.EdgeInsets.all(AppSpacing.md),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(tSummary, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
              pw.SizedBox(height: 8),
              ...summary.map((e) => _summaryRow(e.key, e.value)),
              if (summary.isNotEmpty) pw.Divider(color: PdfColors.grey400),
              _summaryRow(tTotalInterest, fmt.format(totalInterest)),
              _summaryRow(tTotalCostLabel, fmtInt.format(totalCost), highlight: true),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(tAmortization, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
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
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: ['#', tPayment, tPrincipal, tInterest, tBalance]
                  .map((h) => _cell(h, header: true))
                  .toList(),
            ),
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final bg = i.isEven ? PdfColors.white : PdfColors.grey50;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _cell('${r.month}'),
                  _cell(fmt.format(r.payment + p.insuranceMonthly)),
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

  return await pdf.save();
}

Future<Uint8List> _buildLoanComparisonPdf(_LoanComparisonPdfParams p) async {
  final fmt = NumberFormat.currency(symbol: p.currency, decimalDigits: 2);

  final tSummary = p.isFrench ? 'Résumé' : (p.isSpanish ? 'Resumen' : 'Summary');
  final tInputs = p.isFrench ? 'Paramètres' : (p.isSpanish ? 'Parámetros' : 'Parameters');
  final tMonthly = p.isFrench ? 'Paiement mensuel' : (p.isSpanish ? 'Cuota mensual' : 'Monthly Payment');
  final tTotalInterest = p.isFrench ? 'Intérêt total' : (p.isSpanish ? 'Interés total' : 'Total Interest');
  final tTotalCostLabel = p.isFrench ? 'Coût total' : (p.isSpanish ? 'Costo total' : 'Total Cost');
  final tBestDeal = p.isFrench ? 'Meilleure offre' : (p.isSpanish ? 'Mejor oferta' : 'Best Deal');
  final tFooter = p.isFrench
      ? 'À titre informatif seulement. Les taux et frais varient selon le prêteur.'
      : (p.isSpanish
          ? 'Solo con fines informativos. Las tasas y cargos varían según el prestamista.'
          : 'For informational purposes only. Rates and fees vary by lender.');
  final tMo = p.isFrench ? 'mois' : (p.isSpanish ? 'mes' : 'mo');

  final loanLabels = <String>[];
  for (int i = 0; i < p.amounts.length; i++) {
    loanLabels.add(p.isFrench ? 'Prêt ${i + 1}' : (p.isSpanish ? 'Préstamo ${i + 1}' : 'Loan ${i + 1}'));
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p.title, style: pw.TextStyle(fontSize: AppTextSize.body, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tInputs, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  for (int i = 0; i < loanLabels.length; i++)
                    pw.Expanded(
                      child: pw.Text(loanLabels[i],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                ]),
                pw.SizedBox(height: 4),
                _compTableRow(
                  p.isFrench ? 'Montant' : (p.isSpanish ? 'Monto' : 'Amount'),
                  p.amounts.map((a) => fmt.format(a)).toList(),
                ),
                _compTableRow(
                  p.isFrench ? 'Taux' : (p.isSpanish ? 'Tasa' : 'Rate'),
                  p.rates.map((r) => '${r.toStringAsFixed(2)}%').toList(),
                ),
                _compTableRow(
                  p.isFrench ? 'Durée' : (p.isSpanish ? 'Plazo' : 'Term'),
                  p.terms.map((t) => '$t $tMo').toList(),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tSummary, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  for (int i = 0; i < loanLabels.length; i++)
                    pw.Expanded(
                      child: pw.Text(loanLabels[i],
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: i == p.winnerIndex ? PdfColors.blue800 : PdfColors.black)),
                    ),
                ]),
                pw.SizedBox(height: 4),
                _compTableRow(tMonthly, p.monthlyPayments.map((v) => fmt.format(v)).toList(),
                    winnerIndex: p.winnerIndex),
                _compTableRow(tTotalInterest, p.totalInterests.map((v) => fmt.format(v)).toList(),
                    winnerIndex: p.winnerIndex),
                pw.Divider(color: PdfColors.grey400),
                _compTableRow(tTotalCostLabel, p.totalCosts.map((v) => fmt.format(v)).toList(),
                    winnerIndex: p.winnerIndex, bold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.sm),
            child: pw.Text(
              '$tBestDeal: ${loanLabels[p.winnerIndex]} — ${fmt.format(p.totalCosts[p.winnerIndex])}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
          ),
          pw.Spacer(),
          pw.Text(tFooter, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  return await pdf.save();
}

Future<Uint8List> _buildTotalCostPdf(_TotalCostPdfParams p) async {
  final fmt = NumberFormat.currency(symbol: p.currency, decimalDigits: 0);
  final fmt2 = NumberFormat.currency(symbol: p.currency, decimalDigits: 2);

  final tInputs = p.isFrench ? 'Paramètres' : (p.isSpanish ? 'Parámetros' : 'Parameters');
  final tResults = p.isFrench ? 'Résultats' : (p.isSpanish ? 'Resultados' : 'Results');
  final tVehiclePrice = p.isFrench ? 'Prix du véhicule' : (p.isSpanish ? 'Precio del vehículo' : 'Vehicle Price');
  final tMonthlyPayment = p.isFrench ? 'Paiement mensuel' : (p.isSpanish ? 'Cuota mensual' : 'Monthly Payment');
  final tOwnershipPeriod = p.isFrench ? 'Période de possession' : (p.isSpanish ? 'Período de propiedad' : 'Ownership Period');
  final tInsurance = p.isFrench ? 'Assurance / mois' : (p.isSpanish ? 'Seguro / mes' : 'Insurance / mo');
  final tMaintenance = p.isFrench ? 'Entretien / mois' : (p.isSpanish ? 'Mantenimiento / mes' : 'Maintenance / mo');
  final tDepRate = p.isFrench ? 'Taux de dépréciation' : (p.isSpanish ? 'Tasa de depreciación' : 'Depreciation Rate');
  final tTotalLoan = p.isFrench ? 'Coût total du prêt' : (p.isSpanish ? 'Costo total del préstamo' : 'Total Loan Cost');
  final tTotalInsurance = p.isFrench ? 'Assurance totale' : (p.isSpanish ? 'Seguro total' : 'Total Insurance');
  final tTotalFuel = p.isFrench ? 'Carburant total' : (p.isSpanish ? 'Combustible total' : 'Total Fuel');
  final tTotalMaintenance = p.isFrench ? 'Entretien total' : (p.isSpanish ? 'Mantenimiento total' : 'Total Maintenance');
  final tDepLoss = p.isFrench ? 'Perte de valeur' : (p.isSpanish ? 'Pérdida por depreciación' : 'Depreciation Loss');
  final tGrandTotal = p.isFrench ? 'Coût total de possession' : (p.isSpanish ? 'Costo total de propiedad' : 'Total Cost of Ownership');
  final tMonthlyCost = p.isFrench ? 'Coût mensuel réel' : (p.isSpanish ? 'Costo mensual real' : 'Monthly True Cost');
  final tYr = p.isFrench ? 'ans' : (p.isSpanish ? 'años' : 'yr');
  final tMo = p.isFrench ? 'mois' : (p.isSpanish ? 'mes' : 'mo');
  final tFooter = p.isFrench
      ? 'À titre informatif seulement. La dépréciation varie selon la marque, le modèle et les ${p.distUnit} parcourus.'
      : (p.isSpanish
          ? 'Solo con fines informativos. La depreciación varía según la marca, modelo y ${p.distUnit} recorridos.'
          : 'For informational purposes only. Depreciation estimates vary by vehicle make, model, and ${p.distUnit} driven.');

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p.title, style: pw.TextStyle(fontSize: AppTextSize.body, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tInputs, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                _summaryRow(tVehiclePrice, fmt.format(p.vehiclePrice)),
                _summaryRow(tMonthlyPayment, fmt2.format(p.monthlyPayment)),
                _summaryRow(tOwnershipPeriod, '${p.ownershipYears} $tYr'),
                _summaryRow(tInsurance, fmt2.format(p.insurance)),
                _summaryRow(p.fuelLabel, fmt2.format(p.fuel)),
                _summaryRow(tMaintenance, fmt2.format(p.maintenance)),
                _summaryRow(tDepRate, '${p.depreciationRate.toStringAsFixed(0)}% / $tYr'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tResults, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                _summaryRow(tTotalLoan, fmt.format(p.totalLoan)),
                _summaryRow(tTotalInsurance, fmt.format(p.totalInsurance)),
                _summaryRow(tTotalFuel, fmt.format(p.totalFuel)),
                _summaryRow(tTotalMaintenance, fmt.format(p.totalMaintenance)),
                _summaryRow(tDepLoss, fmt.format(p.depreciationLoss)),
                pw.Divider(color: PdfColors.grey400),
                _summaryRow('$tGrandTotal (${p.ownershipYears} $tYr)', fmt.format(p.grandTotal), highlight: true),
                _summaryRow(tMonthlyCost, '${fmt.format(p.costPerMonth)}/$tMo', highlight: true),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Text(tFooter, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  return await pdf.save();
}

Future<Uint8List> _buildLeaseVsBuyPdf(_LeaseVsBuyPdfParams p) async {
  final fmt = NumberFormat.currency(symbol: p.currency, decimalDigits: 2);
  final fmt0 = NumberFormat.currency(symbol: p.currency, decimalDigits: 0);

  final tInputs = p.isFrench ? 'Paramètres' : (p.isSpanish ? 'Parámetros' : 'Parameters');
  final tResults = p.isFrench ? 'Résultats' : (p.isSpanish ? 'Resultados' : 'Results');
  final tVehiclePrice = p.isFrench ? 'Prix du véhicule (PDSF)' : (p.isSpanish ? 'Precio del vehículo' : 'Vehicle Price (MSRP)');
  final tBuyDetails = p.isFrench ? 'Achat — détails' : (p.isSpanish ? 'Compra — detalles' : 'Purchase — Details');
  final tLeaseDetails = p.isFrench ? 'Location — détails' : (p.isSpanish ? 'Arrendamiento — detalles' : 'Lease — Details');
  final tDownPayment = p.isFrench ? 'Mise de fonds' : (p.isSpanish ? 'Pago inicial' : 'Down Payment');
  final tApr = p.isFrench ? 'Taux annuel' : (p.isSpanish ? 'Tasa APR' : 'Annual Rate (APR)');
  final tTerm = p.isFrench ? 'Durée' : (p.isSpanish ? 'Plazo' : 'Term');
  final tResidual = p.isFrench ? 'Valeur résiduelle' : (p.isSpanish ? 'Valor residual' : 'Residual Value');
  final tInsurance = p.isFrench ? 'Assurance annuelle' : (p.isSpanish ? 'Seguro anual' : 'Annual Insurance');
  final tMonthlyPayment = p.isFrench ? 'Paiement mensuel' : (p.isSpanish ? 'Cuota mensual' : 'Monthly Payment');
  final tTotalInterest = p.isFrench ? 'Intérêt total' : (p.isSpanish ? 'Interés total' : 'Total Interest');
  final tInsuranceCost = p.isFrench ? 'Coût assurance' : (p.isSpanish ? 'Costo seguro' : 'Insurance Cost');
  final tTotalBuyCost = p.isFrench ? 'Coût total achat' : (p.isSpanish ? 'Costo total compra' : 'Total Purchase Cost');
  final tLeasePayment = p.isFrench ? 'Paiement mensuel location' : (p.isSpanish ? 'Cuota mensual arriendo' : 'Monthly Lease Payment');
  final tAcqFee = p.isFrench ? "Frais d'acquisition" : (p.isSpanish ? 'Cargo de adquisición' : 'Acquisition Fee');
  final tDispFee = p.isFrench ? 'Frais de disposition' : (p.isSpanish ? 'Cargo de disposición' : 'Disposition Fee');
  final tTotalLeaseCost = p.isFrench ? 'Coût total location' : (p.isSpanish ? 'Costo total arriendo' : 'Total Lease Cost');
  final tBreakEven = p.isFrench ? 'Kilométrage seuil de rentabilité' : (p.isSpanish ? 'Millaje de equilibrio' : 'Break-Even Mileage');
  final tRecommendation = p.isFrench ? 'Recommandation' : (p.isSpanish ? 'Recomendación' : 'Recommendation');
  final tSavings = p.isFrench ? 'Économies' : (p.isSpanish ? 'Ahorros' : 'Savings');
  final tWinner = p.leaseIsChEaper
      ? (p.isFrench ? 'LOUER est plus avantageux' : (p.isSpanish ? 'ARRENDAR es más ventajoso' : 'LEASING is the better deal'))
      : (p.isFrench ? 'ACHETER est plus avantageux' : (p.isSpanish ? 'COMPRAR es más ventajoso' : 'BUYING is the better deal'));
  final tFooter = p.isFrench
      ? "À titre informatif seulement. Les frais de dépassement de kilométrage peuvent s'appliquer."
      : (p.isSpanish
          ? 'Solo con fines informativos. Pueden aplicarse cargos por exceso de millaje.'
          : 'For informational purposes only. Mileage overage fees may apply.');
  final tMo = p.isFrench ? 'mois' : (p.isSpanish ? 'mes' : 'mo');
  final tYr = p.isFrench ? 'ans' : (p.isSpanish ? 'años' : 'yr');

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p.title,
                  style: pw.TextStyle(fontSize: AppTextSize.body, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tInputs, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                _summaryRow(tVehiclePrice, fmt0.format(p.vehiclePrice)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: p.leaseIsChEaper ? PdfColors.blueGrey50 : PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                    border: p.leaseIsChEaper
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
                              color: p.leaseIsChEaper ? PdfColors.grey700 : PdfColors.blue800)),
                      pw.SizedBox(height: 6),
                      _summaryRow(tDownPayment, fmt0.format(p.buyDown)),
                      _summaryRow(tApr, '${p.buyApr.toStringAsFixed(2)}%'),
                      _summaryRow(tTerm, '${p.buyTerm} $tMo'),
                      _summaryRow(tResidual, '${p.residualPercent.toStringAsFixed(0)}%'),
                      _summaryRow(tInsurance, fmt0.format(p.annualInsurance)),
                      pw.Divider(color: PdfColors.grey400),
                      _summaryRow(tMonthlyPayment, fmt.format(p.buyMonthly), highlight: !p.leaseIsChEaper),
                      _summaryRow(tTotalInterest, fmt.format(p.buyTotalInterest)),
                      _summaryRow(tInsuranceCost, fmt.format(p.buyInsuranceCost)),
                      _summaryRow(tTotalBuyCost, fmt0.format(p.buyTotalCost), highlight: !p.leaseIsChEaper),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: p.leaseIsChEaper ? PdfColors.blue50 : PdfColors.blueGrey50,
                    borderRadius: pw.BorderRadius.circular(AppRadius.xs),
                    border: p.leaseIsChEaper
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
                              color: p.leaseIsChEaper ? PdfColors.blue800 : PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                      _summaryRow(tLeasePayment, fmt.format(p.leaseMonthly)),
                      _summaryRow(tTerm, '${p.leaseTerm} $tMo'),
                      _summaryRow(tDownPayment, fmt0.format(p.leaseDown)),
                      _summaryRow(tAcqFee, fmt.format(p.acquisitionFee)),
                      _summaryRow(tDispFee, fmt.format(p.dispositionFee)),
                      pw.Divider(color: PdfColors.grey400),
                      _summaryRow(tTotalLeaseCost, fmt0.format(p.leaseTotalCost),
                          highlight: p.leaseIsChEaper),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tResults, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                if (p.breakEvenMiles > 0)
                  _summaryRow('$tBreakEven / $tYr', '${p.breakEvenMiles.toStringAsFixed(0)} ${p.distLabel}'),
                pw.Divider(color: PdfColors.grey400),
                _summaryRow(tSavings, fmt0.format(p.saving), highlight: true),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.sm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tRecommendation,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 2),
                pw.Text(tWinner,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Text(tFooter, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  return await pdf.save();
}

Future<Uint8List> _buildCashbackVsLowAprPdf(_CashbackVsLowAprPdfParams p) async {
  final fmt = NumberFormat.currency(symbol: p.currency, decimalDigits: 2);
  final fmt0 = NumberFormat.currency(symbol: p.currency, decimalDigits: 0);

  final tInputs = p.isFrench ? 'Paramètres' : (p.isSpanish ? 'Parámetros' : 'Parameters');
  final tResults = p.isFrench ? 'Résultats' : (p.isSpanish ? 'Resultados' : 'Results');
  final tVehiclePrice = p.isFrench ? 'Prix du véhicule' : (p.isSpanish ? 'Precio del vehículo' : 'Vehicle Price');
  final tDownPayment = p.isFrench ? 'Mise de fonds' : (p.isSpanish ? 'Pago inicial' : 'Down Payment');
  final tTerm = p.isFrench ? 'Durée' : (p.isSpanish ? 'Plazo' : 'Term');
  final tScenarioA = p.isFrench ? 'Scénario A — Remise' : (p.isSpanish ? 'Escenario A — Reembolso' : 'Scenario A — Cash-Back');
  final tScenarioB = p.isFrench ? 'Scénario B — Taux bas' : (p.isSpanish ? 'Escenario B — Tasa Baja' : 'Scenario B — Low APR');
  final tMonthly = p.isFrench ? 'Paiement mensuel' : (p.isSpanish ? 'Cuota mensual' : 'Monthly Payment');
  final tTotalInterest = p.isFrench ? 'Intérêt total' : (p.isSpanish ? 'Interés total' : 'Total Interest');
  final tTotalCost = p.isFrench ? 'Coût total' : (p.isSpanish ? 'Costo total' : 'Total Cost');
  final tWinner = p.isFrench ? 'Gagnant' : (p.isSpanish ? 'Ganador' : 'Winner');
  final tSavings = p.isFrench ? 'Économies' : (p.isSpanish ? 'Ahorros' : 'Savings');
  final tWinnerLabel = p.aWins
      ? (p.isFrench ? 'Scénario A — Remise' : (p.isSpanish ? 'Escenario A — Reembolso' : 'Scenario A — Cash-Back'))
      : (p.isFrench ? 'Scénario B — Taux bas' : (p.isSpanish ? 'Escenario B — Tasa Baja' : 'Scenario B — Low APR'));
  final tFooter = p.isFrench
      ? 'À titre informatif seulement. Ne constitue pas un conseil financier.'
      : (p.isSpanish
          ? 'Solo con fines informativos. No es asesoramiento financiero.'
          : 'For informational purposes only. Not financial advice.');
  final tMo = p.isFrench ? 'mois' : (p.isSpanish ? 'mes' : 'mo');

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p.title,
                  style: pw.TextStyle(fontSize: AppTextSize.body, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tInputs, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                _summaryRow(tVehiclePrice, fmt0.format(p.vehiclePrice)),
                _summaryRow(tDownPayment, fmt0.format(p.downPayment)),
                _summaryRow(tTerm, '${p.termMonths} $tMo'),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tResults, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      child: pw.Text(tScenarioA,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: p.aWins ? PdfColors.blue800 : PdfColors.black))),
                  pw.Expanded(
                      child: pw.Text(tScenarioB,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: !p.aWins ? PdfColors.blue800 : PdfColors.black))),
                ]),
                pw.SizedBox(height: 4),
                _compTableRow(
                  p.isFrench ? 'Remise / Taux promo' : (p.isSpanish ? 'Reembolso / Tasa promo' : 'Cash-Back / Promo Rate'),
                  [fmt0.format(p.cashBack), '${p.rateB.toStringAsFixed(2)}%'],
                ),
                _compTableRow(
                  p.isFrench ? 'Taux standard / Taux' : (p.isSpanish ? 'Tasa estándar / Tasa' : 'Std Rate / Rate'),
                  ['${p.rateA.toStringAsFixed(2)}%', '${p.rateB.toStringAsFixed(2)}%'],
                ),
                _compTableRow(tMonthly, [fmt.format(p.monthlyA), fmt.format(p.monthlyB)],
                    winnerIndex: p.aWins ? 0 : 1),
                _compTableRow(tTotalInterest,
                    [fmt.format(p.totalInterestA), fmt.format(p.totalInterestB)],
                    winnerIndex: p.aWins ? 0 : 1),
                pw.Divider(color: PdfColors.grey400),
                _compTableRow(tTotalCost, [fmt0.format(p.totalCostA), fmt0.format(p.totalCostB)],
                    winnerIndex: p.aWins ? 0 : 1, bold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.sm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tWinner,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 2),
                pw.Text('$tWinnerLabel — $tSavings: ${fmt0.format(p.savings)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Text(tFooter, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  return await pdf.save();
}

Future<Uint8List> _buildLoanComparePdf(_LoanComparePdfParams p) async {
  final fmt = NumberFormat.currency(symbol: p.currency, decimalDigits: 2);
  final fmt0 = NumberFormat.currency(symbol: p.currency, decimalDigits: 0);

  final tSummary = p.isFrench ? 'Résumé' : (p.isSpanish ? 'Resumen' : 'Summary');
  final tInputs = p.isFrench ? 'Paramètres' : (p.isSpanish ? 'Parámetros' : 'Parameters');
  final tVehiclePrice = p.isFrench ? 'Prix du véhicule' : (p.isSpanish ? 'Precio del vehículo' : 'Vehicle Price');
  final tDownPayment = p.isFrench ? 'Mise de fonds' : (p.isSpanish ? 'Pago inicial' : 'Down Payment');
  final tLoanAmount = p.isFrench ? 'Montant du prêt' : (p.isSpanish ? 'Monto del préstamo' : 'Loan Amount');
  final tScenarioA = p.isFrench ? 'Scénario A' : (p.isSpanish ? 'Escenario A' : 'Scenario A');
  final tScenarioB = p.isFrench ? 'Scénario B' : (p.isSpanish ? 'Escenario B' : 'Scenario B');
  final tRate = p.isFrench ? 'Taux' : (p.isSpanish ? 'Tasa' : 'Rate');
  final tTerm = p.isFrench ? 'Durée' : (p.isSpanish ? 'Plazo' : 'Term');
  final tMonthly = p.isBiWeekly
      ? (p.isFrench ? 'Paiement bi-hebdo' : (p.isSpanish ? 'Pago quincenal' : 'Bi-Weekly Payment'))
      : (p.isFrench ? 'Paiement mensuel' : (p.isSpanish ? 'Cuota mensual' : 'Monthly Payment'));
  final tTotalInterest = p.isFrench ? 'Intérêt total' : (p.isSpanish ? 'Interés total' : 'Total Interest');
  final tTotalCost = p.isFrench ? 'Coût total' : (p.isSpanish ? 'Costo total' : 'Total Cost');
  final tBestDeal = p.isFrench ? 'Meilleure offre' : (p.isSpanish ? 'Mejor oferta' : 'Best Deal');
  final tSavings = p.isFrench ? 'Économies' : (p.isSpanish ? 'Ahorros' : 'Savings');
  final tFooter = p.isFrench
      ? 'À titre informatif seulement. Les taux et frais varient selon le prêteur.'
      : (p.isSpanish
          ? 'Solo con fines informativos. Las tasas y cargos varían según el prestamista.'
          : 'For informational purposes only. Rates and fees vary by lender.');
  final tMo = p.isFrench ? 'mois' : (p.isSpanish ? 'mes' : 'mo');

  final loanAmount = (p.vehiclePrice - p.downPayment).clamp(0.0, double.infinity);
  final winnerLabel = p.aBetter ? tScenarioA : tScenarioB;
  final winnerCost = p.aBetter ? p.totalCostA : p.totalCostB;

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p.title,
                  style: pw.TextStyle(fontSize: AppTextSize.body, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tInputs, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                _summaryRow(tVehiclePrice, fmt0.format(p.vehiclePrice)),
                _summaryRow(tDownPayment, fmt0.format(p.downPayment)),
                _summaryRow(tLoanAmount, fmt0.format(loanAmount)),
                pw.SizedBox(height: 4),
                pw.Row(children: [
                  pw.Expanded(flex: 2, child: pw.Text('', style: const pw.TextStyle(fontSize: 9))),
                  pw.Expanded(
                      child: pw.Text(tScenarioA,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: p.aBetter ? PdfColors.blue800 : PdfColors.black))),
                  pw.Expanded(
                      child: pw.Text(tScenarioB,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: !p.aBetter ? PdfColors.blue800 : PdfColors.black))),
                ]),
                pw.SizedBox(height: 4),
                _compTableRow(tRate, ['${p.rateA.toStringAsFixed(2)}%', '${p.rateB.toStringAsFixed(2)}%']),
                _compTableRow(tTerm, ['${p.termA} $tMo', '${p.termB} $tMo']),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.md),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tSummary, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.sm)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(flex: 2, child: pw.Text('', style: const pw.TextStyle(fontSize: 9))),
                  pw.Expanded(
                      child: pw.Text(tScenarioA,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: p.aBetter ? PdfColors.blue800 : PdfColors.black))),
                  pw.Expanded(
                      child: pw.Text(tScenarioB,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: !p.aBetter ? PdfColors.blue800 : PdfColors.black))),
                ]),
                pw.SizedBox(height: 4),
                _compTableRow(tMonthly, [fmt.format(p.monthlyA), fmt.format(p.monthlyB)],
                    winnerIndex: p.aBetter ? 0 : 1),
                _compTableRow(tTotalInterest,
                    [fmt.format(p.totalInterestA), fmt.format(p.totalInterestB)],
                    winnerIndex: p.aBetter ? 0 : 1),
                pw.Divider(color: PdfColors.grey400),
                _compTableRow(tTotalCost, [fmt0.format(p.totalCostA), fmt0.format(p.totalCostB)],
                    winnerIndex: p.aBetter ? 0 : 1, bold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(AppRadius.xs),
              border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
            ),
            padding: const pw.EdgeInsets.all(AppSpacing.sm),
            child: pw.Text(
              '$tBestDeal: $winnerLabel — ${fmt0.format(winnerCost)} ($tSavings: ${fmt0.format(p.savings)})',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
          ),
          pw.Spacer(),
          pw.Text(tFooter, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  return await pdf.save();
}

Future<Uint8List> _buildHistoryPdf(_HistoryPdfParams p) async {
  final ts = DateTime.tryParse(p.timestamp ?? '');
  final dateFmt = DateFormat('MMM d, yyyy');

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Auto Loan ${p.country} — Loan Summary',
            style: pw.TextStyle(fontSize: AppTextSize.title, fontWeight: pw.FontWeight.bold),
          ),
          if (ts != null)
            pw.Text(
              dateFmt.format(ts),
              style: const pw.TextStyle(fontSize: AppTextSize.xs, color: PdfColors.grey600),
            ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
            },
            children: List.generate(p.rowLabels.length, (i) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(p.rowLabels[i],
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: AppTextSize.xs)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(p.rowValues[i],
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: AppTextSize.xs)),
                  ),
                ],
              );
            }),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Calculated with Auto Loan ${p.country}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    ),
  );

  return await pdf.save();
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared PDF widget helpers (top-level so they are accessible from isolate)
// ─────────────────────────────────────────────────────────────────────────────

pw.Widget _compTableRow(
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
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ),
        for (int i = 0; i < values.length; i++)
          pw.Expanded(
            child: pw.Text(
              values[i],
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: (bold || i == winnerIndex) ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: i == winnerIndex ? PdfColors.blue800 : PdfColors.black,
              ),
            ),
          ),
      ],
    ),
  );
}

pw.Widget _summaryRow(String label, String value, {bool highlight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
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

pw.Widget _cell(String text, {bool header = false, bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.right,
      style: pw.TextStyle(
        fontSize: header ? 9 : 8,
        fontWeight: (header || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper — write bytes to temp file and share
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _saveAndShare(Uint8List pdfBytes, String title) async {
  final tmpDir = await getTemporaryDirectory();
  final pdfFile = File(
      '${tmpDir.path}/${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  await pdfFile.writeAsBytes(pdfBytes);
  await Share.shareXFiles([XFile(pdfFile.path, mimeType: 'application/pdf')]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Public service — thin wrappers that delegate to Isolate.run()
// ─────────────────────────────────────────────────────────────────────────────

class PdfExportService {
  /// Build and share a PDF with a summary section + full amortization table.
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
    final params = _LoanPdfParams(
      title: title,
      currencySymbol: currencySymbol,
      loanAmount: loanAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      downPayment: downPayment,
      balloonAmount: balloonAmount,
      insuranceMonthly: insuranceMonthly,
      summaryKeys: summary.map((e) => e.key).toList(),
      summaryValues: summary.map((e) => e.value).toList(),
      isFrench: isFrench,
      isSpanish: isSpanish,
    );
    final pdfBytes = await Isolate.run(() => _buildLoanPdf(params));
    await _saveAndShare(pdfBytes, title);
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
    final params = _LoanComparisonPdfParams(
      title: title,
      currency: currency,
      amounts: amounts,
      rates: rates,
      terms: terms,
      monthlyPayments: monthlyPayments,
      totalInterests: totalInterests,
      totalCosts: totalCosts,
      winnerIndex: winnerIndex,
      isFrench: isFrench,
      isSpanish: isSpanish,
    );
    final pdfBytes = await Isolate.run(() => _buildLoanComparisonPdf(params));
    await _saveAndShare(pdfBytes, title);
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
    final params = _TotalCostPdfParams(
      title: title,
      currency: currency,
      vehiclePrice: vehiclePrice,
      monthlyPayment: monthlyPayment,
      ownershipYears: ownershipYears,
      insurance: insurance,
      fuel: fuel,
      maintenance: maintenance,
      depreciationRate: depreciationRate,
      totalLoan: totalLoan,
      totalInsurance: totalInsurance,
      totalFuel: totalFuel,
      totalMaintenance: totalMaintenance,
      depreciationLoss: depreciationLoss,
      grandTotal: grandTotal,
      costPerMonth: costPerMonth,
      fuelLabel: fuelLabel,
      distUnit: distUnit,
      isFrench: isFrench,
      isSpanish: isSpanish,
    );
    final pdfBytes = await Isolate.run(() => _buildTotalCostPdf(params));
    await _saveAndShare(pdfBytes, title);
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
    final params = _LeaseVsBuyPdfParams(
      title: title,
      currency: currency,
      vehiclePrice: vehiclePrice,
      buyDown: buyDown,
      buyApr: buyApr,
      buyTerm: buyTerm,
      residualPercent: residualPercent,
      annualInsurance: annualInsurance,
      leaseMonthly: leaseMonthly,
      leaseTerm: leaseTerm,
      leaseDown: leaseDown,
      acquisitionFee: acquisitionFee,
      dispositionFee: dispositionFee,
      buyMonthly: buyMonthly,
      buyTotalCost: buyTotalCost,
      buyTotalInterest: buyTotalInterest,
      buyInsuranceCost: buyInsuranceCost,
      leaseTotalCost: leaseTotalCost,
      breakEvenMiles: breakEvenMiles,
      leaseIsChEaper: leaseIsChEaper,
      saving: saving,
      distLabel: distLabel,
      isFrench: isFrench,
      isSpanish: isSpanish,
    );
    final pdfBytes = await Isolate.run(() => _buildLeaseVsBuyPdf(params));
    await _saveAndShare(pdfBytes, title);
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
    final params = _CashbackVsLowAprPdfParams(
      title: title,
      currency: currency,
      vehiclePrice: vehiclePrice,
      downPayment: downPayment,
      termMonths: termMonths,
      cashBack: cashBack,
      rateA: rateA,
      rateB: rateB,
      monthlyA: monthlyA,
      totalInterestA: totalInterestA,
      totalCostA: totalCostA,
      monthlyB: monthlyB,
      totalInterestB: totalInterestB,
      totalCostB: totalCostB,
      aWins: aWins,
      savings: savings,
      isFrench: isFrench,
      isSpanish: isSpanish,
    );
    final pdfBytes = await Isolate.run(() => _buildCashbackVsLowAprPdf(params));
    await _saveAndShare(pdfBytes, title);
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
    final params = _LoanComparePdfParams(
      title: title,
      currency: currency,
      vehiclePrice: vehiclePrice,
      downPayment: downPayment,
      rateA: rateA,
      termA: termA,
      rateB: rateB,
      termB: termB,
      monthlyA: monthlyA,
      totalInterestA: totalInterestA,
      totalCostA: totalCostA,
      monthlyB: monthlyB,
      totalInterestB: totalInterestB,
      totalCostB: totalCostB,
      aBetter: aBetter,
      savings: savings,
      isBiWeekly: isBiWeekly,
      isFrench: isFrench,
      isSpanish: isSpanish,
    );
    final pdfBytes = await Isolate.run(() => _buildLoanComparePdf(params));
    await _saveAndShare(pdfBytes, title);
  }
}
