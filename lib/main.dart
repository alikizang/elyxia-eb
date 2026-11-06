import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/main_layout_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du moteur SQL FFI pour Desktop (Windows, macOS, Linux)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ElyxiaEbApp());
}

class ElyxiaEbApp extends StatelessWidget {
  const ElyxiaEbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elyxia EB — Examen Blanc (Complexe Scolaire Les Victorieux)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayoutScreen(),
    );
  }
}
