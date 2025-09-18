import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final String? uid;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.uid,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? uid,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      uid: uid ?? this.uid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, isLoading, uid, errorMessage];
}
