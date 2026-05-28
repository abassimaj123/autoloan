import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';
import '../../core/freemium/freemium_service.dart';
import 'package:calcwise_core/calcwise_core.dart' show CalcwiseAdService;
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../../widgets/premium_gate.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;
  const HistoryDetailScreen({super.key, required this.entry});

  String get _country => (entry['country'] as String? ?? '').toUpperCase();
  String get _flavor => (entry['country'] as String? ?? 'ca');
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
      'Total Vehicle Cost',
      _amt('totalCost') != null ? _fmt.format(_amt('totalCost')!) : null,
    );
    add(
      'Total Interest',
      _amt('totalInterest') != null
          ? _fmt.format(_amt('totalInterest')!)
          : null,
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
    final dateFmt = DateFormat('MMM d, yyyy');
    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Auto Loan $_country — Loan Summary',
              style: pw.TextStyle(
                fontSize: AppTextSize.title,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (ts != null)
              pw.Text(
                dateFmt.format(ts),
                style: const pw.TextStyle(
                  fontSize: AppTextSize.xs,
                  color: PdfColors.grey600,
                ),
              ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
              },
              children: _rows
                  .map(
                    (r) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            r.label,
                            style: const pw.TextStyle(
                              color: PdfColors.grey700,
                              fontSize: AppTextSize.xs,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            r.value,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: AppTextSize.xs,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Calculated with Auto Loan $_country',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );
    final ts2 = ts != null ? DateFormat('yyyyMMdd').format(ts) : 'export';
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'autoloan_${_country.toLowerCase()}_$ts2.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adService = context.read<CalcwiseAdService>();

    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');

    return ListenableBuilder(
      listenable: Listenable.merge([
        freemiumService.hasFullAccessNotifier,
        freemiumService.isRewardedNotifier,
      ]),
      builder: (context, _) {
        final hasFull =
            freemiumService.hasFullAccess || freemiumService.isRewarded;
        return Scaffold(
          appBar: AppBar(
            title: Text('$_country Loan Detail'),
            centerTitle: false,
            actions: [
              if (hasFull)
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share',
                  onPressed: _shareSummary,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                                Text(
                                  r.label,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: AppTextSize.body,
                                  ),
                                ),
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

              // ── Share / PDF or PremiumGate ────────────────────────────
              if (hasFull)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareSummary,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Export PDF'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                )
              else
                PremiumGate(
                  adService: adService,
                  flavor: _flavor,
                  onUnlocked: () {
                    // ListenableBuilder already rebuilds when isPremiumNotifier fires;
                    // no navigation needed — just let the listenable re-render.
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
