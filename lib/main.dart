import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/home_tabs.dart';
import 'screens/onboarding.dart';

const bool kUseEmulators = true; // set false for production

Future<void> _connectToEmulators() async {
  if (!kUseEmulators) return;
  final host = kIsWeb ? '127.0.0.1' : 'localhost';
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _connectToEmulators(); // si tu utilises les émulateurs

  // initialise la locale française (ou système)
  await initializeDateFormatting('fr_FR', null);

  // initialise la locale système
  await initializeDateFormatting(ui.window.locale.toString(), null);

  runApp(const ProviderScope(child: SportMatchApp()));
}

class SportMatchApp extends StatelessWidget {
  const SportMatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportMatch',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system, // prépare le dark mode
      home: const OnboardingGate(),
    );
  }
}
