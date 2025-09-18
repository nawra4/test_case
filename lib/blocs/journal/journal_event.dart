import 'package:equatable/equatable.dart';

abstract class JournalEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Load semua jurnal (HomePage)
class LoadJournals extends JournalEvent {}

// Load detail jurnal (DetailPage)
class LoadJournalDetail extends JournalEvent {
  final String id;
  LoadJournalDetail({required this.id});

  @override
  List<Object?> get props => [id];
}

// Create jurnal baru (CreatePage)
class CreateJournal extends JournalEvent {
  final String title;
  final String content;
  CreateJournal({required this.title, required this.content});

  @override
  List<Object?> get props => [title, content];
}

// Update jurnal (EditPage)
class UpdateJournal extends JournalEvent {
  final String id;
  final String title;
  final String content;
  UpdateJournal({required this.id, required this.title, required this.content});

  @override
  List<Object?> get props => [id, title, content];
}

// Delete jurnal (DetailPage)
class DeleteJournal extends JournalEvent {
  final String id;
  DeleteJournal(journal, {required this.id});
  @override List<Object?> get props => [id];
}

// Optional: Sync dengan server / refresh
class SyncJournals extends JournalEvent {}
