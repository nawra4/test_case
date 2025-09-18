import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/custom_textfield.dart';
import 'login_page.dart';
import '../blocs/register/register_bloc.dart';
import '../blocs/register/register_event.dart';
import '../blocs/register/register_state.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterBloc(), // 🔥 tambahin provider
      child: const RegisterView(),   // ⬅️ isi lama dipindah ke sini
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed(BuildContext context) {
    context.read<RegisterBloc>().add(
          RegisterSubmitted(
            username: usernameController.text,
            email: emailController.text,
            password: passwordController.text,
            confirmPassword: confirmPasswordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Registrasi berhasil! Silakan login.')),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            } else if (state is RegisterFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is RegisterLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.person_add, size: 80, color: Colors.teal[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Daftar Akun',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  // Input fields
                  CustomTextField(
                      hintText: 'Username', controller: usernameController),
                  const SizedBox(height: 20),
                  CustomTextField(
                      hintText: 'Email', controller: emailController),
                  const SizedBox(height: 20),
                  CustomTextField(
                      hintText: 'Password',
                      isPassword: true,
                      controller: passwordController),
                  const SizedBox(height: 20),
                  CustomTextField(
                      hintText: 'Konfirmasi Password',
                      isPassword: true,
                      controller: confirmPasswordController),
                  const SizedBox(height: 30),

                  // Tombol Register
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal[700],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          isLoading ? null : () => _onRegisterPressed(context),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "Daftar",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      text: "Sudah punya akun? ",
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Masuk",
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
                                    builder: (_) => const LoginScreen()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
