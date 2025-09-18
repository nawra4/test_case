import 'package:equatable/equatable.dart';

/// Base class untuk semua state jurnal
class JournalState extends Equatable {
  final List<Map<String, dynamic>> journals;
  final Map<String, dynamic>? selectedJournal;
  final String? operationMessage;
  final String? error;

  const JournalState({
    this.journals = const [],
    this.selectedJournal,
    this.operationMessage,
    this.error,
  });

  JournalState copyWith({
    List<Map<String, dynamic>>? journals,
    Map<String, dynamic>? selectedJournal,
    String? operationMessage,
    String? error,
  }) {
    return JournalState(
      journals: journals ?? this.journals,
      selectedJournal: selectedJournal ?? this.selectedJournal,
      operationMessage: operationMessage ?? this.operationMessage,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        journals,
        selectedJournal,
        operationMessage,
        error,
      ];

  get isLoading => null;
}

/// State saat jurnal berhasil dimuat / diperbarui
class JournalLoaded extends JournalState {
  const JournalLoaded({List<Map<String, dynamic>>? journals, Map<String, dynamic>? selectedJournal, required String operationMessage})
      : super(journals: journals ?? const []);
}

/// State saat terjadi error
class JournalError extends JournalState {
  final String message;

  const JournalError(this.message) : super(error: message);
}
