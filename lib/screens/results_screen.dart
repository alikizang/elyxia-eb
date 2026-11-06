import 'dart:convert' show utf8;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/student_result.dart';
import '../models/subject.dart';
import '../services/calculation_service.dart';
import '../services/csv_service.dart';
import '../theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  final AppSettings? settings;
  final Exam exam;
  final SchoolClass schoolClass;
  final List<Subject> subjects;
  final List<StudentResult> results;
  final Function(StudentResult) onPreviewSingleStudent;
  final VoidCallback onPreviewAllStudentsA5;
  final VoidCallback onPreviewPvA4;

  const ResultsScreen({
    super.key,
    required this.settings,
    required this.exam,
    required this.schoolClass,
    required this.subjects,
    required this.results,
    required this.onPreviewSingleStudent,
    required this.onPreviewAllStudentsA5,
    required this.onPreviewPvA4,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _searchQuery = '';
  String _filterDecision = 'ALL'; // ALL, ADMIS, AJOURNE

  @override
  Widget build(BuildContext context) {
    final stats = CalculationService.computeStatistics(widget.results);
    final primaryColor = AppColors.fromHex(widget.settings?.primaryColorHex);
    final accentColor = AppColors.fromHex(widget.settings?.accentColorHex);
    final isAccentLight = accentColor.computeLuminance() > 0.65;
    final accentTextColor = isAccentLight ? Colors.black87 : Colors.white;

    // Filtrage
    final filtered = widget.results.where((r) {
      final matchesSearch = r.student.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.student.tableNumber.contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_filterDecision == 'ADMIS') return r.isAdmitted;
      if (_filterDecision == 'AJOURNE') return !r.isAdmitted;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête + Boutons d'export & impression
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
                        "Résultats & Classement — ${widget.schoolClass.name} (${widget.schoolClass.examType})",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.exam.title} • Délibération officielle de la session de ${widget.exam.sessionDate}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Bouton Exporter CSV
                OutlinedButton.icon(
                  onPressed: () => _exportCsv(context),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text("Exporter CSV"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton PV A4
                ElevatedButton.icon(
                  onPressed: widget.onPreviewPvA4,
                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                  label: const Text("Procès-Verbal (PV A4)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton Relevés A5 par lot
                ElevatedButton.icon(
                  onPressed: widget.onPreviewAllStudentsA5,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text("Imprimer Tous les Relevés A5"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: accentTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barre de synthèse et filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Champ de recherche
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher par nom ou numéro de table...",
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
                // Filtre Admis / Ajourné
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ALL', label: Text("Tous")),
                    ButtonSegment(value: 'ADMIS', label: Text("Admis")),
                    ButtonSegment(value: 'AJOURNE', label: Text("Ajournés")),
                  ],
                  selected: {_filterDecision},
                  onSelectionChanged: (val) {
                    setState(() => _filterDecision = val.first);
                  },
                ),
                const Spacer(),
                Text(
                  "Taux de Réussite : ${stats.successRate} % (${stats.admittedCount}/${stats.totalStudents})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: stats.successRate >= 50 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tableau complet des délibérations avec défilement horizontal fluide
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
                    final double minTableWidth = 50 + 65 + 230 + 45 + (widget.subjects.length * 62.0) + 80 + 80 + 90 + 80 + 90 + 32;
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
                              // En-tête du tableau
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 50, child: Text("RANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    const SizedBox(width: 65, child: Text("N° TABLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    const SizedBox(
                                      width: 230,
                                      child: Text(
                                        "NOM & PRÉNOMS",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 45, child: Text("SEXE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    ...widget.subjects.map(
                                      (sub) => SizedBox(
                                        width: 62,
                                        child: Text(
                                          "${sub.code}\n(${sub.coefficient.toInt()})",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 80, child: Text("TOTAL PTS", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    const SizedBox(width: 80, child: Text("MOYENNE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    const SizedBox(width: 90, child: Text("DÉCISION", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    const SizedBox(width: 80, child: Text("MENTION", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                    const SizedBox(width: 90, child: Text("ACTION", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                  ],
                                ),
                              ),

                              // Lignes des élèves
                              Expanded(
                                child: filtered.isEmpty
                                    ? const Center(child: Text("Aucun candidat trouvé."))
                                    : ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                                        itemBuilder: (context, index) {
                                          final r = filtered[index];
                                          return Container(
                                            color: index % 2 == 1 ? AppColors.surfaceSubtle.withValues(alpha: 0.5) : Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  child: Text(
                                                    r.rankFormatted,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: r.rank <= 3 ? primaryColor : AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 65,
                                                  child: Text(
                                                    r.student.tableNumber,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 230,
                                                  child: Text(
                                                    r.student.fullName,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 45,
                                                  child: Text(
                                                    r.student.gender,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                // Notes par matière
                                                ...r.grades.map(
                                                  (g) => SizedBox(
                                                    width: 62,
                                                    child: Text(
                                                      g.scoreFormatted,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: g.isAbsent
                                                            ? AppColors.error
                                                            : ((g.score ?? 0) < 10 ? AppColors.error : AppColors.textPrimary),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Total Points
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    r.totalPointsFormatted,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor),
                                                  ),
                                                ),
                                                // Moyenne /20
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    "${r.averageFormatted} /20",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: r.isAdmitted ? AppColors.success : AppColors.error,
                                                    ),
                                                  ),
                                                ),
                                                // Décision
                                                SizedBox(
                                                  width: 90,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: r.isAdmitted ? AppColors.successBg : AppColors.errorBg,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      r.decision,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: r.isAdmitted ? AppColors.success : AppColors.error,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Mention
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    r.mention,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                ),
                                                // Bouton Action Relevé individuel
                                                SizedBox(
                                                  width: 90,
                                                  child: IconButton(
                                                    icon: Icon(Icons.print_outlined, size: 18, color: primaryColor),
                                                    tooltip: "Imprimer Relevé A5",
                                                    onPressed: () => widget.onPreviewSingleStudent(r),
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

  Future<void> _exportCsv(BuildContext context) async {
    final csvContent = CsvService.exportClassResultsToCsv(widget.subjects, widget.results);
    final savedUri = await FilePicker.saveFile(
      dialogTitle: "Enregistrer les résultats en CSV",
      fileName: "Resultats_${widget.schoolClass.name.replaceAll(' ', '_')}_${widget.exam.title.replaceAll(' ', '_')}.csv",
      bytes: Uint8List.fromList(utf8.encode(csvContent)),
    );

    if (savedUri != null) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fichier CSV enregistré avec succès ! (${savedUri.path})"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
