import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();

  AuthBloc() : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LogoutRequested>(_onLogoutRequested);

    // Bisa dipanggil juga di main.dart setelah BlocProvider
    add(CheckAuthStatus());
  }

  // 🔑 Login
  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, uid: null));

    try {
      final User? user =
          await _authService.login(event.email, event.password);

      if (user != null) {
        emit(state.copyWith(
            isAuthenticated: true, uid: user.uid, isLoading: false));
      } else {
        emit(state.copyWith(
            isAuthenticated: false,
            isLoading: false,
            errorMessage: "Login gagal: user tidak ditemukan"));
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = "Email tidak terdaftar";
      } else if (e.code == 'wrong-password') {
        message = "Password salah";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid";
      } else {
        message = "Error: ${e.message}";
      }

      emit(state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: message,
          uid: null));
    } catch (e) {
      emit(state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: "Terjadi kesalahan: $e",
          uid: null));
    }
  }

  // 🔑 Register
  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, uid: null));

    try {
      final User? user = await _authService.register(
        event.email,
        event.password,
      );

      if (user != null) {
        emit(state.copyWith(
            isAuthenticated: true, uid: user.uid, isLoading: false));
      } else {
        emit(state.copyWith(
            isAuthenticated: false,
            isLoading: false,
            errorMessage: "Registrasi gagal",
            uid: null));
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = "Email sudah digunakan";
      } else if (e.code == 'weak-password') {
        message = "Password terlalu lemah";
      } else {
        message = "Error: ${e.message}";
      }

      emit(state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: message,
          uid: null));
    } catch (e) {
      emit(state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: "Terjadi kesalahan: $e",
          uid: null));
    }
  }

  // 🔑 Cek auto-login
  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    final user = _authService.currentUser;
    if (user != null) {
      emit(state.copyWith(isAuthenticated: true, uid: user.uid));
    } else {
      emit(state.copyWith(isAuthenticated: false, uid: null));
    }
  }

  // 🔑 Logout
  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _authService.logout();
    emit(state.copyWith(isAuthenticated: false, uid: null));
  }
}