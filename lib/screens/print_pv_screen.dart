import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/student_result.dart';
import '../models/subject.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';

class PrintPvScreen extends StatelessWidget {
  final AppSettings settings;
  final Exam exam;
  final SchoolClass schoolClass;
  final List<Subject> subjects;
  final List<StudentResult> results;

  const PrintPvScreen({
    super.key,
    required this.settings,
    required this.exam,
    required this.schoolClass,
    required this.subjects,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text("Aucun résultat disponible pour générer le Procès-Verbal."),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(18),
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
                      const Text(
                        "Procès-Verbal de Délibération (Format A4 Paysage)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${schoolClass.name} (${schoolClass.examType}) • ${exam.title} • Fiche récapitulative grand format pour affichage et archives",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Visualiseur PDF A4 Paysage
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
                borderRadius: BorderRadius.circular(12),
                child: PdfPreview(
                  initialPageFormat: PdfPageFormat.a4.landscape,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: "PV_Deliberation_${schoolClass.name.replaceAll(' ', '_')}_${exam.title.replaceAll(' ', '_')}.pdf",
                  build: (format) => PdfService.generatePvReport(
                    settings: settings,
                    exam: exam,
                    schoolClass: schoolClass,
                    subjects: subjects,
                    results: results,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
