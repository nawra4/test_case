import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JournalStorageService {
  static const String _journalKey = 'journals';

  // Simpan list jurnal ke local storage
  static Future<void> saveJournals(List<Map<String, dynamic>> journals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final journalString = jsonEncode(journals);
      await prefs.setString(_journalKey, journalString);
    } catch (e) {
      print('Error saving journals: $e');
    }
  }

  // Ambil list jurnal dari local storage
  static Future<List<Map<String, dynamic>>> getJournals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final journalString = prefs.getString(_journalKey);
      
      if (journalString != null && journalString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(journalString);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error getting journals: $e');
    }
    return [];
  }

  // Tambah jurnal baru ke storage
  static Future<void> addJournal(Map<String, dynamic> journal) async {
    try {
      final journals = await getJournals();
      
      // Pastikan ada ID dan timestamp
      final journalWithMeta = Map<String, dynamic>.from(journal);
      if (!journalWithMeta.containsKey('id') || journalWithMeta['id'] == null) {
        journalWithMeta['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      if (!journalWithMeta.containsKey('created_at') || journalWithMeta['created_at'] == null) {
        journalWithMeta['created_at'] = DateTime.now().toIso8601String();
      }
      
      journals.insert(0, journalWithMeta); // Tambah di paling atas
      await saveJournals(journals);
    } catch (e) {
      print('Error adding journal: $e');
    }
  }

  // Hapus jurnal berdasarkan ID
  static Future<void> deleteJournal(String journalId) async {
    try {
      final journals = await getJournals();
      journals.removeWhere((journal) => journal['id']?.toString() == journalId);
      await saveJournals(journals);
    } catch (e) {
      print('Error deleting journal: $e');
    }
  }

  // Update jurnal
  static Future<void> updateJournal(String journalId, Map<String, dynamic> updatedJournal) async {
    try {
      final journals = await getJournals();
      final index = journals.indexWhere((journal) => journal['id']?.toString() == journalId);
      
      if (index != -1) {
        journals[index] = {...journals[index], ...updatedJournal};
        await saveJournals(journals);
      }
    } catch (e) {
      print('Error updating journal: $e');
    }
  }

  // Clear semua jurnal
  static Future<void> clearAllJournals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalKey);
    } catch (e) {
      print('Error clearing journals: $e');
    }
  }

  // Helper function untuk safe get journal ID
  static String? getJournalId(Map<String, dynamic>? journal) {
    if (journal == null) return null;
    final id = journal['id'];
    if (id == null) return null;
    return id.toString();
  }
}