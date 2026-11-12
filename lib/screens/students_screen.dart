import 'dart:convert' show utf8;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/app_settings.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../services/csv_service.dart';
import '../services/excel_service.dart';
import '../services/file_service.dart';
import '../theme/app_colors.dart';

class StudentsScreen extends StatefulWidget {
  final AppSettings? settings;
  final SchoolClass schoolClass;
  final List<Student> students;
  final VoidCallback onStudentsChanged;
  final bool isReadOnly;
  final String academicYear;

  const StudentsScreen({
    super.key,
    this.settings,
    required this.schoolClass,
    required this.students,
    required this.onStudentsChanged,
    this.isReadOnly = false,
    this.academicYear = '2025-2026',
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.fromHex(widget.settings?.primaryColorHex);

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
          if (widget.isReadOnly) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Année Académique Clôturée (Mode Consultation)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade900),
                        ),
                        Text(
                          "La liste des élèves est verrouillée pour cette session. Les ajouts et modifications sont désactivés.",
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final actionButtons = <Widget>[
                  // Menu déroulant Modèle (Excel prioritaire / CSV)
                PopupMenuButton<String>(
                  tooltip: "Télécharger un modèle de fichier",
                  onSelected: (val) {
                    if (val == 'xlsx') {
                      _downloadXlsxTemplate(context);
                    } else if (val == 'csv') {
                      _downloadCsvTemplate(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'xlsx',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart_rounded, size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Modèle Excel (.xlsx)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Format recommandé par défaut", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Modèle Texte CSV (.csv)", style: TextStyle(fontSize: 13)),
                              Text("Format universel texte délimité", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: OutlinedButton.icon(
                    onPressed: null, // Délégué au PopupMenuButton
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Modèle Excel / CSV"),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AppColors.textSecondary,
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Menu déroulant Importer (Excel prioritaire / CSV)
                PopupMenuButton<String>(
                  tooltip: "Importer des candidats depuis un fichier",
                  enabled: !widget.isReadOnly,
                  onSelected: (val) {
                    if (val == 'xlsx') {
                      _importXlsx(context);
                    } else if (val == 'csv') {
                      _importCsv(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'xlsx',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart_rounded, size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Importer fichier Excel (.xlsx)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Lecture automatique des colonnes", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file_rounded, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Importer fichier CSV (.csv)", style: TextStyle(fontSize: 13)),
                              Text("Fichier avec virgule ou point-virgule", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: OutlinedButton.icon(
                    onPressed: null, // Délégué au PopupMenuButton
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Importer Élèves"),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: widget.isReadOnly ? AppColors.textMuted : primaryColor,
                      foregroundColor: primaryColor,
                      side: BorderSide(color: widget.isReadOnly ? AppColors.border : primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                // Bouton Importer depuis une autre Année
                OutlinedButton.icon(
                  onPressed: widget.isReadOnly ? null : () => _showImportFromPreviousYearDialog(context),
                  icon: const Icon(Icons.history_edu_rounded, size: 18),
                  label: const Text("Importer d'une Année"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                // Bouton Numéroter Automatiquement la Classe
                OutlinedButton.icon(
                  onPressed: widget.isReadOnly ? null : () => _showAutoRenumberDialog(context),
                  icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
                  label: const Text("Numéroter Automatiquement"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                  // Bouton Nouveau Candidat
                  ElevatedButton.icon(
                    onPressed: widget.isReadOnly ? null : () => _showAddEditStudentDialog(context),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text("Nouveau Candidat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ];

                final titleWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gestion des Candidats — ${widget.schoolClass.name}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Effectif : ${widget.students.length} inscrits • Importez un fichier Excel/CSV ou ajoutez manuellement",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actionButtons,
                    ),
                  ],
                );
              },
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double minTableWidth = 860;
                    final double tableWidth = math.max(constraints.maxWidth, minTableWidth);

                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          height: constraints.maxHeight,
                          child: Column(
                            children: [
                              // En-tête
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                ),
                    child: const Row(
                      children: [
                        SizedBox(width: 80, child: Text("N° TABLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 140, child: Text("MATRICULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 3, child: Text("NOM & PRÉNOMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 85, child: Text("SEXE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 24),
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
                                        student.matricule.isNotEmpty ? student.matricule : "—",
                                        style: TextStyle(
                                          color: student.matricule.isNotEmpty ? AppColors.textSecondary : AppColors.textMuted,
                                          fontSize: 12,
                                        ),
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
                                      width: 85,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: student.gender == 'F' ? primaryColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: student.gender == 'F' ? primaryColor.withValues(alpha: 0.35) : const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          child: Text(
                                            student.gender == 'F' ? 'Fille' : 'Garçon',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: student.gender == 'F' ? primaryColor : const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
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
                                            icon: Icon(Icons.edit_outlined, size: 18, color: primaryColor),
                                            tooltip: "Modifier",
                                            onPressed: widget.isReadOnly ? null : () => _showAddEditStudentDialog(context, student: student),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            tooltip: "Supprimer",
                                            onPressed: widget.isReadOnly ? null : () => _confirmDelete(context, student),
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
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportFromPreviousYearDialog(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final allYears = await db.getAcademicYears();
    final allClasses = await db.getClasses();

    if (allYears.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucune année scolaire trouvée.")),
        );
      }
      return;
    }

    final otherYears = allYears.where((y) => y.name != widget.academicYear).toList();
    String sourceYearName = otherYears.isNotEmpty ? otherYears.first.name : allYears.first.name;
    SchoolClass sourceClass = widget.schoolClass;

    List<Student> sourceStudents = await db.getStudentsForClass(sourceClass.id!, academicYear: sourceYearName);
    Set<int> selectedStudentIds = sourceStudents.where((s) => s.id != null).map((s) => s.id!).toSet();
    bool autoRenumber = true;
    bool isLoadingStudents = false;

    if (!context.mounted) return;

    final primaryColor = AppColors.fromHex(widget.settings?.primaryColorHex);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            void loadSourceStudents() async {
              setModalState(() => isLoadingStudents = true);
              final loaded = await db.getStudentsForClass(sourceClass.id!, academicYear: sourceYearName);
              setModalState(() {
                sourceStudents = loaded;
                selectedStudentIds = loaded.where((s) => s.id != null).map((s) => s.id!).toSet();
                isLoadingStudents = false;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history_edu_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Importer des Candidats d'une Autre Année",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Destination : ${widget.schoolClass.name} • Année ${widget.academicYear}",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 680,
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Année Scolaire Source :", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: sourceYearName,
                                      items: allYears.map((y) {
                                        return DropdownMenuItem<String>(
                                          value: y.name,
                                          child: Text(
                                            "${y.name} ${y.name == widget.academicYear ? '(Actuelle)' : ''}",
                                            style: TextStyle(
                                              fontWeight: y.name != widget.academicYear ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newYr) {
                                        if (newYr != null && newYr != sourceYearName) {
                                          sourceYearName = newYr;
                                          loadSourceStudents();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Classe Source :", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<SchoolClass>(
                                      isExpanded: true,
                                      value: sourceClass,
                                      items: allClasses.map((c) {
                                        return DropdownMenuItem<SchoolClass>(
                                          value: c,
                                          child: Text("${c.name} (${c.examType})", style: const TextStyle(fontSize: 12.5)),
                                        );
                                      }).toList(),
                                      onChanged: (newCls) {
                                        if (newCls != null && newCls.id != sourceClass.id) {
                                          sourceClass = newCls;
                                          loadSourceStudents();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: sourceStudents.isNotEmpty && selectedStudentIds.length == sourceStudents.length,
                          tristate: selectedStudentIds.isNotEmpty && selectedStudentIds.length < sourceStudents.length,
                          activeColor: primaryColor,
                          onChanged: sourceStudents.isEmpty ? null : (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedStudentIds = sourceStudents.where((s) => s.id != null).map((s) => s.id!).toSet();
                              } else {
                                selectedStudentIds.clear();
                              }
                            });
                          },
                        ),
                        Text(
                          "Sélection : ${selectedStudentIds.length} / ${sourceStudents.length} élèves",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setModalState(() => autoRenumber = !autoRenumber),
                          child: Row(
                            children: [
                              Checkbox(
                                value: autoRenumber,
                                activeColor: primaryColor,
                                onChanged: (v) => setModalState(() => autoRenumber = v ?? true),
                              ),
                              const Text("Réassigner des N° de table consécutifs", style: TextStyle(fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: isLoadingStudents
                          ? const Center(child: CircularProgressIndicator())
                          : sourceStudents.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_off_outlined, size: 36, color: AppColors.textMuted),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Aucun élève trouvé dans la classe ${sourceClass.name} pour l'année $sourceYearName.",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: sourceStudents.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                                  itemBuilder: (context, idx) {
                                    final s = sourceStudents[idx];
                                    final isSelected = selectedStudentIds.contains(s.id);
                                    return CheckboxListTile(
                                      value: isSelected,
                                      dense: true,
                                      activeColor: primaryColor,
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            selectedStudentIds.add(s.id!);
                                          } else {
                                            selectedStudentIds.remove(s.id);
                                          }
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSubtle,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text("N° ${s.tableNumber}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              s.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: s.gender == 'F' ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              s.gender == 'F' ? 'Fille' : 'Garçon',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: s.gender == 'F' ? primaryColor : const Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            s.matricule,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton.icon(
                  onPressed: selectedStudentIds.isEmpty
                      ? null
                      : () async {
                          final selectedStudents = sourceStudents.where((s) => selectedStudentIds.contains(s.id)).toList();
                          Navigator.pop(dialogCtx);

                          final count = await db.importStudentsFromPreviousYear(
                            students: selectedStudents,
                            targetClassId: widget.schoolClass.id!,
                            targetAcademicYear: widget.academicYear,
                            autoRenumber: autoRenumber,
                          );

                          widget.onStudentsChanged();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$count candidat(s) importé(s) avec succès pour l'année ${widget.academicYear} !"),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text("Importer la Sélection (${selectedStudentIds.length})"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAutoRenumberDialog(BuildContext context) async {
    final defaultStart = widget.students.isNotEmpty ? widget.students.first.tableNumber : "101";
    final startCtrl = TextEditingController(text: defaultStart);
    bool sortByAlpha = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.format_list_numbered_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text("Numéroter Automatiquement"),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigner automatiquement des numéros de table consécutifs aux ${widget.students.length} candidats de la classe ${widget.schoolClass.name}.",
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: startCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Numéro de table de départ *",
                    hintText: "Ex : 101",
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: sortByAlpha,
                  activeColor: AppColors.fromHex(widget.settings?.primaryColorHex),
                  title: const Text("Trier par ordre alphabétique (Nom & Prénoms)", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Convention officielle des examens nationaux au Togo", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  onChanged: (val) => setDlgState(() => sortByAlpha = val ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton.icon(
              onPressed: widget.students.isEmpty
                  ? null
                  : () async {
                      final start = int.tryParse(startCtrl.text.trim()) ?? 101;
                      Navigator.pop(ctx);
                      final count = await DatabaseHelper.instance.renumberStudentsForClass(
                        classId: widget.schoolClass.id!,
                        academicYear: widget.academicYear,
                        startNumber: start,
                        sortByAlphabetical: sortByAlpha,
                      );
                      widget.onStudentsChanged();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$count candidat(s) numéroté(s) consécutivement de $start à ${start + count - 1} !"),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text("Numéroter la Classe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fromHex(widget.settings?.primaryColorHex),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditStudentDialog(BuildContext context, {Student? student}) async {
    final isEdit = student != null;
    String defaultTable = student?.tableNumber ?? '';
    if (!isEdit) {
      defaultTable = await DatabaseHelper.instance.getNextTableNumber(
        widget.schoolClass.id!,
        academicYear: widget.academicYear,
      );
    }

    final matriculeCtrl = TextEditingController(text: student?.matricule ?? '');
    final tableCtrl = TextEditingController(text: defaultTable);
    final lastNameCtrl = TextEditingController(text: student?.lastName ?? '');
    final firstNameCtrl = TextEditingController(text: student?.firstName ?? '');
    String gender = student?.gender ?? 'M';
    bool isRepeater = student?.isRepeater ?? false;
    final birthDateCtrl = TextEditingController(text: student?.birthDate ?? '15/05/2007');
    final birthPlaceCtrl = TextEditingController(text: student?.birthPlace ?? 'Lomé');

    if (!context.mounted) return;

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
                          decoration: const InputDecoration(
                            labelText: "Matricule (Optionnel)",
                            hintText: "Laisser vide si aucun",
                          ),
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
                      Checkbox(
                        value: isRepeater,
                        onChanged: (val) => setDlgState(() => isRepeater = val ?? false),
                      ),
                      const Text(
                        "Élève doublant(e) / redoublant(e) (Relevé officiel)",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  isRepeater: isRepeater,
                  academicYear: widget.academicYear,
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
                backgroundColor: AppColors.fromHex(widget.settings?.primaryColorHex),
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

  Future<void> _importXlsx(BuildContext context) async {
    final picked = await FileService.pickFile(
      dialogTitle: "Sélectionnez le fichier Excel des candidats (.xlsx / .xls)",
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (picked != null) {
      int startTableNum = 101;
      if (widget.students.isNotEmpty) {
        final maxTable = widget.students
            .map((s) => int.tryParse(s.tableNumber) ?? 0)
            .fold<int>(0, (max, n) => n > max ? n : max);
        if (maxTable > 0) startTableNum = maxTable + 1;
      }

      final students = ExcelService.parseStudentsXlsx(
        picked.bytes,
        widget.schoolClass.id!,
        academicYear: widget.academicYear,
        startDefaultTableNumber: startTableNum,
      );

      if (students.isEmpty) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aucun candidat valide trouvé dans le fichier Excel. Vérifiez les colonnes (Nom, Prénoms, etc.)."),
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
            content: Text("${students.length} candidat(s) importé(s) avec succès depuis Excel pour l'année ${widget.academicYear} !"),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onStudentsChanged();
      }
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    final picked = await FileService.pickFile(
      dialogTitle: "Sélectionnez le fichier CSV des candidats (.csv / .txt)",
      allowedExtensions: ['csv', 'txt'],
    );

    if (picked != null) {
      final content = FileService.decodeTextBytes(picked.bytes);

      int startTableNum = 101;
      if (widget.students.isNotEmpty) {
        final maxTable = widget.students
            .map((s) => int.tryParse(s.tableNumber) ?? 0)
            .fold<int>(0, (max, n) => n > max ? n : max);
        if (maxTable > 0) startTableNum = maxTable + 1;
      }

      final students = CsvService.parseStudentsCsv(
        content,
        widget.schoolClass.id!,
        academicYear: widget.academicYear,
        startDefaultTableNumber: startTableNum,
      );

      if (students.isEmpty) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aucun candidat valide trouvé dans le fichier CSV. Vérifiez l'en-tête ou les données."),
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
            content: Text("${students.length} candidat(s) importé(s) avec succès depuis CSV pour l'année ${widget.academicYear} !"),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onStudentsChanged();
      }
    }
  }

  Future<void> _downloadXlsxTemplate(BuildContext context) async {
    final bytes = ExcelService.generateStudentsTemplateXlsx();
    final savedPath = await FileService.saveFile(
      dialogTitle: "Enregistrer le modèle Excel des candidats",
      fileName: "modele_candidats_elyxia.xlsx",
      bytes: bytes,
    );

    if (savedPath != null && mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Modèle Excel (.xlsx) enregistré avec succès : $savedPath"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _downloadCsvTemplate(BuildContext context) async {
    const template = "N° Table;Nom;Prénoms;Sexe;Date Naissance;Lieu Naissance;Matricule;Doublant\n"
        "101;KOUDOSSOU;Koffi Jean-Luc;M;14/05/2007;Lomé;VIC-2025-0101;NON\n"
        "102;ADJALLÉ;Afiwa Blandine;F;22/09/2007;Aného;;NON\n"
        "103;MENSAH;Kokou Mawunyo;M;03/01/2008;Kpalimé;;OUI\n";

    final savedPath = await FileService.saveFile(
      dialogTitle: "Enregistrer le modèle CSV des candidats",
      fileName: "modele_candidats_elyxia.csv",
      bytes: Uint8List.fromList(utf8.encode(template)),
    );

    if (savedPath != null && mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Modèle CSV (.csv) enregistré avec succès : $savedPath"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
