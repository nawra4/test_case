import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:journal_mobile_api/services/api_service.dart';
import 'journal_event.dart';
import 'journal_state.dart';
import '../../services/journal_service.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalService _journalService = JournalService();

  JournalBloc({required ApiService apiService}) : super(const JournalState()) {
    on<LoadJournals>(_onLoadJournals);
    on<LoadJournalDetail>(_onLoadJournalDetail);
    on<CreateJournal>(_onCreateJournal);
    on<UpdateJournal>(_onUpdateJournal);
    on<DeleteJournal>(_onDeleteJournal);
  }

  Future<void> _onLoadJournals(
      LoadJournals event, Emitter<JournalState> emit) async {
    try {
      final journals = await _journalService.loadJournals();
      emit(JournalLoaded(journals: journals, operationMessage: ''));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onLoadJournalDetail(
      LoadJournalDetail event, Emitter<JournalState> emit) async {
    try {
      final journal = (await _journalService.loadJournals())
          .firstWhere((j) => j['id'] == event.id, orElse: () => {});
      emit(JournalLoaded(
        journals: state.journals,
        selectedJournal: journal.isNotEmpty ? journal : null,
        operationMessage: '',
      ));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onCreateJournal(
      CreateJournal event, Emitter<JournalState> emit) async {
    try {
      final newJournal =
          await _journalService.createJournal(event.title, event.content);
      if (newJournal != null) {
        final updated = List<Map<String, dynamic>>.from(state.journals)
          ..insert(0, newJournal);

        emit(JournalLoaded(
          journals: updated,
          operationMessage: "Jurnal berhasil dibuat",
        ));
      }
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onUpdateJournal(
      UpdateJournal event, Emitter<JournalState> emit) async {
    try {
      final index =
          state.journals.indexWhere((j) => j['id'] == event.id);
      if (index == -1) return;

      final optimisticData = {
        ...state.journals[index],
        'title': event.title,
        'content': event.content,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final updatedList = List<Map<String, dynamic>>.from(state.journals);
      updatedList[index] = optimisticData;

      emit(JournalLoaded(
        journals: updatedList,
        selectedJournal: optimisticData,
        operationMessage: "Jurnal berhasil diupdate",
      ));

      final result =
          await _journalService.updateJournal(event.id, {'title': event.title, 'content': event.content});

      updatedList[index] = result!;
      emit(JournalLoaded(
        journals: updatedList,
        selectedJournal: result,
        operationMessage: "Jurnal berhasil diupdate & disinkron",
      ));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onDeleteJournal(
      DeleteJournal event, Emitter<JournalState> emit) async {
    try {
      await _journalService.deleteJournal(event.id);
      final updated = state.journals
          .where((j) => j['id'] != event.id)
          .toList();

      emit(JournalLoaded(
        journals: updated,
        selectedJournal: null,
        operationMessage: "Jurnal berhasil dihapus",
      ));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }
}
