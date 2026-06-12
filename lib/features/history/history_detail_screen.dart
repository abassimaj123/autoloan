import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/freemium/freemium_service.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile, PaywallHard;
import '../../widgets/paywall_hard.dart';

// ─── PDF isolate helpers (top-level — required by Isolate.run) ───────────────

class _HistoryDetailPdfParams {
  final String country;
  final String? timestamp;
  final List<String> rowLabels;
  final List<String> rowValues;

  const _HistoryDetailPdfParams({
    required this.country,
    required this.timestamp,
    required this.rowLabels,
    required this.rowValues,
  });
}

Future<Uint8List> _buildHistoryDetailPdf(_HistoryDetailPdfParams p) async {
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
          pw.Text(
            'Calculated with Auto Loan ${p.country}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    ),
  );

  return await pdf.save();
}

// ─────────────────────────────────────────────────────────────────────────────

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;
  const HistoryDetailScreen({super.key, required this.entry});

  String get _country => (entry['country'] as String? ?? '').toUpperCase();
  String get _currency => _country == 'UK' ? '£' : '\$';

  NumberFormat get _fmt =>
      NumberFormat.currency(symbol: _currency, decimalDigits: 2);

  double? _amt(String key) {
    final v = entry[key];
    return v == null ? null : (v as num).toDouble();
  }

  List<({String label, String value})> get _rows {
    final rows = <({String label, String value})>[];
    void add(String label, String? val) {
      if (val != null) rows.add((label: label, value: val));
    }

    add(
      'Vehicle Price',
      _amt('vehiclePrice') != null ? _fmt.format(_amt('vehiclePrice')!) : null,
    );
    add(
      'Trade-in Value',
      (_amt('tradeInValue') ?? 0) > 0
          ? _fmt.format(_amt('tradeInValue')!)
          : null,
    );
    add(
      'Down Payment',
      (_amt('downPayment') ?? 0) > 0
          ? _fmt.format(_amt('downPayment')!)
          : null,
    );
    add(
      'Loan Amount',
      _amt('loanAmount') != null
          ? _fmt.format(_amt('loanAmount')!)
          : (_amt('financedAmount') != null
              ? _fmt.format(_amt('financedAmount')!)
              : null),
    );
    add(
      'Loan Term',
      entry['termMonths'] != null ? '${entry['termMonths']} months' : null,
    );
    add(
      'Annual Rate',
      _amt('annualRate') != null
          ? '${_amt('annualRate')!.toStringAsFixed(2)}%'
          : null,
    );
    add(
      'Effective Rate',
      _amt('effectiveRate') != null
          ? '${_amt('effectiveRate')!.toStringAsFixed(2)}%'
          : null,
    );
    add('Province', entry['provinceCode'] as String?);
    add(
      'Monthly Payment',
      _amt('monthlyPayment') != null
          ? _fmt.format(_amt('monthlyPayment')!)
          : null,
    );
    add(
      'Bi-weekly Payment',
      _amt('biWeeklyPayment') != null
          ? _fmt.format(_amt('biWeeklyPayment')!)
          : null,
    );
    add(
      'Total Interest',
      _amt('totalInterest') != null
          ? _fmt.format(_amt('totalInterest')!)
          : null,
    );
    add(
      'Total Cost of Loan',
      _amt('totalCost') != null ? _fmt.format(_amt('totalCost')!) : null,
    );
    return rows;
  }

  String _buildShareText() {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
    const sep = '─────────────────────';
    final buf = StringBuffer();
    buf.writeln('Auto Loan $_country — Loan Summary');
    if (ts != null) buf.writeln(dateFmt.format(ts));
    buf.writeln(sep);
    for (final r in _rows) {
      final pad = ' ' * ((28 - r.label.length).clamp(1, 20));
      buf.writeln('${r.label}$pad${r.value}');
    }
    buf.writeln(sep);
    buf.write('Calculated with Auto Loan $_country');
    return buf.toString();
  }

  Future<void> _shareSummary() async {
    await Share.share(
      _buildShareText(),
      subject: 'Auto Loan $_country Summary',
    );
  }

  Future<void> _exportPdf() async {
    final rows = _rows;
    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
    final ts2 = ts != null ? DateFormat('yyyyMMdd').format(ts) : 'export';

    final params = _HistoryDetailPdfParams(
      country: _country,
      timestamp: entry['timestamp'] as String?,
      rowLabels: rows.map((r) => r.label).toList(),
      rowValues: rows.map((r) => r.value).toList(),
    );

    final bytes = await Isolate.run(() => _buildHistoryDetailPdf(params));

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'autoloan_${_country.toLowerCase()}_$ts2.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.hasFullAccessNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        return Scaffold(
          appBar: AppBar(
            title: Text('$_country Loan Detail'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: l10n.share,
                onPressed: _shareSummary,
              ),
            ],
          ),
          body: CalcwiseScreenScaffold(
            resultKey: ValueKey(entry.hashCode),
            children: [
              // ── Date ──────────────────────────────────────────────────
              if (ts != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    dateFmt.format(ts),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: AppTextSize.md,
                    ),
                  ),
                ),

              // ── Details card ──────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: _rows
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    r.label,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                      fontSize: AppTextSize.body,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppTextSize.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Share / PDF ───────────────────────────────────────────
              // Share is always free. PDF is always visible — gated for free users.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareSummary,
                      icon: const Icon(Icons.share_rounded),
                      label: Text(l10n.share),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: hasFull
                          ? _exportPdf
                          : () => PaywallHard.show(context),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(hasFull ? l10n.exportPdf : l10n.exportPdfPro),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
