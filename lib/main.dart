import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:journal_mobile_api/screens/home_page.dart';
import 'package:journal_mobile_api/screens/login_page.dart';
import 'services/auth_storage_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/journal/journal_bloc.dart';
import 'blocs/register/register_bloc.dart';
import 'services/api_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final apiService = ApiService();

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  const MyApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (_) => JournalBloc(apiService: apiService),
        ),
        BlocProvider(
          create: (_) => RegisterBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Journal App',
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}