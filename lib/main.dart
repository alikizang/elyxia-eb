import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/database_helper.dart';
import 'models/academic_year.dart';
import 'models/app_settings.dart';
import 'models/app_user.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout_screen.dart';
import 'theme/app_colors.dart';
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

class ElyxiaEbApp extends StatefulWidget {
  const ElyxiaEbApp({super.key});

  @override
  State<ElyxiaEbApp> createState() => _ElyxiaEbAppState();
}

class _ElyxiaEbAppState extends State<ElyxiaEbApp> {
  AppUser? _currentUser;
  AcademicYear? _activeYear;
  AppSettings? _settings;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = DatabaseHelper.instance;
      final settings = await db.getSettings();
      final year = await db.getActiveAcademicYear();

      if (mounted) {
        setState(() {
          _settings = settings;
          _activeYear = year;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint("Erreur critique initialisation SQLite/Settings: $e\n$stack");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onLoginSuccess(AppUser user) async {
    final year = await DatabaseHelper.instance.getActiveAcademicYear();
    setState(() {
      _currentUser = user;
      _activeYear = year;
    });
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Chargement d'Elyxia EB...",
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 54),
                  const SizedBox(height: 16),
                  const Text(
                    "Erreur d'initialisation",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Une erreur est survenue lors de l'accès à la base de données locale :\n$_errorMessage",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadSettings,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Réessayer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final primary = AppColors.fromHex(_settings?.primaryColorHex);
    final accent = AppColors.fromHex(_settings?.accentColorHex);
    final theme = AppTheme.createTheme(primaryColor: primary, secondaryColor: accent);

    return MaterialApp(
      title: 'Elyxia EB — Examen Blanc',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: _currentUser == null
          ? LoginScreen(onLoginSuccess: _onLoginSuccess)
          : MainLayoutScreen(
              currentUser: _currentUser!,
              initialYear: _activeYear ?? AcademicYear(name: '2025-2026', isCurrent: true),
              onLogout: _onLogout,
              onThemeChanged: _loadSettings,
            ),
    );
  }
}
