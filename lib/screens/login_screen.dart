import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final Function(AppUser user) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDefaultAdminPassword = false;

  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final settings = await db.getSettings();
    final defaultAdmin = await db.authenticate('admin', 'admin123');

    if (mounted) {
      setState(() {
        _settings = settings;
        _isDefaultAdminPassword = (defaultAdmin != null);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Veuillez saisir votre nom d'utilisateur et mot de passe.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = DatabaseHelper.instance;
    final user = await db.authenticate(username, password);

    if (user != null) {
      widget.onLoginSuccess(user);
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Identifiants incorrects. Veuillez réessayer.";
        });
      }
    }
  }

  Widget _buildSchoolLogo() {
    if (_settings?.logoBase64 != null && _settings!.logoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_settings!.logoBase64!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }
    return Image.asset('assets/images/school_logo_default.jpg', fit: BoxFit.contain);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.fromHex(_settings?.primaryColorHex);
    final accentColor = AppColors.fromHex(_settings?.accentColorHex);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(primaryColor, const Color(0xFF020617), 0.72)!,
              Color.lerp(primaryColor, const Color(0xFF0F172A), 0.85)!,
              const Color(0xFF020617),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Carte de connexion
                Container(
                  width: 440,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 28,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo de l'établissement
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(child: _buildSchoolLogo()),
                    ),
                    const SizedBox(height: 16),

                    // Nom de l'établissement
                    Text(
                      _settings?.schoolName ?? "COMPLEXE SCOLAIRE LES VICTORIEUX",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _settings?.schoolSlogan ?? "Discipline - Travail - Succès",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Badge Examen Blanc
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        "GESTION DES EXAMENS BLANCS",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Champ Utilisateur
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Nom d'utilisateur",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        hintText: "admin",
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: 14),

                    // Champ Mot de passe
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Mot de passe",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        hintText: "••••••••",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bouton de connexion
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Se Connecter",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    if (_isDefaultAdminPassword) ...[
                      const SizedBox(height: 18),
                      // Aide / Rappel des identifiants initiaux (masqué dès que le mot de passe est changé)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Accès initial : admin  /  admin123 (Modifiable dans les Paramètres)",
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mention de sécurité
              const Text(
                "Fonctionnement 100% autonome et hors-ligne • Données sécurisées localement",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
