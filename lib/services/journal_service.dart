import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'journal_storage_service.dart';

class JournalService {
  // Submit jurnal ke server DAN simpan ke local storage
  static Future<Map<String, dynamic>?> submitJournal(String title, String content, {List<String>? tags}) async {
    try {
      // Siapkan data jurnal dengan ID dan timestamp
      final journalData = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": title,
        "content": content,
        "tags": tags ?? <String>[],
        "date": _formatDate(DateTime.now()),
        "time": _formatTime(DateTime.now()),
        "created_at": DateTime.now().toIso8601String(),
        "synced": false,
      };

      // Simpan ke local storage dulu (offline-first approach)
      await JournalStorageService.addJournal(journalData);

      // Coba kirim ke server
      try {
        final token = await ApiService.getToken();
        final response = await http.post(
          Uri.parse("${ApiService.baseUrl}/journals"),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "title": title,
            "content": content,
            "tags": tags ?? <String>[],
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final serverResponse = jsonDecode(response.body);
          
          // Update data local dengan response dari server
          if (serverResponse is Map<String, dynamic>) {
            final updatedData = {
              ...journalData,
              "synced": true,
            };
            
            // Jika server memberikan ID baru, update ID
            if (serverResponse.containsKey('id') && serverResponse['id'] != null) {
              updatedData['server_id'] = serverResponse['id'].toString();
            }
            
            await JournalStorageService.updateJournal(journalData['id'] as String, updatedData);
          }
          
          return {...journalData, "synced": true};
        } else {
          print('Failed to sync to server: ${response.statusCode}');
          return journalData; // Return local data
        }
      } catch (e) {
        print('Network error, saved locally: $e');
        return journalData; // Return local data
      }
    } catch (e) {
      print('Error creating journal: $e');
      return null;
    }
  }

  // Load jurnal dari local storage
  static Future<List<Map<String, dynamic>>> loadLocalJournals() async {
    return await JournalStorageService.getJournals();
  }

  // PERBAIKAN: Merge data server dengan data lokal, bukan replace
  static Future<List<Map<String, dynamic>>> fetchAndSyncJournals() async {
    try {
      // Load data lokal dulu
      final localJournals = await loadLocalJournals();
      print('Local journals count: ${localJournals.length}');

      // Coba fetch dari server
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/journals"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Server response: $data');
        
        if (data is List) {
          final serverJournals = data.map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'id': item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                'server_id': item['id']?.toString(), // Simpan server ID terpisah
                'title': item['title']?.toString() ?? 'Untitled',
                'date': item['date']?.toString() ?? _formatDate(DateTime.now()),
                'time': item['time']?.toString() ?? _formatTime(DateTime.now()),
                'content': item['content']?.toString() ?? '',
                'tags': _extractTags(item['tags']),
                'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                'synced': true,
              };
            }
            return <String, dynamic>{};
          }).where((item) => item.isNotEmpty).toList();

          // MERGE LOGIC: Gabungkan data server dan lokal
          final mergedJournals = _mergeJournals(localJournals, List<Map<String, dynamic>>.from(serverJournals));
          
          // Update local storage dengan hasil merge
          await JournalStorageService.saveJournals(mergedJournals);
          
          print('Merged journals count: ${mergedJournals.length}');
          return mergedJournals;
        }
      } else {
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching from server: $e');
    }
    
    // Jika gagal fetch server, return data lokal
    print('Returning local journals');
    return await loadLocalJournals();
  }

  // PERBAIKAN: Fungsi untuk merge data server dan lokal
  static List<Map<String, dynamic>> _mergeJournals(
    List<Map<String, dynamic>> localJournals, 
    List<Map<String, dynamic>> serverJournals
  ) {
    final Map<String, Map<String, dynamic>> journalMap = {};
    
    // Tambah semua jurnal lokal dulu
    for (final journal in localJournals) {
      final id = journal['id']?.toString();
      if (id != null) {
        journalMap[id] = Map<String, dynamic>.from(journal);
      }
    }
    
    // Merge dengan data server
    for (final serverJournal in serverJournals) {
      final serverId = serverJournal['server_id']?.toString();
      final id = serverJournal['id']?.toString();
      
      // Cari jurnal lokal yang match dengan server ID
      String? matchingLocalId;
      for (final localJournal in localJournals) {
        if (localJournal['server_id']?.toString() == serverId && serverId != null) {
          matchingLocalId = localJournal['id']?.toString();
          break;
        }
      }
      
      if (matchingLocalId != null && journalMap.containsKey(matchingLocalId)) {
        // Update jurnal lokal dengan data server
        journalMap[matchingLocalId] = {
          ...journalMap[matchingLocalId]!,
          ...serverJournal,
          'id': matchingLocalId, // Keep local ID
          'synced': true,
        };
      } else if (id != null) {
        // Jurnal baru dari server
        journalMap[id] = serverJournal;
      }
    }
    
    // Convert back to list dan sort by created_at
    final result = journalMap.values.toList();
    result.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
      return bTime.compareTo(aTime); // Descending order (newest first)
    });
    
    return result;
  }

  // Hapus jurnal dari local dan server
  static Future<bool> deleteJournal(String journalId) async {
    try {
      // Ambil data jurnal untuk mendapatkan server_id
      final localJournals = await loadLocalJournals();
      final targetJournal = localJournals.firstWhere(
        (journal) => journal['id']?.toString() == journalId,
        orElse: () => <String, dynamic>{},
      );
      
      // Hapus dari local storage dulu
      await JournalStorageService.deleteJournal(journalId);

      // Coba hapus dari server jika ada server_id
      final serverId = targetJournal['server_id']?.toString();
      if (serverId != null) {
        try {
          final token = await ApiService.getToken();
          final response = await http.delete(
            Uri.parse("${ApiService.baseUrl}/journals/$serverId"),
            headers: {
              "Authorization": "Bearer $token",
            },
          );

          if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
            print('Successfully deleted from server');
          } else {
            print('Failed to delete from server: ${response.statusCode}');
          }
        } catch (e) {
          print('Network error while deleting: $e');
        }
      }
      
      return true; // Local deletion always succeeds
    } catch (e) {
      print('Error deleting journal: $e');
      return false;
    }
  }

  // Update jurnal
  static Future<bool> updateJournal(String journalId, Map<String, dynamic> updatedData) async {
    try {
      // Update local storage dulu
      await JournalStorageService.updateJournal(journalId, updatedData);

      // Coba update ke server
      try {
        final token = await ApiService.getToken();
        final response = await http.put(
          Uri.parse("${ApiService.baseUrl}/journals/$journalId"),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(updatedData),
        );

        if (response.statusCode == 200) {
          // Mark as synced
          await JournalStorageService.updateJournal(journalId, {...updatedData, 'synced': true});
          return true;
        } else {
          print('Failed to update server: ${response.statusCode}');
          return true; // Local update succeeded
        }
      } catch (e) {
        print('Network error while updating: $e');
        return true; // Local update succeeded
      }
    } catch (e) {
      print('Error updating journal: $e');
      return false;
    }
  }

  // Retry sync untuk jurnal yang belum tersinkron
  static Future<void> retrySyncUnsyncedJournals() async {
    try {
      final localJournals = await loadLocalJournals();
      final unsyncedJournals = localJournals.where((journal) => journal['synced'] != true).toList();
      
      print('Found ${unsyncedJournals.length} unsynced journals');
      
      for (final journal in unsyncedJournals) {
        try {
          final token = await ApiService.getToken();
          final response = await http.post(
            Uri.parse("${ApiService.baseUrl}/journals"),
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "title": journal['title'],
              "content": journal['content'],
              "tags": journal['tags'] ?? [],
            }),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            final serverResponse = jsonDecode(response.body);
            
            // Update local journal dengan server ID dan mark as synced
            final updatedJournal = {
              ...journal,
              'server_id': serverResponse['id']?.toString(),
              'synced': true,
            };
            
            await JournalStorageService.updateJournal(journal['id']?.toString() ?? '', updatedJournal);
            print('Successfully synced journal: ${journal['title']}');
          }
        } catch (e) {
          print('Failed to sync journal ${journal['title']}: $e');
        }
      }
    } catch (e) {
      print('Error retrying sync: $e');
    }
  }

  // Helper functions
  static String _formatDate(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
  }

  static String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  static List<String> _extractTags(dynamic tags) {
    if (tags is List) {
      return tags.map((tag) => tag.toString()).toList();
    } else if (tags is String) {
      return [tags];
    }
    return <String>[];
  }
}