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
