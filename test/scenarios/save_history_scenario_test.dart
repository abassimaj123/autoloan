import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calcwise_core/calcwise_core.dart';

// ── In-memory adapter (same pattern as calcwise_core tests) ──────────────────

class _MemoryAdapter implements DatabaseAdapter {
  final List<Map<String, dynamic>> _rows = [];
  int _nextId = 1;

  int get rowCount => _rows.length;

  List<Map<String, dynamic>> get rows => List.unmodifiable(_rows);

  @override
  Future<int> insertRow(Map<String, dynamic> row) async {
    final id = _nextId++;
    _rows.add({...row, 'id': id});
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getRows({
    required String appKey,
    String? screenId,
    bool? isPinned,
    int? limit,
  }) async {
    var result = _rows.where((r) {
      if (r['app_key'] != appKey) return false;
      if (screenId != null && r['screen_id'] != screenId) return false;
      if (isPinned != null) {
        final pinVal = (r['is_pinned'] as int) == 1;
        if (pinVal != isPinned) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      final aPin = a['is_pinned'] as int;
      final bPin = b['is_pinned'] as int;
      if (aPin != bPin) return bPin.compareTo(aPin);
      final aOrder = (a['pin_order'] as int?) ?? 0;
      final bOrder = (b['pin_order'] as int?) ?? 0;
      if (aOrder != bOrder) return bOrder.compareTo(aOrder);
      return (b['saved_at'] as int).compareTo(a['saved_at'] as int);
    });

    if (limit != null && result.length > limit) {
      result = result.sublist(0, limit);
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>?> getRowByHash({
    required String appKey,
    required String resultHash,
  }) async {
    try {
      return _rows.firstWhere(
        (r) => r['app_key'] == appKey && r['result_hash'] == resultHash,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> updateRow(int id, Map<String, dynamic> values) async {
    final idx = _rows.indexWhere((r) => r['id'] == id);
    if (idx < 0) return 0;
    _rows[idx] = {..._rows[idx], ...values};
    return 1;
  }

  @override
  Future<int> deleteRow(int id) async {
    final before = _rows.length;
    _rows.removeWhere((r) => r['id'] == id);
    return before - _rows.length;
  }

  @override
  Future<int> countRows({required String appKey, bool? isPinned}) async {
    return _rows.where((r) {
      if (r['app_key'] != appKey) return false;
      if (isPinned != null) {
        return ((r['is_pinned'] as int) == 1) == isPinned;
      }
      return true;
    }).length;
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestAutoSaves({
    required String appKey,
    required int limit,
  }) async {
    final rows = _rows
        .where((r) => r['app_key'] == appKey && (r['is_pinned'] as int) == 0)
        .toList()
      ..sort(
        (a, b) => (a['saved_at'] as int).compareTo(b['saved_at'] as int),
      );
    return rows.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestPinned({
    required String appKey,
    required int limit,
  }) async {
    final rows = _rows
        .where((r) => r['app_key'] == appKey && (r['is_pinned'] as int) == 1)
        .toList()
      ..sort(
        (a, b) => (a['saved_at'] as int).compareTo(b['saved_at'] as int),
      );
    return rows.take(limit).toList();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> _pump() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MemoryAdapter adapter;
  late CalcwiseFreemium freemium;
  late SmartHistoryService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    adapter = _MemoryAdapter();
    freemium = CalcwiseFreemium(appKey: 'autoloan');
    await freemium.initialize();
    svc = SmartHistoryService(
      db: adapter,
      freemium: freemium,
      overrideSaveDebounce: Duration.zero,
    );
  });

  tearDown(() => svc.dispose());

  group('AutoLoan — save → history scenarios', () {
    test('scenario: calculate auto loan → entry appears in history', () async {
      // GIVEN: typical auto loan inputs (mirrors ca_provider._doAutoSave fields)
      const vehiclePrice = 35000.0;
      const downPayment = 5000.0;
      const loanAmount = 30000.0;
      const annualRate = 6.99;
      const termMonths = 60;

      final inputHash = ResultHasher.hashMixed({
        'vehiclePrice': ResultHasher.roundTo(vehiclePrice, 500),
        'downPayment': ResultHasher.roundTo(downPayment, 500),
        'annualRate': ResultHasher.roundTo(annualRate, 0.1),
        'termMonths': termMonths,
      });

      // WHEN: auto-save triggered (mirrors what CAProvider._doAutoSave does via smartHistoryService)
      var savedCalled = false;
      svc.scheduleAutoSave(
        appKey: 'autoloan',
        screenId: 'calculator',
        inputHash: inputHash,
        l1: {
          'label': '\$${loanAmount.toStringAsFixed(0)} · ${annualRate}% · ${termMonths}mo',
          'monthlyPayment': 594.0,
        },
        l2: {
          'vehiclePrice': vehiclePrice,
          'downPayment': downPayment,
          'loanAmount': loanAmount,
          'annualRate': annualRate,
          'termMonths': termMonths,
          'monthlyPayment': 594.0,
          'totalCost': 35640.0,
          'totalInterest': 5640.0,
        },
        onSaved: () => savedCalled = true,
      );
      await _pump();

      // THEN: entry visible in history
      final history = await svc.getHistory('autoloan');
      expect(history, isNotEmpty,
          reason: 'History must contain the saved entry');
      expect(history.first.l2['vehiclePrice'], vehiclePrice);
      expect(savedCalled, isTrue,
          reason:
              'onSaved must fire — anti-regression for history refresh race condition');
    });

    test('scenario: two different auto loans → both entries in history',
        () async {
      for (var i = 0; i < 2; i++) {
        final price = 25000.0 + i * 10000;
        svc.scheduleAutoSave(
          appKey: 'autoloan',
          screenId: 'calculator',
          inputHash: 'hash-autoloan-$i',
          l1: {'label': '\$${price.toStringAsFixed(0)}'},
          l2: {'vehiclePrice': price, 'annualRate': 6.99},
        );
        await _pump();
      }
      final history = await svc.getHistory('autoloan');
      expect(history.length, 2);
    });

    test(
        'scenario: same inputs twice → only one history entry (no duplicates)',
        () async {
      const hash = 'same-hash-autoloan';
      for (var i = 0; i < 3; i++) {
        svc.scheduleAutoSave(
          appKey: 'autoloan',
          screenId: 'calculator',
          inputHash: hash,
          l1: {'label': 'Same car'},
          l2: {'vehiclePrice': 30000.0, 'termMonths': 48},
        );
        await _pump();
      }
      expect(adapter.rowCount, 1,
          reason: 'Identical inputs must not create duplicates');
    });

    test('scenario: save pinned scenario → survives ring buffer eviction',
        () async {
      // Pin a scenario first (mirrors CAProvider.saveScenario)
      await svc.saveScenario(
        appKey: 'autoloan',
        screenId: 'calculator',
        inputHash: 'pinned-scenario-autoloan',
        l1: {'label': 'Best rate deal'},
        l2: {'vehiclePrice': 45000.0, 'annualRate': 4.99, 'termMonths': 72},
        label: 'Best rate deal',
      );
      // Fill ring buffer beyond free limit
      for (var i = 0; i < MonetizationConfig.freeRingBufferSize + 2; i++) {
        svc.scheduleAutoSave(
          appKey: 'autoloan',
          screenId: 'calculator',
          inputHash: 'auto-autoloan-$i',
          l1: {'label': 'Auto $i'},
          l2: {'vehiclePrice': i * 1000.0},
        );
        await _pump();
      }
      final pinned = await svc.getPinned('autoloan');
      expect(pinned, isNotEmpty,
          reason: 'Pinned scenario must survive ring buffer eviction');
      expect(pinned.first.l2['vehiclePrice'], 45000.0);
    });
  });
}
