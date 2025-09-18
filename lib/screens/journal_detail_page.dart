import 'package:flutter/material.dart';
import 'edit_journal_page.dart';

class JournalDetailPage extends StatefulWidget {
  final String journalId;
  final String title;
  final String content;
  final String date;
  final String time;

  const JournalDetailPage({
    Key? key,
    required this.journalId,
    required this.title,
    required this.content,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> {
  late String _title;
  late String _content;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _content = widget.content;
  }

  Future<void> _editJournal() async {
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditJournalPage(
          journalId: widget.journalId,
          journal: {
            'id': widget.journalId,
            'title': _title,
            'content': _content,
            'date': widget.date,
            'time': widget.time,
          },
        ),
      ),
    );

    if (updated != null) {
      setState(() {
        _title = updated['title'] ?? _title;
        _content = updated['content'] ?? _content;
      });
      // kirim balik ke Home juga biar sinkron
      Navigator.pop(context, {
        'id': widget.journalId,
        'title': _title,
        'content': _content,
        'date': widget.date,
        'time': widget.time,
      });
    }
  }

    void _deleteJournal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Jurnal"),
        content: const Text("Apakah kamu yakin ingin menghapus jurnal ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pop(context, {
        'id': widget.journalId,
        'deleted': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Jurnal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editJournal,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteJournal,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(widget.date,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(widget.time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _content,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
