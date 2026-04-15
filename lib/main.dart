import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

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

  static const Color _primaryColor = Color(0xFF22C55E);
  static const Color _backgroundColor = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _primaryColor,
      surface: _backgroundColor,
    );

    return MaterialApp(
      title: 'KwartX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _backgroundColor,
      ),
      home: const KwartXPlaceholderScreen(),
    );
  }
}

class KwartXPlaceholderScreen extends StatelessWidget {
  const KwartXPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('KwartX')));
  }
}
