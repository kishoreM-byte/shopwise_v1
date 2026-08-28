import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ShopWiseApp());
}

class ShopWiseApp extends StatelessWidget {
  const ShopWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Global ShopWise premium theme
      theme: AppTheme.lightTheme,

      // Keep existing application entry point
      home: SplashScreen(),
    );
  }
}