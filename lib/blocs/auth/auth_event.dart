import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String passwordConfirm;

  const RegisterRequested(
      this.username, this.email, this.password, this.passwordConfirm);

  @override
  List<Object?> get props => [username, email, password, passwordConfirm];
}

class CheckAuthStatus extends AuthEvent {}

class LogoutRequested extends AuthEvent {}
