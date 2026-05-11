import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'ad_service.dart';
import '../core/freemium/iap_service.dart';
import '../core/theme/app_theme.dart';

const _navy  = PdfColor(0.059, 0.322, 0.600); // #0F52B0 AutoLoan blue
const _teal  = PdfColor(0.086, 0.533, 0.533); // accent
const _light = PdfColor(0.933, 0.957, 0.996);

class PdfExportService {
  static final _cur2 = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
  static final _cur0 = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
  static final _date = DateFormat('MMMM d, yyyy');

  // ── Public entry point ────────────────────────────────────────────────────

  static Future<void> exportLoan({
    required BuildContext context,
    required double vehiclePrice,
    required double downPayment,
    required double tradeIn,
    required double loanAmount,
    required double annualRate,
    required int    termMonths,
    required double monthlyPayment,
    required double totalInterest,
    required double totalCost,
    required List<Map<String, dynamic>> schedule, // {month, payment, principal, interest, balance}
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 28),
      build: (_) => _buildSummaryPage(
        vehiclePrice: vehiclePrice,
        downPayment: downPayment,
        tradeIn: tradeIn,
        loanAmount: loanAmount,
        annualRate: annualRate,
        termMonths: termMonths,
        monthlyPayment: monthlyPayment,
        totalInterest: totalInterest,
        totalCost: totalCost,
      ),
    ));

    if (schedule.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
        header: (_) => _amortHeader(loanAmount, annualRate, termMonths),
        footer: (ctx) => _footer(ctx),
        build: (_) => [..._buildScheduleTable(schedule)],
      ));
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'AutoLoan_${loanAmount.round()}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ── Summary page ─────────────────────────────────────────────────────────

  static pw.Widget _buildSummaryPage({
    required double vehiclePrice,
    required double downPayment,
    required double tradeIn,
    required double loanAmount,
    required double annualRate,
    required int    termMonths,
    required double monthlyPayment,
    required double totalInterest,
    required double totalCost,
  }) {
    final now = DateTime.now();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Auto Loan Calculator',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy)),
              pw.Text('Vehicle Financing Report',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            ]),
            pw.Text(_date.format(now),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        pw.Container(height: 2, color: _navy, margin: const pw.EdgeInsets.only(top: 6, bottom: 14)),

        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(children: [
            _sectionBox('VEHICLE & LOAN DETAILS', [
              _row2('Vehicle Price',      _cur0.format(vehiclePrice)),
              _row2('Down Payment',       _cur0.format(downPayment)),
              if (tradeIn > 0)
                _row2('Trade-In Value',   _cur0.format(tradeIn)),
              _row2('Loan Amount',        _cur0.format(loanAmount)),
              _row2('Interest Rate (APR)','${annualRate.toStringAsFixed(2)}%'),
              _row2('Loan Term',          '$termMonths months (${(termMonths / 12).toStringAsFixed(1)} yr)'),
            ]),
          ])),
          pw.SizedBox(width: 14),
          pw.Expanded(child: pw.Column(children: [
            _sectionBox('PAYMENT SUMMARY', [
              _row2('Monthly Payment',    _cur2.format(monthlyPayment), bold: true, color: _navy),
              _row2('Total Interest',     _cur0.format(totalInterest)),
              _row2('Total Cost',         _cur0.format(totalCost), bold: true),
            ]),
            pw.SizedBox(height: 10),
            _costBar(loanAmount, totalInterest),
          ])),
        ]),

        pw.Spacer(),
        _footerNote(),
      ],
    );
  }

  static pw.Widget _costBar(double principal, double interest) {
    final total = principal + interest;
    final pPct  = total > 0 ? principal / total : 0.5;
    final iPct  = total > 0 ? interest  / total : 0.5;
    return _sectionBox('PRINCIPAL vs INTEREST', [
      pw.SizedBox(height: 6),
      pw.Row(children: [
        pw.Expanded(
          flex: (pPct * 100).round().clamp(1, 99),
          child: pw.Container(height: 14, color: _navy,
            child: pw.Center(child: pw.Text(
              '${(pPct * 100).toStringAsFixed(0)}%',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ))),
        ),
        pw.Expanded(
          flex: (iPct * 100).round().clamp(1, 99),
          child: pw.Container(height: 14, color: _teal,
            child: pw.Center(child: pw.Text(
              '${(iPct * 100).toStringAsFixed(0)}%',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ))),
        ),
      ]),
    ]);
  }

  static List<pw.Widget> _buildScheduleTable(List<Map<String, dynamic>> schedule) {
    final rows = schedule.map((e) => [
      e['month'].toString(),
      _cur0.format(e['payment']),
      _cur0.format(e['principal']),
      _cur0.format(e['interest']),
      _cur0.format(e['balance']),
    ]).toList();

    return [
      _tableTitle('FULL AMORTIZATION SCHEDULE'),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        headers: ['Month', 'Payment', 'Principal', 'Interest', 'Balance'],
        data: rows,
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _navy),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellHeight: 13,
        rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
        oddRowDecoration: pw.BoxDecoration(color: _light),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
      ),
    ];
  }

  static pw.Widget _amortHeader(double loanAmount, double rate, int months) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 0.5))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Auto Loan — Amortization Schedule',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.Text('${_cur0.format(loanAmount)} · ${rate.toStringAsFixed(2)}% APR · ${months}mo',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ]),
      );

  static pw.Widget _footer(pw.Context ctx) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 4),
    decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('For illustration purposes only. Not financial advice.',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
      pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
    ]),
  );

  static pw.Widget _footerNote() => pw.Column(children: [
    pw.Divider(color: PdfColors.grey300, height: 12),
    pw.Text('Generated by Auto Loan Calculator · For illustration purposes only. Not financial advice.',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
  ]);

  static pw.Widget _tableTitle(String text) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    color: _navy,
    child: pw.Text(text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
  );

  static pw.Widget _sectionBox(String title, List<pw.Widget> rows) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: _navy,
        child: pw.Text(title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
        child: pw.Column(children: rows),
      ),
    ],
  );

  static pw.Widget _row2(String label, String value, {bool bold = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black)),
        ]),
      );

  // ── Unlock sheet ──────────────────────────────────────────────────────────

  static Future<void> showUnlockOrPay(
    BuildContext context,
    Future<void> Function() onExport,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PdfUnlockSheet(onExport: onExport),
    );
  }
}

class _PdfUnlockSheet extends StatefulWidget {
  final Future<void> Function() onExport;
  const _PdfUnlockSheet({required this.onExport});

  @override
  State<_PdfUnlockSheet> createState() => _PdfUnlockSheetState();
}

class _PdfUnlockSheetState extends State<_PdfUnlockSheet> {
  bool _loading = false;

  Future<void> _watchAd() async {
    setState(() => _loading = true);
    final earned = await context.read<AdService>().showRewarded();
    if (!mounted) return;
    setState(() => _loading = false);
    if (earned) {
      Navigator.pop(context);
      await widget.onExport();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not available. Try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adReady = context.read<AdService>().isRewardedReady;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.picture_as_pdf_outlined, size: 36, color: AppTheme.primary),
          const SizedBox(height: 12),
          const Text('Export PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Choose how to unlock PDF export',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          const SizedBox(height: 24),
          Opacity(
            opacity: adReady ? 1.0 : 0.45,
            child: InkWell(
              onTap: (adReady && !_loading) ? _watchAd : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_circle_outline, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Watch a short video',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Export once — free',
                          style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                    ],
                  )),
                  if (_loading)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); IAPService.instance.buy(); },
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Premium — \$3.99 (unlimited)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }
}
