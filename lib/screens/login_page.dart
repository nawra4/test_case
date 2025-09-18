import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import 'register_page.dart';
import 'home_page.dart';
import '../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.isAuthenticated != curr.isAuthenticated ||
              prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            if (state.isAuthenticated) {
              // Auto navigate ke HomeScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(Icons.book, size: 80, color: Colors.teal[700]),
                const SizedBox(height: 16),
                const Text(
                  'Login Jurnal Harian',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // Email
                CustomTextField(
                  hintText: 'Email',
                  controller: emailController,
                ),
                const SizedBox(height: 20),
                // Password
                CustomTextField(
                  hintText: 'Password',
                  isPassword: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 30),
                // Tombol Login
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                      LoginRequested(
                                        emailController.text,
                                        passwordController.text,
                                      ),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Masuk",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Teks Daftar
                RichText(
                  text: TextSpan(
                    text: "Belum punya akun? ",
                    style:
                        const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Daftar",
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
