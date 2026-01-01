import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_fruit/screens/auth/login_screen.dart';
import 'package:smart_fruit/screens/main/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables (expects a `.env` file at project root, listed in pubspec assets)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // OK if `.env` is missing; AIService will show a clear message.
  }
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFruit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Widget qui vérifie l'état d'authentification et redirige vers l'écran approprié
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Vérifier si l'utilisateur est connecté
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Afficher un écran de chargement pendant la vérification
          return const Scaffold(
      body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si l'utilisateur est connecté, afficher le menu principal
        if (snapshot.hasData && snapshot.data != null) {
          return const MainMenuScreen();
        }

        // Sinon, afficher l'écran de connexion
        return const LoginScreen();
      },
    );
  }
}
