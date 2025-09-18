import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load semua jurnal user
  Future<List<Map<String, dynamic>>> loadJournals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('journals')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Ambil jurnal per ID
  Future<Map<String, dynamic>?> getJournalById(String id) async {
    try {
      final doc = await _firestore.collection('journals').doc(id).get();
      if (doc.exists) return {'id': doc.id, ...doc.data()!};
      return null;
    } catch (e) {
      print("Error getting journal by ID: $e");
      return null;
    }
  }

  /// Create jurnal baru
  Future<Map<String, dynamic>?> createJournal(String title, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docRef = await _firestore.collection('journals').add({
      'title': title,
      'content': content,
      'userId': user.uid,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final doc = await docRef.get();
    return {'id': doc.id, ...doc.data()!};
  }

  /// Update jurnal
  Future<Map<String, dynamic>?> updateJournal(String id, Map<String, dynamic> data) async {
    try {
      final docRef = _firestore.collection('journals').doc(id);
      await docRef.update({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final updatedDoc = await docRef.get();
      return {'id': updatedDoc.id, ...updatedDoc.data()!};
    } catch (e) {
      print("Error updating journal: $e");
      return null;
    }
  }

  /// Delete jurnal
  Future<void> deleteJournal(String id) async {
    try {
      await _firestore.collection('journals').doc(id).delete();
    } catch (e) {
      print("Error deleting journal: $e");
    }
  }

  /// Optional: listen realtime changes
  Stream<List<Map<String, dynamic>>> streamJournals() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('journals')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()!}).toList());
  }

    static Future<Map<String, dynamic>?> submitJournal(String title, String content, {List<String>? tags}) async {
    try {
      final service = JournalService();
      return await service.createJournal(title, content);
    } catch (e) {
      print('Error submitJournal static wrapper: $e');
      return null;
    }
  }
}