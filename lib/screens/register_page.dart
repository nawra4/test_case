import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;

  void register() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.register(
        usernameController.text,
        emailController.text,
        passwordController.text,
      );
      setState(() => isLoading = false);

      if (result['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registrasi gagal')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(Icons.person_add, size: 80, color: Colors.teal[700]),
              const SizedBox(height: 16),
              const Text(
                'Daftar Akun',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Nama
              CustomTextField(
                hintText: 'Username',
                controller: usernameController,
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

              // Konfirmasi Password
              CustomTextField(
                hintText: 'Konfirmasi Password',
                isPassword: true,
                controller: confirmPasswordController,
              ),
              const SizedBox(height: 30),

              // Tombol Register
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoading ? null : register,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Daftar",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: Colors.white,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Teks Login
              RichText(
                text: TextSpan(
                  text: "Sudah punya akun? ",
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    TextSpan(
                      text: "Login",
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
        ),
      ),
    );
  }
}
