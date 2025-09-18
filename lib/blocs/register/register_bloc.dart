import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_event.dart';
import 'register_state.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthService _authService = AuthService();

  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event, Emitter<RegisterState> emit) async {
    if (event.password != event.confirmPassword) {
      emit(RegisterFailure('Password dan konfirmasi tidak cocok.'));
      return;
    }

    emit(RegisterLoading());

    try {
      final User? user =
          await _authService.register(event.email, event.password);

      if (user != null) {
        // Opsional: simpan username di Firestore
        // await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        //   'username': event.username,
        //   'email': event.email,
        // });

        emit(RegisterSuccess());
      } else {
        emit(RegisterFailure('Registrasi gagal.'));
      }
    } catch (e) {
      emit(RegisterFailure('Terjadi kesalahan: $e'));
    }
  }
}
