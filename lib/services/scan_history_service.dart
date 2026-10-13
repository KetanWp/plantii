import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

/// Offline-first service storing crop scan history using SharedPreferences
class ScanHistoryService {
  static const String _storageKey = 'crop_doctor_scan_history_v1';

  /// Saves a new scan record at the top of the history list
  Future<void> saveScan(ScanRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ScanRecord> history = await getHistory();

    // Prevent duplicate entries
    history.removeWhere((item) => item.id == record.id);
    history.insert(0, record);

    final List<String> encodedList =
        history.map((item) => jsonEncode(item.toMap())).toList();

    await prefs.setStringList(_storageKey, encodedList);
  }

  /// Retrieves all past scan records ordered latest first
  Future<List<ScanRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? rawList = prefs.getStringList(_storageKey);

    if (rawList == null || rawList.isEmpty) {
      return [];
    }

    final List<ScanRecord> records = [];
    for (final rawJson in rawList) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(rawJson) as Map<String, dynamic>;
        records.add(ScanRecord.fromMap(decoded));
      } catch (_) {
        // Skip any corrupted legacy records gracefully
      }
    }
    return records;
  }

  /// Deletes an individual scan by id
  Future<void> deleteScan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ScanRecord> history = await getHistory();

    history.removeWhere((item) => item.id == id);
    final List<String> encodedList =
        history.map((item) => jsonEncode(item.toMap())).toList();

    await prefs.setStringList(_storageKey, encodedList);
  }

  /// Clears all local scans
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
