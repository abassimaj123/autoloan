import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto_loan/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryService — legacy loan_history migration', () {
    test('migrates legacy entries to loan_history_v2 and deletes old key',
        () async {
      final legacy = [
        jsonEncode({
          'vehiclePrice': 30000.0,
          'monthlyPayment': 550.0,
          'country': 'ca',
          'timestamp': '2026-01-15T10:00:00.000',
        }),
        jsonEncode({
          'vehiclePrice': 45000.0,
          'monthlyPayment': 780.0,
          'country': 'us',
          // no timestamp — must fall back to epoch 0
        }),
      ];
      SharedPreferences.setMockInitialValues({'loan_history': legacy});
      final prefs = await SharedPreferences.getInstance();

      final svc = HistoryService(prefs);

      // Old key deleted, new key present
      expect(prefs.containsKey('loan_history'), isFalse);
      expect(prefs.containsKey('loan_history_v2'), isTrue);

      final all = svc.getAll(); // newest-first
      expect(all.length, 2);

      // Order preserved (legacy stored oldest-first → reversed for display)
      expect(all[0]['country'], 'us');
      expect(all[1]['country'], 'ca');

      // Sequential ids assigned via the next-id mechanism
      expect(all[1]['id'], 1);
      expect(all[0]['id'], 2);
      expect(prefs.getInt('loan_history_next_id'), 2);

      // v2 metadata present on every migrated entry
      for (final e in all) {
        expect(e['isPinned'], isFalse);
        expect(e['pinLabel'], isNull);
        expect(e['pinOrder'], 0);
        expect(e['inputHash'], '');
      }

      // Original calculator fields intact
      expect(all[1]['vehiclePrice'], 30000.0);
      expect(all[1]['timestamp'], '2026-01-15T10:00:00.000');
      // Missing timestamp → epoch 0
      expect(
        all[0]['timestamp'],
        DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      );
    });

    test('skips corrupt legacy entries instead of losing everything',
        () async {
      SharedPreferences.setMockInitialValues({
        'loan_history': [
          'not-json{{{',
          jsonEncode({'vehiclePrice': 20000.0, 'country': 'uk'}),
        ],
      });
      final prefs = await SharedPreferences.getInstance();

      final svc = HistoryService(prefs);

      final all = svc.getAll();
      expect(all.length, 1);
      expect(all[0]['country'], 'uk');
      expect(prefs.containsKey('loan_history'), isFalse);
    });

    test('does not run when loan_history_v2 already exists', () async {
      final v2Entry = jsonEncode({
        'id': 7,
        'country': 'ca',
        'inputHash': 'abcd1234',
        'isPinned': true,
        'pinLabel': 'My deal',
        'pinOrder': 0,
        'timestamp': '2026-02-01T09:00:00.000',
        'vehiclePrice': 50000.0,
      });
      SharedPreferences.setMockInitialValues({
        'loan_history_v2': [v2Entry],
        'loan_history': [
          jsonEncode({'vehiclePrice': 1.0, 'country': 'ca'}),
        ],
      });
      final prefs = await SharedPreferences.getInstance();

      final svc = HistoryService(prefs);

      final all = svc.getAll();
      expect(all.length, 1);
      expect(all[0]['id'], 7);
      expect(all[0]['isPinned'], isTrue);
      // Legacy key untouched because migration was skipped
      expect(prefs.containsKey('loan_history'), isTrue);
    });

    test('no-op when neither key exists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final svc = HistoryService(prefs);

      expect(svc.getAll(), isEmpty);
      expect(prefs.containsKey('loan_history_v2'), isFalse);
    });
  });
}
