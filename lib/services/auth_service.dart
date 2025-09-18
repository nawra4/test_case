import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // 🔑 Login
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // lempar biar Bloc yang handle pesan error
      throw e;
    } catch (e) {
      throw Exception("Login gagal: $e");
    }
  }

  // 🆕 Register
  Future<User?> register(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Registrasi gagal: $e");
    }
  }

  // 🚪 Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // 👤 User aktif (auto-login)
  User? get currentUser => _firebaseAuth.currentUser;
}
