import 'dart:convert';

import 'package:calcwise_core/calcwise_core.dart' show DatabaseAdapter;

import 'history_service.dart';

/// DatabaseAdapter implementation for AutoLoan.
///
/// Bridges SmartHistoryService (which speaks HistoryEntry / l1_json / l2_json)
/// to AutoLoan's SharedPreferences-backed [HistoryService].
///
/// The `app_key` tracks the screen/feature (e.g. 'autoloan:compare') and
/// `screen_id` is stored in the data so the history screen can group by feature.
class AutoLoanDatabaseAdapter implements DatabaseAdapter {
  final HistoryService _history;

  AutoLoanDatabaseAdapter(this._history);

  // ── Insert ──────────────────────────────────────────────────────────────────

  @override
  Future<int> insertRow(Map<String, dynamic> row) async {
    final screenId = row['screen_id'] as String? ?? 'unknown';
    final appKey = row['app_key'] as String? ?? 'autoloan';
    final hash = (row['result_hash'] as String?) ?? '';
    final isPinned = (row['is_pinned'] as int? ?? 0) == 1;
    final pinLabel = row['pin_label'] as String?;
    final savedAt = row['saved_at'] as int? ?? 0;

    final data = <String, dynamic>{
      'screen_id': screenId,
      'app_key': appKey,
      'l1_json': row['l1_json'],
      'l2_json': row['l2_json'],
      'timestamp': DateTime.fromMillisecondsSinceEpoch(savedAt).toIso8601String(),
    };

    if (isPinned) {
      await _history.saveScenario(screenId, data, hash, label: pinLabel);
    } else {
      await _history.addAutoSave(screenId, data, hash);
    }

    // Return the latest id
    final all = _history.getAll();
    final inserted = all.firstWhere(
      (e) => e['inputHash'] == hash && e['country'] == screenId,
      orElse: () => {'id': 0},
    );
    return (inserted['id'] as int?) ?? 0;
  }

  // ── Query ────────────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getRows({
    required String appKey,
    String? screenId,
    bool? isPinned,
    int? limit,
  }) async {
    // screenId is used as 'country' in HistoryService
    final country = screenId ?? appKey;
    List<Map<String, dynamic>> rows;
    if (isPinned == true) {
      rows = _history.getPinned(country);
    } else if (isPinned == false) {
      rows = _history.getAutoSaves(country);
    } else {
      rows = _history.getAllForCountry(country);
    }
    if (limit != null && rows.length > limit) {
      rows = rows.sublist(0, limit);
    }
    return rows.map(_toAdapterRow).toList();
  }

  @override
  Future<Map<String, dynamic>?> getRowByHash({
    required String appKey,
    required String resultHash,
  }) async {
    final all = _history.getAll();
    final found = all.where((e) => e['inputHash'] == resultHash).firstOrNull;
    return found == null ? null : _toAdapterRow(found);
  }

  // ── Update / Delete ──────────────────────────────────────────────────────────

  @override
  Future<int> updateRow(int id, Map<String, dynamic> values) async {
    final isPinned = values['is_pinned'] as int?;
    final pinLabel = values['pin_label'] as String?;
    if (isPinned == 0) {
      await _history.unpin(id);
    }
    if (pinLabel != null) {
      await _history.rename(id, pinLabel);
    }
    return 1;
  }

  @override
  Future<int> deleteRow(int id) async {
    await _history.delete(id);
    return 1;
  }

  // ── Count / Eviction ─────────────────────────────────────────────────────────

  @override
  Future<int> countRows({required String appKey, bool? isPinned}) async {
    // appKey used as screen/country key in this adapter
    if (isPinned == true) {
      return _history.getPinned(appKey).length;
    } else if (isPinned == false) {
      return _history.getAutoSaves(appKey).length;
    }
    return _history.getAllForCountry(appKey).length;
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestAutoSaves({
    required String appKey,
    required int limit,
  }) async {
    final rows = _history.getAutoSaves(appKey).reversed.toList();
    return rows.take(limit).map(_toAdapterRow).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestPinned({
    required String appKey,
    required int limit,
  }) async {
    final rows = _history.getPinned(appKey).reversed.toList();
    return rows.take(limit).map(_toAdapterRow).toList();
  }

  // ── Mapping ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _toAdapterRow(Map<String, dynamic> row) {
    final createdAt = DateTime.tryParse(row['timestamp'] as String? ?? '')
            ?.millisecondsSinceEpoch ??
        0;

    // l1_json / l2_json may already be stored if the row was written via this
    // adapter; fall back to building them from legacy fields.
    final l1Json = (row['l1_json'] as String?) ?? _buildDefaultL1Json(row);
    final l2Json = (row['l2_json'] as String?) ?? jsonEncode(row);

    return {
      'id': row['id'] ?? 0,
      'app_key': row['app_key'] ?? row['country'] ?? 'autoloan',
      'screen_id': row['screen_id'] ?? row['country'] ?? 'unknown',
      'result_hash': (row['inputHash'] as String?) ?? '',
      'l1_json': l1Json,
      'l2_json': l2Json,
      'saved_at': createdAt,
      'is_pinned': (row['isPinned'] == true) ? 1 : 0,
      'pin_label': row['pinLabel'],
      'pin_order': (row['pinOrder'] as int?) ?? 0,
    };
  }

  String _buildDefaultL1Json(Map<String, dynamic> row) {
    return jsonEncode({
      'label': row['pinLabel'] ?? row['screen_id'] ?? 'Auto Loan',
    });
  }
}
