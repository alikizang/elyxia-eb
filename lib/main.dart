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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
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
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
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
