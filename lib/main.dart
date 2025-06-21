import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'registration_page.dart';
import 'login_page.dart';
import 'loginFormateur.dart';

Future<void> main() async {
  // Set this to true to make zone errors fatal
  BindingBase.debugZoneErrorsAreFatal = true;
  
  // Ensure everything runs in the same zone
  runZonedGuarded(() async {
    // Initialiser les bindings Flutter
    WidgetsFlutterBinding.ensureInitialized();
    
    // Optimisations pour les appels vidéo
    if (kIsWeb) {
      // Configuration spécifique pour le web
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}');
      };
    } else {
      // Configuration pour les plateformes mobiles
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    }
    
    // Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Lancer l'application
    runApp(const SkillBridgeApp());
  }, (error, stack) {
    debugPrint('Caught error in runZonedGuarded: $error');
    debugPrint(stack.toString());
  });
}

class SkillBridgeApp extends StatelessWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        // Optimisations pour les appels vidéo
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: LoginScreen(), // Page par défaut
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationPage(),
        '/loginFormateur': (context) => LoginFormateur(),
      },
    );
  }
}
