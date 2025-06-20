import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'registration_page.dart';
import 'login_page.dart';
import 'loginFormateur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkillBridgeApp());
}

class SkillBridgeApp extends StatelessWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Bridge',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Page par défaut
      routes: {
        '/login': (context) => LoginScreen(), // ✅ Route ajoutée ici
        '/register': (context) => RegistrationPage(),
        '/loginFormateur': (context) => LoginFormateur(),
      },
    );
  }
}
