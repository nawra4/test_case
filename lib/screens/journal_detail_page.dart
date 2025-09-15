import 'package:flutter/material.dart';
import '../services/journal_service.dart';
import 'edit_journal_page.dart';

class JournalDetailPage extends StatelessWidget {
  final String journalId;
  final String title;
  final String content;
  final String date;
  final String time;

  const JournalDetailPage({
    super.key,
    required this.journalId,
    required this.title,
    required this.content,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F7),
      appBar: AppBar(
        title: const Text("Detail Jurnal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditJournalPage(
                    journalId: journalId,
                    initialTitle: title,
                    initialContent: content,
                  ),
                ),
              );

              if (updated != null) {
                Navigator.pop(context, updated); // Kirim updated data ke HomeScreen
              }
            },
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            label: const Text(
              "Edit",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              _showDeleteDialog(context);
            },
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            label: const Text(
              "Hapus",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(date, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(width: 20),
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(time, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Content Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  )
                ),
                ),
              ),
          ],
        ))
    );
}
  void _showDeleteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Hapus Jurnal"),
        content: const Text("Apakah Anda yakin ingin menghapus jurnal ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              // Panggil delete terlebih dahulu
              final success = await JournalService.deleteJournal(journalId);

              if (!context.mounted) return; // Pastikan context masih valid

              Navigator.pop(context); // Tutup dialog

              if (success) {
                // Kirim info ke HomeScreen bahwa jurnal terhapus
                Navigator.pop(context, {'deleted': true});
              } else {
                // Opsional: tampilkan error jika gagal hapus
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gagal menghapus jurnal."),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      );
    },
  );
}
}