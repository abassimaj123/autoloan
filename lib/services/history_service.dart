import 'dart:convert';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/freemium/freemium_service.dart';

/// History storage for AutoLoan (CA / UK / US flavors).
///
/// Stored in SharedPreferences under [_kEntries] as a JSON-encoded list.
/// Each entry is a `Map<String, dynamic>` that includes all calculator fields
/// plus the metadata fields added by this service:
///
/// | Field        | Type   | Description                              |
/// |---|---|---|
/// | id           | int     | Auto-incrementing entry identifier       |
/// | country      | String  | 'ca', 'uk', or 'us'                      |
/// | inputHash    | String  | Deterministic 8-char hex hash of inputs  |
/// | isPinned     | bool    | Whether this is a pinned scenario        |
/// | pinLabel     | String? | User-defined scenario name (premium)     |
/// | pinOrder     | int     | Sort weight (reserved, always 0 for now) |
/// | timestamp    | String  | ISO-8601 save time                       |
///
/// ## Ring buffer
/// | Tier    | Auto-saves | Pinned |
/// |---------|-----------|--------|
/// | Free    | 5 max, FIFO eviction | 3 max |
/// | Premium | 20 max, FIFO eviction | unlimited |
class HistoryService {
  static const _kEntries = 'loan_history_v2';
  static const _kNextId = 'loan_history_next_id';
  static const _kLegacyEntries = 'loan_history'; // pre-1.0.5 key (no metadata)

  final SharedPreferences _prefs;

  HistoryService(this._prefs) {
    _migrateLegacyIfNeeded();
  }

  /// One-time lazy migration from the pre-1.0.5 `loan_history` key.
  ///
  /// Legacy entries carried calculator fields + `country` + `timestamp` but
  /// none of the v2 metadata (`id`, `inputHash`, `isPinned`, `pinLabel`,
  /// `pinOrder`). Wrap each into the v2 shape, write under [_kEntries] and
  /// delete the old key. Runs only when the v2 key is absent so it can never
  /// clobber existing v2 data. SharedPreferences writes update the in-memory
  /// cache synchronously, so subsequent sync reads see the migrated list.
  void _migrateLegacyIfNeeded() {
    if (_prefs.containsKey(_kEntries)) return;
    final legacyRaw = _prefs.getStringList(_kLegacyEntries);
    if (legacyRaw == null) return;

    final epoch0 = DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
    final migrated = <Map<String, dynamic>>[];
    for (final raw in legacyRaw) {
      Map<String, dynamic> entry;
      try {
        entry = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue; // skip corrupt legacy entries
      }
      migrated.add({
        ...entry,
        'id': _nextId(),
        'country': entry['country'] ?? 'ca',
        // Legacy entries never stored an input hash; empty string never
        // collides with real 8-char hashes used for dedup/promotion.
        'inputHash': '',
        'isPinned': false,
        'pinLabel': null,
        'pinOrder': 0,
        // Missing timestamp → epoch 0 so migrated entries sort oldest.
        'timestamp': entry['timestamp'] ?? epoch0,
      });
    }

    // Fire-and-forget: in-memory cache is updated synchronously.
    _prefs.setStringList(
      _kEntries,
      migrated.map((e) => jsonEncode(e)).toList(),
    );
    _prefs.remove(_kLegacyEntries);
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// All entries across all countries, stored oldest-first internally.
  List<Map<String, dynamic>> _rawAll() {
    final raw = _prefs.getStringList(_kEntries) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// All entries across all countries, newest-first (for display).
  List<Map<String, dynamic>> getAll() => _rawAll().reversed.toList();

  /// All entries for [country], newest-first.
  List<Map<String, dynamic>> getAllForCountry(String country) =>
      getAll().where((e) => e['country'] == country).toList();

  /// Non-pinned (auto-saved) entries for [country], newest-first.
  List<Map<String, dynamic>> getAutoSaves(String country) =>
      getAllForCountry(country)
          .where((e) => e['isPinned'] != true)
          .toList();

  /// Pinned entries for [country], newest-first.
  List<Map<String, dynamic>> getPinned(String country) =>
      getAllForCountry(country)
          .where((e) => e['isPinned'] == true)
          .toList();

  // ── Auto-save ─────────────────────────────────────────────────────────────

  /// Save a non-pinned entry with hash dedup + ring buffer enforcement.
  ///
  /// Skips silently if [inputHash] is already present for [country].
  /// After inserting, evicts the oldest non-pinned entries beyond the
  /// ring buffer limit (Free = 5, Premium = 20).
  Future<void> addAutoSave(
    String country,
    Map<String, dynamic> data,
    String inputHash,
  ) async {
    final all = _rawAll();

    // Hash dedup — skip if same inputs already saved for this country
    final exists = all.any(
      (e) => e['country'] == country && e['inputHash'] == inputHash,
    );
    if (exists) return;

    final id = _nextId();
    all.add({
      ...data,
      'id': id,
      'country': country,
      'inputHash': inputHash,
      'isPinned': false,
      'pinLabel': null,
      'pinOrder': 0,
      if (!data.containsKey('timestamp'))
        'timestamp': DateTime.now().toIso8601String(),
    });
    await _save(all);
    await _enforceRingBuffer(all, country);
  }

  // ── Save Scenario (pinned) ────────────────────────────────────────────────

  /// Save a pinned scenario. Bypasses the ring buffer.
  ///
  /// If an entry with [inputHash] already exists for [country], promotes it
  /// to pinned instead of creating a duplicate entry.
  /// Free users: oldest pinned entry is evicted when the 3-entry limit is
  /// exceeded.
  Future<void> saveScenario(
    String country,
    Map<String, dynamic> data,
    String inputHash, {
    String? label,
  }) async {
    var all = _rawAll();

    final idx = all.indexWhere(
      (e) => e['country'] == country && e['inputHash'] == inputHash,
    );
    if (idx >= 0) {
      // Promote existing auto-save entry to pinned
      all[idx] = {
        ...all[idx],
        'isPinned': true,
        if (label != null) 'pinLabel': label,
      };
    } else {
      // Insert new pinned entry
      final id = _nextId();
      all.add({
        ...data,
        'id': id,
        'country': country,
        'inputHash': inputHash,
        'isPinned': true,
        'pinLabel': label,
        'pinOrder': 0,
        if (!data.containsKey('timestamp'))
          'timestamp': DateTime.now().toIso8601String(),
      });
    }
    await _save(all);

    // Enforce pinned cap for free users
    if (!freemiumService.hasFullAccess) {
      await _enforcePinnedLimit(all, country);
    }
  }

  // ── Pin management ────────────────────────────────────────────────────────

  /// Remove pin from entry [id] (keeps the entry as a regular auto-save).
  Future<void> unpin(int id) async {
    final all = _rawAll();
    final idx = all.indexWhere((e) => e['id'] == id);
    if (idx < 0) return;
    all[idx] = {
      ...all[idx],
      'isPinned': false,
      'pinLabel': null,
      'pinOrder': 0,
    };
    await _save(all);
  }

  /// Rename a pinned scenario label.
  Future<void> rename(int id, String label) async {
    final all = _rawAll();
    final idx = all.indexWhere((e) => e['id'] == id);
    if (idx < 0) return;
    all[idx] = {...all[idx], 'pinLabel': label};
    await _save(all);
  }

  /// Permanently delete entry [id].
  Future<void> delete(int id) async {
    final all = _rawAll();
    all.removeWhere((e) => e['id'] == id);
    await _save(all);
  }

  /// Clear all history across all countries.
  Future<void> clear() async {
    await _prefs.remove(_kEntries);
    await _prefs.remove(_kNextId);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  int _nextId() {
    final next = (_prefs.getInt(_kNextId) ?? 0) + 1;
    _prefs.setInt(_kNextId, next); // fire-and-forget; in-memory cache is sync
    return next;
  }

  Future<void> _save(List<Map<String, dynamic>> all) async {
    await _prefs.setStringList(
      _kEntries,
      all.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> _enforceRingBuffer(
    List<Map<String, dynamic>> all,
    String country,
  ) async {
    final limit = freemiumService.hasFullAccess
        ? MonetizationConfig.premiumRingBufferSize
        : MonetizationConfig.freeRingBufferSize;

    // Oldest non-pinned entries for this country (index 0 = oldest in raw list)
    final autoSaves = all
        .where((e) => e['country'] == country && e['isPinned'] != true)
        .toList();

    if (autoSaves.length <= limit) return;

    final excess = autoSaves.length - limit;
    final toEvict = autoSaves.take(excess).map((e) => e['id']).toSet();
    all.removeWhere((e) => toEvict.contains(e['id']));
    await _save(all);
  }

  Future<void> _enforcePinnedLimit(
    List<Map<String, dynamic>> all,
    String country,
  ) async {
    const limit = MonetizationConfig.freePinnedLimit;
    final pinned = all
        .where((e) => e['country'] == country && e['isPinned'] == true)
        .toList();

    if (pinned.length <= limit) return;

    final excess = pinned.length - limit;
    final toEvict = pinned.take(excess).map((e) => e['id']).toSet();
    all.removeWhere((e) => toEvict.contains(e['id']));
    await _save(all);
  }
}
