import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/history_service.dart';
import '../../services/trial_service.dart';
import '../../widgets/rewarded_button.dart';
import '../../services/ad_service.dart';

class HistoryScreen extends StatelessWidget {
  final String country;
  const HistoryScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final history      = context.read<HistoryService>();
    final trialService = context.read<TrialService>();
    final adService    = context.read<AdService>();

    final hasFull  = trialService.isTrialActive || trialService.isRewardedActive;
    final all      = history.getAll().where((e) => e['country'] == country).toList();
    final shown    = hasFull ? all : history.getFree().where((e) => e['country'] == country).toList();
    final locked   = all.length - shown.length;
    final dateFmt  = DateFormat('MMM d, yyyy · HH:mm');
    final currency = country == 'uk' ? '£' : '\$';
    final fmt      = NumberFormat.currency(symbol: currency, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('History — ${country.toUpperCase()}'),
        actions: [
          if (shown.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await history.clear();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: all.isEmpty
          ? const Center(child: Text('No calculations yet.'))
          : Column(children: [
              if (!hasFull && locked > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text('$locked older record${locked > 1 ? 's' : ''} locked',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        RewardedButton(
                          adService: adService,
                          trialService: trialService,
                          onUnlocked: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HistoryScreen(country: country))),
                        ),
                      ]),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final e         = shown[i];
                    final ts        = DateTime.tryParse(e['timestamp'] ?? '');
                    final price     = (e['vehiclePrice'] as num?)?.toDouble() ?? 0;
                    final payment   = _getPayment(e);
                    final totalCost = (e['totalCost'] as num?)?.toDouble() ?? 0;

                    return ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(fmt.format(price)),
                      subtitle: Text(ts != null ? dateFmt.format(ts) : ''),
                      trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmt.format(payment),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('total ${fmt.format(totalCost)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                    );
                  },
                ),
              ),
            ]),
    );
  }

  double _getPayment(Map<String, dynamic> e) {
    return (e['monthlyPayment'] ?? e['regularMonthly'] ?? e['biWeeklyPayment'] ?? 0)
        as double;
  }
}
