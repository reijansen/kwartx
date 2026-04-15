import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const KwartXApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  } on FirebaseException catch (error) {
    debugPrint('Firebase initialization failed: ${error.message}');
  } catch (error) {
    debugPrint('Unexpected Firebase initialization error: $error');
  }
}

class KwartXApp extends StatelessWidget {
  const KwartXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KwartX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
