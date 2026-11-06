import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final List<Exam> exams;
  final Exam? activeExam;
  final List<SchoolClass> classes;
  final VoidCallback onSettingsUpdated;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.exams,
    required this.activeExam,
    required this.classes,
    required this.onSettingsUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _subTitleCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _directorTitleCtrl;
  late TextEditingController _directorNameCtrl;
  late TextEditingController _juryPresidentCtrl;

  SchoolClass? _selectedClass;
  List<Subject> _classSubjects = [];
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _schoolNameCtrl = TextEditingController(text: widget.settings.schoolName);
    _subTitleCtrl = TextEditingController(text: widget.settings.schoolSubTitle);
    _addressCtrl = TextEditingController(text: widget.settings.schoolAddress);
    _phoneCtrl = TextEditingController(text: widget.settings.schoolPhone);
    _emailCtrl = TextEditingController(text: widget.settings.schoolEmail);
    _yearCtrl = TextEditingController(text: widget.settings.academicYear);
    _directorTitleCtrl = TextEditingController(text: widget.settings.directorTitle);
    _directorNameCtrl = TextEditingController(text: widget.settings.directorName);
    _juryPresidentCtrl = TextEditingController(text: widget.settings.juryPresidentTitle);

    if (widget.classes.isNotEmpty) {
      _selectedClass = widget.classes.first;
      _loadSubjects();
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameCtrl.dispose();
    _subTitleCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _yearCtrl.dispose();
    _directorTitleCtrl.dispose();
    _directorNameCtrl.dispose();
    _juryPresidentCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSchoolSettings() async {
    final updated = widget.settings.copyWith(
      schoolName: _schoolNameCtrl.text.trim(),
      schoolSubTitle: _subTitleCtrl.text.trim(),
      schoolAddress: _addressCtrl.text.trim(),
      schoolPhone: _phoneCtrl.text.trim(),
      schoolEmail: _emailCtrl.text.trim(),
      academicYear: _yearCtrl.text.trim(),
      directorTitle: _directorTitleCtrl.text.trim(),
      directorName: _directorNameCtrl.text.trim(),
      juryPresidentTitle: _juryPresidentCtrl.text.trim(),
    );

    await DatabaseHelper.instance.updateSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paramètres de l'établissement mis à jour avec succès !"),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSettingsUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Paramètres & Configuration",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Personnalisez l'établissement, les sessions d'examens blancs et les coefficients des matières",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.school_rounded, size: 18), text: "Établissement"),
                    Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: "Matières & Coefs"),
                    Tab(icon: Icon(Icons.event_note_rounded, size: 18), text: "Sessions d'Examens"),
                    Tab(icon: Icon(Icons.storage_rounded, size: 18), text: "Sauvegarde & SQL"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSchoolTab(),
                _buildSubjectsTab(),
                _buildExamsTab(),
                _buildDatabaseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolTab() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informations officielles de l'établissement",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              "Ces informations figureront sur l'en-tête de tous les relevés de notes A5 et procès-verbaux.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Divider(height: 32, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _schoolNameCtrl,
                    decoration: const InputDecoration(labelText: "Nom de l'établissement *"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _yearCtrl,
                    decoration: const InputDecoration(labelText: "Année Scolaire * (ex: 2025-2026)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subTitleCtrl,
              decoration: const InputDecoration(labelText: "Sous-titre / Description de l'établissement"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: "Adresse / Ville (ex: Lomé - TOGO)"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: "Numéros de Téléphone"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: AppColors.border),
            const Text(
              "Signataires officiels des relevés",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _directorTitleCtrl,
                    decoration: const InputDecoration(labelText: "Titre du Chef d'Établissement (ex: Le Proviseur)"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _directorNameCtrl,
                    decoration: const InputDecoration(labelText: "Nom ou mention du Chef d'Établissement"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _juryPresidentCtrl,
                    decoration: const InputDecoration(labelText: "Titre du Président du Jury"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveSchoolSettings,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text("Enregistrer les Modifications"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

  Widget _buildSubjectsTab() {
    double totalCoef = _classSubjects.fold(0.0, (prev, s) => prev + s.coefficient);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
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
                    const Text(
                      "Matières et Coefficients par Classe",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Sélectionnez une classe pour afficher ou ajuster ses matières et coefficients selon les normes du Togo.",
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
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
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
                onPressed: () => _showAddSubjectDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Ajouter Matière"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Coef Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Classe : ${_selectedClass?.name ?? ''} • Nombre de matières : ${_classSubjects.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  "TOTAL DES COEFFICIENTS : ${totalCoef.toInt()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
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
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final sub = _classSubjects[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                          child: Text(
                            "${sub.orderIndex}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Code: ${sub.code}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                "Coef : ${sub.coefficient.toInt()}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showEditSubjectDialog(context, sub),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              onPressed: () => _deleteSubject(sub),
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

  Widget _buildExamsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sessions d'Examens Blancs",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Créez vos sessions (Examen Blanc N°1, Examen Blanc N°2, etc.) et choisissez la session active",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddExamDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Nouvelle Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              itemCount: widget.exams.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final ex = widget.exams[index];
                final isActive = ex.id == widget.activeExam?.id;

                return ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isActive ? AppColors.success : AppColors.textMuted,
                  ),
                  title: Text(
                    ex.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? AppColors.primary : AppColors.textPrimary),
                  ),
                  subtitle: Text("Session : ${ex.sessionDate} • Année : ${ex.academicYear}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        OutlinedButton(
                          onPressed: () async {
                            // Désactiver les autres et activer celui-ci
                            for (final e in widget.exams) {
                              await DatabaseHelper.instance.updateExam(
                                Exam(
                                  id: e.id,
                                  title: e.title,
                                  sessionDate: e.sessionDate,
                                  academicYear: e.academicYear,
                                  isActive: e.id == ex.id,
                                ),
                              );
                            }
                            widget.onSettingsUpdated();
                          },
                          child: const Text("Définir comme actif"),
                        ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("Session Active", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
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

  void _showAddSubjectDialog(BuildContext context) {
    if (_selectedClass == null) return;
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final coefCtrl = TextEditingController(text: "2");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Ajouter une matière à ${_selectedClass!.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom de la matière *")),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code (ex: FRA, MATH) *")),
            const SizedBox(height: 12),
            TextField(controller: coefCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Coefficient *")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || coefCtrl.text.trim().isEmpty) return;
              final coef = double.tryParse(coefCtrl.text.trim()) ?? 1.0;
              await DatabaseHelper.instance.addSubject(
                Subject(
                  classId: _selectedClass!.id!,
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  coefficient: coef,
                  orderIndex: _classSubjects.length + 1,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSubjects();
              widget.onSettingsUpdated();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, Subject sub) {
    final nameCtrl = TextEditingController(text: sub.name);
    final codeCtrl = TextEditingController(text: sub.code);
    final coefCtrl = TextEditingController(text: sub.coefficient.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier la matière"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom de la matière")),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code")),
            const SizedBox(height: 12),
            TextField(controller: coefCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Coefficient")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final coef = double.tryParse(coefCtrl.text.trim()) ?? sub.coefficient;
              await DatabaseHelper.instance.updateSubject(
                sub.copyWith(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  coefficient: coef,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSubjects();
              widget.onSettingsUpdated();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(Subject sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer cette matière ?"),
        content: Text("Voulez-vous supprimer '${sub.name}' ? Toutes les notes associées dans cette classe seront supprimées."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (ok == true && sub.id != null) {
      await DatabaseHelper.instance.deleteSubject(sub.id!);
      _loadSubjects();
      widget.onSettingsUpdated();
    }
  }

  void _showAddExamDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: "Examen Blanc N°${widget.exams.length + 1}");
    final sessionCtrl = TextEditingController(text: "Mai 2026");
    final yearCtrl = TextEditingController(text: widget.settings.academicYear);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Créer une nouvelle session d'examen blanc"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Intitulé (ex: Examen Blanc N°2)")),
            const SizedBox(height: 12),
            TextField(controller: sessionCtrl, decoration: const InputDecoration(labelText: "Mois / Session (ex: Mai 2026)")),
            const SizedBox(height: 12),
            TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: "Année Scolaire")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await DatabaseHelper.instance.addExam(
                Exam(
                  title: titleCtrl.text.trim(),
                  sessionDate: sessionCtrl.text.trim(),
                  academicYear: yearCtrl.text.trim(),
                  isActive: true,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              widget.onSettingsUpdated();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET BASE DE DONNÉES & PORTABILITÉ SQL ====================
  Widget _buildDatabaseTab() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Portabilité & Sauvegarde SQL (Windows ↔ Mac)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              "La base de données est 100% hors ligne et stockée dans un fichier SQL standard. Vous pouvez l'exporter sur une clé USB et l'importer sur n'importe quel ordinateur Windows ou Mac pour continuer votre travail sans interruption.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Divider(height: 32, color: AppColors.border),

            _buildDbCard(
              title: "1. Exporter la Base de Données (.db)",
              description: "Sauvegarde complète de tous les élèves, classes, notes et sessions dans un fichier SQLite binaire (.db). Compatible Windows et macOS sans conversion.",
              icon: Icons.upload_file_rounded,
              buttonText: "Exporter la Base (.db)",
              buttonColor: AppColors.primary,
              onPressed: () => _exportDatabaseFile(context),
            ),

            const SizedBox(height: 16),

            _buildDbCard(
              title: "2. Importer / Restaurer une Base de Données (.db)",
              description: "Chargez un fichier de sauvegarde (.db) depuis une clé USB ou un disque. Vos données actuelles seront remplacées par celles du fichier importé.",
              icon: Icons.download_rounded,
              buttonText: "Importer la Base (.db)",
              buttonColor: AppColors.accent,
              isAccent: true,
              onPressed: () => _importDatabaseFile(context),
            ),

            const SizedBox(height: 16),

            _buildDbCard(
              title: "3. Exporter le Script SQL Brut (.sql)",
              description: "Génère un fichier texte SQL avec toutes les instructions (INSERT OR REPLACE) de vos tables pour consultation ou injection dans un autre SGBD.",
              icon: Icons.terminal_rounded,
              buttonText: "Exporter Script (.sql)",
              buttonColor: AppColors.info,
              onPressed: () => _exportSqlDump(context),
            ),

            const Divider(height: 32, color: AppColors.border),

            FutureBuilder<String>(
              future: DatabaseHelper.instance.getDatabasePath(),
              builder: (context, snapshot) {
                final path = snapshot.data ?? "...";
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Emplacement local du fichier SQL sur cette machine :", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(path, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDbCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
    bool isAccent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: buttonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: buttonColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: isAccent ? AppColors.primaryDark : Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDatabaseFile(BuildContext context) async {
    final bytes = await DatabaseHelper.instance.exportDatabaseBytes();
    final today = DateTime.now().toString().split(' ').first;
    final savedUri = await FilePicker.saveFile(
      dialogTitle: "Exporter la Base de Données (.db)",
      fileName: "elyxia_eb_backup_$today.db",
      bytes: Uint8List.fromList(bytes),
    );

    if (savedUri != null && mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Base de données exportée avec succès ! (${savedUri.path})"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importDatabaseFile(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Attention : Remplacement de la base de données"),
        content: const Text(
          "L'importation va remplacer les données locales actuelles par celles du fichier sélectionné.\n\nVoulez-vous continuer ?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.black87),
            child: const Text("Continuer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
    );

    if (picked.isNotEmpty && picked.first.path != null) {
      final file = File(picked.first.path!);
      final bytes = await file.readAsBytes();
      await DatabaseHelper.instance.importDatabaseBytes(bytes);

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Base de données importée et synchronisée avec succès !"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSettingsUpdated();
      }
    }
  }

  Future<void> _exportSqlDump(BuildContext context) async {
    final sql = await DatabaseHelper.instance.exportSqlScript();
    final today = DateTime.now().toString().split(' ').first;
    final savedUri = await FilePicker.saveFile(
      dialogTitle: "Exporter le Script SQL (.sql)",
      fileName: "elyxia_eb_dump_$today.sql",
      bytes: Uint8List.fromList(utf8.encode(sql)),
    );

    if (savedUri != null && mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Script SQL exporté avec succès ! (${savedUri.path})"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
