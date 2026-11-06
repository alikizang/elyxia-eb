import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../data/database_helper.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../services/csv_service.dart';
import '../theme/app_colors.dart';

class StudentsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  final List<Student> students;
  final VoidCallback onStudentsChanged;

  const StudentsScreen({
    super.key,
    required this.schoolClass,
    required this.students,
    required this.onStudentsChanged,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students.where((s) {
      return s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.tableNumber.contains(_searchQuery) ||
          s.matricule.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête + Boutons d'Action
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gestion des Candidats — ${widget.schoolClass.name}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Effectif : ${widget.students.length} inscrits • Importez un fichier CSV ou ajoutez manuellement",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Bouton Modèle CSV
                OutlinedButton.icon(
                  onPressed: () => _downloadCsvTemplate(context),
                  icon: const Icon(Icons.file_copy_outlined, size: 18),
                  label: const Text("Modèle CSV"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton Importer CSV
                OutlinedButton.icon(
                  onPressed: () => _importCsv(context),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text("Importer CSV"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton Nouveau Candidat
                ElevatedButton.icon(
                  onPressed: () => _showAddEditStudentDialog(context),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text("Nouveau Candidat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barre de recherche
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher par nom, prénom, N° de table ou matricule...",
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Affichage : ${filtered.length} / ${widget.students.length} candidats",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liste des Candidats
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // En-tête
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(11),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 80, child: Text("N° TABLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 140, child: Text("MATRICULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 3, child: Text("NOM & PRÉNOMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 70, child: Text("SEXE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text("DATE & LIEU DE NAISSANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 100, child: Text("ACTIONS", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  ),

                  // Lignes
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text("Aucun candidat dans cette classe. Cliquez sur 'Nouveau Candidat' ou 'Importer CSV'."))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (context, index) {
                              final student = filtered[index];
                              return Container(
                                color: index % 2 == 1 ? AppColors.surfaceSubtle.withValues(alpha: 0.5) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        student.tableNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        student.matricule,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        student.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: student.gender == 'F' ? Colors.pink.shade50 : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          student.gender == 'F' ? 'Fille' : 'Garçon',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: student.gender == 'F' ? Colors.pink.shade700 : Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${student.birthDate.isNotEmpty ? student.birthDate : '-'} ${student.birthPlace.isNotEmpty ? 'à ${student.birthPlace}' : ''}",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                            tooltip: "Modifier",
                                            onPressed: () => _showAddEditStudentDialog(context, student: student),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            tooltip: "Supprimer",
                                            onPressed: () => _confirmDelete(context, student),
                                          ),
                                        ],
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
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditStudentDialog(BuildContext context, {Student? student}) {
    final isEdit = student != null;
    final matriculeCtrl = TextEditingController(text: student?.matricule ?? "VIC-2025-${(widget.students.length + 1).toString().padLeft(3, '0')}");
    final tableCtrl = TextEditingController(text: student?.tableNumber ?? (widget.students.length + 1).toString().padLeft(3, '0'));
    final lastNameCtrl = TextEditingController(text: student?.lastName ?? '');
    final firstNameCtrl = TextEditingController(text: student?.firstName ?? '');
    String gender = student?.gender ?? 'M';
    final birthDateCtrl = TextEditingController(text: student?.birthDate ?? '15/05/2007');
    final birthPlaceCtrl = TextEditingController(text: student?.birthPlace ?? 'Lomé');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(isEdit ? "Modifier Candidat" : "Nouveau Candidat"),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tableCtrl,
                          decoration: const InputDecoration(labelText: "N° de Table *"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: matriculeCtrl,
                          decoration: const InputDecoration(labelText: "Matricule *"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameCtrl,
                    decoration: const InputDecoration(labelText: "Nom de Famille *"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: firstNameCtrl,
                    decoration: const InputDecoration(labelText: "Prénoms *"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Sexe : "),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text("Masculin (M)"),
                        selected: gender == 'M',
                        onSelected: (val) {
                          if (val) setDlgState(() => gender = 'M');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Féminin (F)"),
                        selected: gender == 'F',
                        onSelected: (val) {
                          if (val) setDlgState(() => gender = 'F');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: birthDateCtrl,
                          decoration: const InputDecoration(labelText: "Date de Naissance (JJ/MM/AAAA)"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: birthPlaceCtrl,
                          decoration: const InputDecoration(labelText: "Lieu de Naissance"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (lastNameCtrl.text.trim().isEmpty || tableCtrl.text.trim().isEmpty) {
                  return;
                }

                final newStudent = Student(
                  id: student?.id,
                  classId: widget.schoolClass.id!,
                  matricule: matriculeCtrl.text.trim(),
                  tableNumber: tableCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  firstName: firstNameCtrl.text.trim(),
                  gender: gender,
                  birthDate: birthDateCtrl.text.trim(),
                  birthPlace: birthPlaceCtrl.text.trim(),
                );

                if (isEdit) {
                  await DatabaseHelper.instance.updateStudent(newStudent);
                } else {
                  await DatabaseHelper.instance.addStudent(newStudent);
                }

                if (context.mounted) {
                  Navigator.pop(ctx);
                  widget.onStudentsChanged();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? "Enregistrer" : "Ajouter"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Student student) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ce candidat ?"),
        content: Text("Voulez-vous vraiment supprimer ${student.fullName} ? Ses notes seront également effacées."),
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

    if (ok == true && student.id != null) {
      await DatabaseHelper.instance.deleteStudent(student.id!);
      widget.onStudentsChanged();
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final content = await file.readAsString();
      final students = CsvService.parseStudentsCsv(content, widget.schoolClass.id!);

      if (students.isEmpty) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aucun candidat valide trouvé dans le fichier CSV."),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      await DatabaseHelper.instance.addStudentsBatch(students);

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${students.length} candidats importés avec succès !"),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onStudentsChanged();
      }
    }
  }

  Future<void> _downloadCsvTemplate(BuildContext context) async {
    const template = "Matricule;N° Table;Nom;Prénoms;Sexe;Date Naissance;Lieu Naissance\n"
        "VIC-2025-001;001;KOUDOSSOU;Koffi Jean;M;12/04/2007;Lomé\n"
        "VIC-2025-002;002;ADJALLÉ;Afiwa Rose;F;23/09/2007;Aného\n";

    final savedUri = await FilePicker.saveFile(
      dialogTitle: "Enregistrer le modèle CSV",
      fileName: "modele_eleves_elyxia.csv",
      bytes: Uint8List.fromList(utf8.encode(template)),
    );

    if (savedUri != null) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Modèle CSV enregistré avec succès ! (${savedUri.path})"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
