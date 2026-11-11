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

class PrintPvScreen extends StatefulWidget {
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
  State<PrintPvScreen> createState() => _PrintPvScreenState();
}

class _PrintPvScreenState extends State<PrintPvScreen> {
  double _zoomWidth = 950; // Largeur par défaut pour A4 Paysage
  bool _includeSignatures = true;

  void _zoomIn() {
    setState(() {
      if (_zoomWidth < 1800) _zoomWidth += 100;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoomWidth > 600) _zoomWidth -= 100;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomWidth = 950;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const Center(
        child: Text("Aucun résultat disponible pour générer le Procès-Verbal."),
      );
    }

    final primaryColor = AppColors.fromHex(widget.settings.primaryColorHex);
    final zoomPercent = ((_zoomWidth / 950) * 100).round();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec Zoom
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 950;

                final titleCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Procès-Verbal de Délibération (Format A4 Paysage)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.schoolClass.name} (${widget.schoolClass.examType}) • ${widget.exam.title} • Fiche récapitulative grand format pour affichage et archives",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                );

                final controls = Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Interrupteur Signatures Numérisées
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.draw_rounded, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          const Text("Signatures numérisées", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Switch(
                            value: _includeSignatures,
                            activeThumbColor: primaryColor,
                            onChanged: (val) => setState(() => _includeSignatures = val),
                          ),
                        ],
                      ),
                    ),

                    // Barre de Zoom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.zoom_in, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            tooltip: "Dézoomer",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: _zoomWidth > 600 ? _zoomOut : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              "$zoomPercent %",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            tooltip: "Zoomer",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: _zoomWidth < 1800 ? _zoomIn : null,
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _resetZoom,
                            child: const Text("100%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleCol,
                      const SizedBox(height: 12),
                      controls,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleCol),
                    const SizedBox(width: 16),
                    controls,
                  ],
                );
              },
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
                  maxPageWidth: _zoomWidth,
                  initialPageFormat: PdfPageFormat.a4.landscape,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: "PV_Deliberation_${widget.schoolClass.name.replaceAll(' ', '_')}_${widget.exam.title.replaceAll(' ', '_')}.pdf",
                  build: (format) => PdfService.generatePvReport(
                    settings: widget.settings,
                    exam: widget.exam,
                    schoolClass: widget.schoolClass,
                    subjects: widget.subjects,
                    results: widget.results,
                    applySignatures: _includeSignatures,
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
