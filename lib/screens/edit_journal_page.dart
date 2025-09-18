import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/journal/journal_bloc.dart';
import '../blocs/journal/journal_event.dart';
import '../blocs/journal/journal_state.dart';

class EditJournalPage extends StatefulWidget {
  final String journalId;
  final Map<String, dynamic> journal;

  const EditJournalPage({
    Key? key,
    required this.journalId,
    required this.journal,
  }) : super(key: key);

  @override
  State<EditJournalPage> createState() => _EditJournalPageState();
}

class _EditJournalPageState extends State<EditJournalPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.journal['title']?.toString() ?? '');
    _contentController = TextEditingController(
        text: widget.journal['content']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan konten tidak boleh kosong')),
      );
      return;
    }

    context.read<JournalBloc>().add(UpdateJournal(
          id: widget.journalId,
          title: title,
          content: content,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jurnal berhasil diperbarui')),
          );
          Navigator.pop(context);
        } else if (state is JournalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Jurnal'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Konten'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onSavePressed,
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
