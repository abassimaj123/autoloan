import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../amortization/amortization_screen.dart';

class PdfExportService {
  /// Build and share a PDF with a summary section + full amortization table.
  ///
  /// [summary] is an ordered list of label/value pairs shown before the table
  /// (e.g. Monthly Payment, Loan Amount, Total Interest, Total Cost…).
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
  }) async {
    final rows = buildSchedule(
      loanAmount: loanAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      balloonAmount: balloonAmount,
    );

    final fmt    = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    final fmtInt = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);

    final totalInterest = rows.fold(0.0, (s, r) => s + r.interest);
    final totalPayments = rows.fold(0.0, (s, r) => s + r.payment);
    final totalCost     = totalPayments + downPayment + insuranceMonthly * termMonths;

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(DateFormat.yMMMMd().format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
      build: (context) => [
        pw.SizedBox(height: 8),

        // ── Summary ──────────────────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Summary',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              ...summary.map((e) => _summaryRow(e.key, e.value)),
              if (summary.isNotEmpty) pw.Divider(color: PdfColors.grey400),
              _summaryRow('Total Interest', fmt.format(totalInterest)),
              _summaryRow(
                'Total Cost',
                fmtInt.format(totalCost),
                highlight: true,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // ── Amortization table ────────────────────────────────────────────
        pw.Text('Amortization Schedule',
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
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
              decoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: ['#', 'Payment', 'Principal', 'Interest', 'Balance']
                  .map((h) => _cell(h, header: true))
                  .toList(),
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
                  _cell(fmt.format(r.balance),
                      bold: r.balance < 0.01),
                ],
              );
            }),
          ],
        ),
      ],
    ));

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _summaryRow(String label, String value,
      {bool highlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
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

  static pw.Widget _cell(String text, {bool header = false, bool bold = false}) {
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
}
