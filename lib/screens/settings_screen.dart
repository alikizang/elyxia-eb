import 'dart:convert' show base64Decode, base64Encode, utf8;
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/academic_year.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final List<AcademicYear> academicYears;
  final AcademicYear? activeYear;
  final List<Exam> exams;
  final Exam? activeExam;
  final List<SchoolClass> classes;
  final AppUser? currentUser;
  final VoidCallback onSettingsUpdated;
  final Function(AcademicYear) onYearChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.academicYears,
    required this.activeYear,
    required this.exams,
    required this.activeExam,
    required this.classes,
    required this.currentUser,
    required this.onSettingsUpdated,
    required this.onYearChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers Identité & Couleurs
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _subTitleCtrl;
  late TextEditingController _sloganCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _poBoxCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _directorTitleCtrl;
  late TextEditingController _directorNameCtrl;
  late TextEditingController _juryPresidentCtrl;
  late String _selectedPrimaryHex;
  late String _selectedAccentHex;
  String? _customLogoBase64;

  // Matières
  SchoolClass? _selectedClass;
  List<Subject> _classSubjects = [];
  bool _isLoadingSubjects = false;

  // Utilisateurs
  List<AppUser> _users = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _schoolNameCtrl = TextEditingController(text: widget.settings.schoolName);
    _subTitleCtrl = TextEditingController(text: widget.settings.schoolSubTitle);
    _sloganCtrl = TextEditingController(text: widget.settings.schoolSlogan);
    _addressCtrl = TextEditingController(text: widget.settings.schoolAddress);
    _poBoxCtrl = TextEditingController(text: widget.settings.schoolPoBox);
    _cityCtrl = TextEditingController(text: widget.settings.schoolCity);
    _phoneCtrl = TextEditingController(text: widget.settings.schoolPhone);
    _emailCtrl = TextEditingController(text: widget.settings.schoolEmail);
    _directorTitleCtrl = TextEditingController(text: widget.settings.directorTitle);
    _directorNameCtrl = TextEditingController(text: widget.settings.directorName);
    _juryPresidentCtrl = TextEditingController(text: widget.settings.juryPresidentTitle);
    _selectedPrimaryHex = widget.settings.primaryColorHex;
    _selectedAccentHex = widget.settings.accentColorHex;
    _customLogoBase64 = widget.settings.logoBase64;

    if (widget.classes.isNotEmpty) {
      _selectedClass = widget.classes.first;
      _loadSubjects();
    }
    _loadUsers();
  }

  Future<void> _loadSubjects() async {
    if (_selectedClass == null || _selectedClass!.id == null) return;
    setState(() => _isLoadingSubjects = true);
    final subs = await DatabaseHelper.instance.getSubjectsForClass(_selectedClass!.id!);
    if (mounted) {
      setState(() {
        _classSubjects = subs;
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final users = await DatabaseHelper.instance.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameCtrl.dispose();
    _subTitleCtrl.dispose();
    _sloganCtrl.dispose();
    _addressCtrl.dispose();
    _poBoxCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _directorTitleCtrl.dispose();
    _directorNameCtrl.dispose();
    _juryPresidentCtrl.dispose();
    super.dispose();
  }

  // ==================== SAUVEGARDE IDENTITÉ & COULEURS ====================
  Future<void> _saveIdentitySettings() async {
    final updated = widget.settings.copyWith(
      schoolName: _schoolNameCtrl.text.trim(),
      schoolSubTitle: _subTitleCtrl.text.trim(),
      schoolSlogan: _sloganCtrl.text.trim(),
      schoolAddress: _addressCtrl.text.trim(),
      schoolPoBox: _poBoxCtrl.text.trim(),
      schoolCity: _cityCtrl.text.trim(),
      schoolPhone: _phoneCtrl.text.trim(),
      schoolEmail: _emailCtrl.text.trim(),
      directorTitle: _directorTitleCtrl.text.trim(),
      directorName: _directorNameCtrl.text.trim(),
      juryPresidentTitle: _juryPresidentCtrl.text.trim(),
      primaryColorHex: _selectedPrimaryHex,
      accentColorHex: _selectedAccentHex,
      logoBase64: _customLogoBase64,
    );

    await DatabaseHelper.instance.updateSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paramètres et charte graphique enregistrés avec succès !"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSettingsUpdated();
    }
  }

  Future<void> _pickSchoolLogo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final bytes = await File(result.first.path!).readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _customLogoBase64 = base64String;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nouveau logo sélectionné ! N'oubliez pas d'enregistrer."),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetSchoolLogo() {
    setState(() {
      _customLogoBase64 = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logo réinitialisé au logo officiel du Complexe."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.fromHex(_selectedPrimaryHex);
    final accentColor = AppColors.fromHex(_selectedAccentHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre & Sous-titre
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Configuration & Personnalisation Générale",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Personnalisez l'identité de l'établissement, les couleurs, les années académiques, les matières et la sauvegarde SQL.",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Onglets de configuration
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: primaryColor,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.palette_outlined, size: 18), text: "Identité & Couleurs"),
                  Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: "Années Académiques"),
                  Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: "Matières & Coefs"),
                  Tab(icon: Icon(Icons.event_note_outlined, size: 18), text: "Sessions d'Examens"),
                  Tab(icon: Icon(Icons.security_outlined, size: 18), text: "Utilisateurs & Accès"),
                  Tab(icon: Icon(Icons.storage_outlined, size: 18), text: "Sauvegarde & Portabilité SQL"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIdentityAndColorsTab(primaryColor, accentColor),
                  _buildAcademicYearsTab(primaryColor, accentColor),
                  _buildSubjectsTab(primaryColor),
                  _buildExamsTab(primaryColor),
                  _buildUsersTab(primaryColor),
                  _buildDatabasePortabilityTab(primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ONGLET 1 : IDENTITÉ & COULEURS ====================
  Widget _buildIdentityAndColorsTab(Color primaryColor, Color accentColor) {
    // Palettes de couleurs prédéfinies
    final primaryPresets = [
      {'name': 'Bleu Elyxia', 'hex': '#22577A'},
      {'name': 'Bleu Marine', 'hex': '#0F172A'},
      {'name': 'Bleu Nuit', 'hex': '#1E3A8A'},
      {'name': 'Vert Forêt', 'hex': '#065F46'},
      {'name': 'Bordeaux', 'hex': '#881337'},
      {'name': 'Violet Impérial', 'hex': '#581C87'},
    ];

    final accentPresets = [
      {'name': 'Blanc Pur', 'hex': '#FFFFFF'},
      {'name': 'Blanc Ivoire', 'hex': '#F8FAFC'},
      {'name': 'Émeraude', 'hex': '#3BCC97'},
      {'name': 'Vert Menthe', 'hex': '#10B981'},
      {'name': 'Or / Ambre', 'hex': '#F59E0B'},
      {'name': 'Jaune Soleil', 'hex': '#FACC15'},
      {'name': 'Cyan Océan', 'hex': '#0284C7'},
      {'name': 'Bleu Ciel', 'hex': '#38BDF8'},
      {'name': 'Corail', 'hex': '#E11D48'},
      {'name': 'Rose Fuchsia', 'hex': '#EC4899'},
      {'name': 'Violet', 'hex': '#A855F7'},
    ];

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 : Logo & Couleurs
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo de l'établissement
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Logo de l'Établissement",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: primaryColor, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: ClipOval(
                        child: _customLogoBase64 != null
                            ? Image.memory(base64Decode(_customLogoBase64!), fit: BoxFit.contain)
                            : Image.asset('assets/images/school_logo_default.jpg', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickSchoolLogo,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text("Changer le logo", style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    if (_customLogoBase64 != null) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _resetSchoolLogo,
                        child: const Text("Logo par défaut", style: TextStyle(fontSize: 11, color: Colors.red)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 32),

                // Palette de Couleurs
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Couleur Principale de l'Application & des Relevés",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: primaryPresets.map((p) {
                          final isSelected = _selectedPrimaryHex == p['hex'];
                          final c = AppColors.fromHex(p['hex']!);
                          return InkWell(
                            onTap: () => setState(() => _selectedPrimaryHex = p['hex']!),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                boxShadow: isSelected
                                    ? [const BoxShadow(color: Colors.black45, blurRadius: 6)]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) const Icon(Icons.check, size: 14, color: Colors.white),
                                  if (isSelected) const SizedBox(width: 4),
                                  Text(
                                    p['name']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Couleur d'Accentuation (Badges, Mentions, Surlignages)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: accentPresets.map((p) {
                          final isSelected = _selectedAccentHex == p['hex'];
                          final c = AppColors.fromHex(p['hex']!);
                          final isLight = c.computeLuminance() > 0.65;
                          final contentColor = isLight ? Colors.black87 : Colors.white;

                          return InkWell(
                            onTap: () => setState(() => _selectedAccentHex = p['hex']!),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : (isLight ? Colors.grey.shade400 : Colors.transparent),
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) Icon(Icons.check, size: 14, color: contentColor),
                                  if (isSelected) const SizedBox(width: 4),
                                  Text(
                                    p['name']!,
                                    style: TextStyle(
                                      color: contentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            // Section 2 : Coordonnées de l'Établissement
            const Text(
              "Informations Officielles de l'Établissement",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormField(
                    label: "Nom de l'Établissement",
                    controller: _schoolNameCtrl,
                    hint: "COMPLEXE SCOLAIRE LES VICTORIEUX",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildFormField(
                    label: "Devise / Slogan",
                    controller: _sloganCtrl,
                    hint: "Discipline - Travail - Succès",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: "Adresse & Localisation",
                    controller: _addressCtrl,
                    hint: "Zopomahé, Sanguéra",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    label: "Boîte Postale & Ville",
                    controller: _poBoxCtrl,
                    hint: "23 BP 124 Lomé-TOGO",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    label: "Téléphone(s)",
                    controller: _phoneCtrl,
                    hint: "+228 90 41 07 07 / 90 12 34 56",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: "Titre du Directeur / Proviseur",
                    controller: _directorTitleCtrl,
                    hint: "Le Chef d'Établissement",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    label: "Nom & Prénoms du Directeur",
                    controller: _directorNameCtrl,
                    hint: "Direction Générale",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    label: "Titre du Président du Jury",
                    controller: _juryPresidentCtrl,
                    hint: "Le Président du Jury",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveIdentitySettings,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text("Enregistrer les Paramètres et Couleurs"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ONGLET 2 : ANNÉES ACADÉMIQUES ====================
  Widget _buildAcademicYearsTab(Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion & Clôture des Années Académiques",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Définissez librement les années scolaires, changez l'année active ou clôturez une année pour verrouiller les données.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddAcademicYearDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Nouvelle Année"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: widget.academicYears.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final yr = widget.academicYears[index];
                final isCurrent = yr.id == widget.activeYear?.id;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrent ? primaryColor.withValues(alpha: 0.05) : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent ? primaryColor : AppColors.border,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        yr.isClosed ? Icons.lock : Icons.school,
                        color: yr.isClosed ? Colors.red : (isCurrent ? primaryColor : Colors.grey),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  yr.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 10),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "ANNÉE EN COURS",
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                    ),
                                  ),
                                if (yr.isClosed) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "CLÔTURÉE (LECTURE SEULE)",
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (yr.notes != null && yr.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(yr.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ),

                      // Actions
                      if (!isCurrent)
                        OutlinedButton(
                          onPressed: () async {
                            await DatabaseHelper.instance.setCurrentAcademicYear(yr.id!);
                            widget.onYearChanged(yr);
                            widget.onSettingsUpdated();
                          },
                          child: const Text("Définir active", style: TextStyle(fontSize: 11)),
                        ),
                      const SizedBox(width: 10),

                      // Bouton Clôturer / Rouvrir
                      if (!yr.isClosed)
                        ElevatedButton.icon(
                          onPressed: () => _confirmCloseAcademicYear(yr),
                          icon: const Icon(Icons.lock_outline, size: 14),
                          label: const Text("Clôturer l'année", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _confirmReopenAcademicYear(yr),
                          icon: const Icon(Icons.lock_open, size: 14),
                          label: const Text("Rouvrir", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAcademicYearDialog() {
    final nameCtrl = TextEditingController(text: '2026-2027');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvelle Année Académique"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Libellé de l'année (ex: 2026-2027)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: "Notes ou observations (optionnel)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newYr = AcademicYear(name: name, notes: notesCtrl.text.trim());
                await DatabaseHelper.instance.addAcademicYear(newYr);
                if (mounted) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onSettingsUpdated();
                }
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  void _confirmCloseAcademicYear(AcademicYear yr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Clôturer l'année ${yr.name} ?"),
        content: const Text(
          "Attention : La clôture verrouille définitivement l'année en mode lecture seule.\n"
          "Les enseignants et administrateurs ne pourront plus ajouter, modifier ou supprimer d'élèves ou de notes pour cette session.\n\n"
          "Confirmez-vous la clôture officielle ?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.toggleCloseAcademicYear(yr.id!, true);
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                widget.onSettingsUpdated();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Oui, Clôturer l'Année"),
          ),
        ],
      ),
    );
  }

  void _confirmReopenAcademicYear(AcademicYear yr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Rouvrir l'année ${yr.name} ?"),
        content: const Text(
          "La réouverture autorisera à nouveau les modifications sur les notes et les candidats de cette année.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.toggleCloseAcademicYear(yr.id!, false);
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                widget.onSettingsUpdated();
              }
            },
            child: const Text("Rouvrir"),
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET 3 : MATIÈRES & COEFS ====================
  Widget _buildSubjectsTab(Color primaryColor) {
    double totalCoef = _classSubjects.fold(0.0, (prev, s) => prev + s.coefficient);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Matières et Coefficients par Classe",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Sélectionnez une classe pour ajuster ses matières, coefficients et professeurs.",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Sélecteur de classe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SchoolClass>(
                    value: _selectedClass,
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    items: widget.classes.map((c) {
                      return DropdownMenuItem<SchoolClass>(
                        value: c,
                        child: Text("${c.name} (${c.examType})"),
                      );
                    }).toList(),
                    onChanged: (newC) {
                      if (newC != null) {
                        setState(() => _selectedClass = newC);
                        _loadSubjects();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Ajouter une matière"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total coef bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Classe : ${_selectedClass?.name ?? ''} (Série ${_selectedClass?.series ?? ''})",
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                ),
                Text(
                  "Total Coefficients : ${totalCoef.toStringAsFixed(1)}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoadingSubjects
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _classSubjects.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sub = _classSubjects[index];
                      return ListTile(
                        dense: true,
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "Code: ${sub.code} • Professeur: ${sub.teacherName.isNotEmpty ? sub.teacherName : 'Non assigné'}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Coef. ${sub.coefficient.toStringAsFixed(1)}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _showEditSubjectDialog(sub),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog() {
    if (_selectedClass == null || _selectedClass!.id == null) return;
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final coefCtrl = TextEditingController(text: "2.0");
    final teacherCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ajouter une matière"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom de la matière")),
            const SizedBox(height: 10),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code court (ex: MATH)")),
            const SizedBox(height: 10),
            TextField(controller: coefCtrl, decoration: const InputDecoration(labelText: "Coefficient")),
            const SizedBox(height: 10),
            TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: "Nom du Professeur")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final coef = double.tryParse(coefCtrl.text.replaceAll(',', '.')) ?? 1.0;
              final newSub = Subject(
                classId: _selectedClass!.id!,
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim().toUpperCase(),
                coefficient: coef,
                orderIndex: _classSubjects.length + 1,
                teacherName: teacherCtrl.text.trim(),
              );
              await DatabaseHelper.instance.addSubject(newSub);
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                _loadSubjects();
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(Subject sub) {
    final nameCtrl = TextEditingController(text: sub.name);
    final codeCtrl = TextEditingController(text: sub.code);
    final coefCtrl = TextEditingController(text: sub.coefficient.toStringAsFixed(1));
    final teacherCtrl = TextEditingController(text: sub.teacherName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Modifier '${sub.name}'"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom de la matière")),
            const SizedBox(height: 10),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code court")),
            const SizedBox(height: 10),
            TextField(controller: coefCtrl, decoration: const InputDecoration(labelText: "Coefficient")),
            const SizedBox(height: 10),
            TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: "Nom du Professeur")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final coef = double.tryParse(coefCtrl.text.replaceAll(',', '.')) ?? sub.coefficient;
              final updated = sub.copyWith(
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim().toUpperCase(),
                coefficient: coef,
                teacherName: teacherCtrl.text.trim(),
              );
              await DatabaseHelper.instance.updateSubject(updated);
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                _loadSubjects();
              }
            },
            child: const Text("Mettre à jour"),
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET 4 : SESSIONS D'EXAMENS ====================
  Widget _buildExamsTab(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sessions d'Examens Blancs",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              ElevatedButton.icon(
                onPressed: _showAddExamDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Nouvelle session"),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: widget.exams.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ex = widget.exams[index];
                final isActive = ex.id == widget.activeExam?.id;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Session: ${ex.sessionDate} • Année: ${ex.academicYear}"),
                  trailing: isActive
                      ? const Chip(label: Text("Active", style: TextStyle(fontSize: 10)))
                      : OutlinedButton(
                          onPressed: () async {
                            final updated = ex.copyWith(isActive: true);
                            await DatabaseHelper.instance.updateExam(updated);
                            widget.onSettingsUpdated();
                          },
                          child: const Text("Activer"),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog() {
    final titleCtrl = TextEditingController(text: "Examen Blanc Régional N°2");
    final dateCtrl = TextEditingController(text: "Avril 2026");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvelle Session d'Examen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Intitulé de l'examen")),
            const SizedBox(height: 10),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Période / Date (ex: Avril 2026)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final newEx = Exam(
                title: titleCtrl.text.trim(),
                sessionDate: dateCtrl.text.trim(),
                academicYear: widget.settings.academicYear,
                isActive: true,
              );
              await DatabaseHelper.instance.addExam(newEx);
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                widget.onSettingsUpdated();
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET 5 : UTILISATEURS & ACCÈS ====================
  Widget _buildUsersTab(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion des Accès & Comptes Locaux",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Gérez les identifiants d'accès pour les enseignants et la direction.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text("Ajouter un compte"),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Text(
                            u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text("${u.fullName} (${u.username})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Rôle : ${u.roleLabel}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showChangePasswordDialog(u),
                              icon: const Icon(Icons.key, size: 14),
                              label: const Text("Changer MDP", style: TextStyle(fontSize: 11)),
                            ),
                            if (u.username != 'admin') ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _confirmDeleteUser(u),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'teacher';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text("Ajouter un Compte Utilisateur"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom complet")),
              const SizedBox(height: 10),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Identifiant de connexion")),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Mot de passe")),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: "Rôle"),
                items: const [
                  DropdownMenuItem(value: 'teacher', child: Text("Enseignant / Saisie")),
                  DropdownMenuItem(value: 'admin', child: Text("Administrateur")),
                  DropdownMenuItem(value: 'secretary', child: Text("Secrétariat")),
                ],
                onChanged: (val) {
                  if (val != null) setDState(() => role = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final username = userCtrl.text.trim();
                final password = passCtrl.text;
                final fullName = nameCtrl.text.trim();
                if (username.isNotEmpty && password.isNotEmpty) {
                  final newUser = AppUser(
                    username: username,
                    password: password,
                    fullName: fullName.isNotEmpty ? fullName : username,
                    role: role,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  await DatabaseHelper.instance.addUser(newUser);
                  if (mounted) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadUsers();
                  }
                }
              },
              child: const Text("Créer"),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(AppUser user) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Changer le mot de passe de '${user.username}'"),
        content: TextField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.isNotEmpty && user.id != null) {
                await DatabaseHelper.instance.updatePassword(user.id!, passCtrl.text);
                if (mounted) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mot de passe mis à jour avec succès !"), backgroundColor: AppColors.success),
                    );
                  }
                  _loadUsers();
                }
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Supprimer l'utilisateur '${user.username}' ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (user.id != null) {
                await DatabaseHelper.instance.deleteUser(user.id!);
                if (mounted) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadUsers();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET 6 : SAUVEGARDE & PORTABILITÉ SQL ====================
  Widget _buildDatabasePortabilityTab(Color primaryColor) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.save_alt, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sauvegarde & Portabilité SQL Complète (Windows <-> macOS)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Exportez votre base sur clé USB et ouvrez-la sur n'importe quel ordinateur Windows ou Mac sans connexion Internet.",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cartes d'action
            Row(
              children: [
                // Export .db
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.file_download_outlined,
                    iconColor: primaryColor,
                    title: "Exporter la Base Complète (.db)",
                    desc: "Sauvegarde intégrale autonome prête à être transférée par clé USB vers un autre PC.",
                    buttonText: "Exporter .db",
                    onPressed: _exportDatabase,
                  ),
                ),
                const SizedBox(width: 20),

                // Import .db
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.file_upload_outlined,
                    iconColor: AppColors.accent,
                    title: "Importer une Base (.db)",
                    desc: "Restaure immédiatement l'ensemble des données, couleurs, logos, années et notes.",
                    buttonText: "Importer .db",
                    onPressed: _importDatabase,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                // Export .sql
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.code,
                    iconColor: Colors.blue.shade700,
                    title: "Exporter en Script SQL (.sql)",
                    desc: "Fichier texte SQL universel lisible contenant toutes les requêtes INSERT OR REPLACE.",
                    buttonText: "Exporter .sql",
                    onPressed: _exportSql,
                  ),
                ),
                const SizedBox(width: 20),

                // Informations
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text("100% Hors-Ligne & Zéro Perte", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "La base SQLite est nativement binaire-compatible entre Windows et macOS. Le logo de l'établissement et les couleurs personnalisées voyagent automatiquement avec le fichier .db.",
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDatabase() async {
    try {
      final bytes = await DatabaseHelper.instance.exportDatabaseBytes();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final defaultName = "elyxia_eb_backup_$dateStr.db";

      final path = await FilePicker.saveFile(
        dialogTitle: "Enregistrer la sauvegarde SQLite (.db)",
        fileName: defaultName,
        bytes: Uint8List.fromList(bytes),
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Base de données exportée avec succès : $path"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'export : $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _importDatabase() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: "Sélectionnez le fichier de sauvegarde SQLite (.db)",
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        final bytes = await File(result.first.path!).readAsBytes();
        await DatabaseHelper.instance.importDatabaseBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Base restaurée avec succès ! Rechargement des données..."),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onSettingsUpdated();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'import : $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportSql() async {
    try {
      final sqlScript = await DatabaseHelper.instance.exportSqlScript();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final defaultName = "elyxia_eb_script_$dateStr.sql";

      final path = await FilePicker.saveFile(
        dialogTitle: "Enregistrer le script SQL (.sql)",
        fileName: defaultName,
        bytes: Uint8List.fromList(utf8.encode(sqlScript)),
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Script SQL exporté avec succès : $path"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
