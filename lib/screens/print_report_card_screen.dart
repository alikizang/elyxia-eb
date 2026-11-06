import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/student_result.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';

class PrintReportCardScreen extends StatefulWidget {
  final AppSettings settings;
  final Exam exam;
  final SchoolClass schoolClass;
  final List<StudentResult> results;
  final StudentResult? initialSelectedStudent;

  const PrintReportCardScreen({
    super.key,
    required this.settings,
    required this.exam,
    required this.schoolClass,
    required this.results,
    this.initialSelectedStudent,
  });

  @override
  State<PrintReportCardScreen> createState() => _PrintReportCardScreenState();
}

class _PrintReportCardScreenState extends State<PrintReportCardScreen> {
  bool _isBatchMode = true; // true = toute la classe, false = élève individuel
  StudentResult? _selectedStudent;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedStudent != null) {
      _isBatchMode = false;
      _selectedStudent = widget.initialSelectedStudent;
    } else if (widget.results.isNotEmpty) {
      _selectedStudent = widget.results.first;
    }
  }

  @override
  void didUpdateWidget(covariant PrintReportCardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedStudent != null &&
        widget.initialSelectedStudent != oldWidget.initialSelectedStudent) {
      _isBatchMode = false;
      _selectedStudent = widget.initialSelectedStudent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const Center(
        child: Text("Aucun résultat disponible pour cette classe."),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre d'options de prévisualisation (Unique vs Ensemble)
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
                        "Impression des Relevés de Notes (Format A5)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.schoolClass.name} • ${widget.exam.title} • Format standard officiel A5 Portrait (148 × 210 mm)",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Sélecteur Mode : Ensemble vs Unique
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.copy_all_rounded, size: 18),
                      label: Text("Prévisualisation d'Ensemble (Toute la classe)"),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.person_rounded, size: 18),
                      label: Text("Prévisualisation Unique (Par élève)"),
                    ),
                  ],
                  selected: {_isBatchMode},
                  onSelectionChanged: (val) {
                    setState(() => _isBatchMode = val.first);
                  },
                ),

                // Sélecteur d'élève si mode unique actif
                if (!_isBatchMode) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<StudentResult>(
                        value: _selectedStudent,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        items: widget.results.map((r) {
                          return DropdownMenuItem<StudentResult>(
                            value: r,
                            child: Text(
                              "[N° ${r.student.tableNumber}] ${r.student.fullName} (${r.averageFormatted}/20)",
                            ),
                          );
                        }).toList(),
                        onChanged: (newR) {
                          if (newR != null) {
                            setState(() => _selectedStudent = newR);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Zone de Prévisualisation interactive PDF (A5)
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
                  maxPageWidth: 460,
                  initialPageFormat: PdfPageFormat.a5,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: _isBatchMode
                      ? "Releves_${widget.schoolClass.name.replaceAll(' ', '_')}_${widget.exam.title.replaceAll(' ', '_')}.pdf"
                      : "Releve_${_selectedStudent?.student.tableNumber}_${_selectedStudent?.student.fullName.replaceAll(' ', '_')}.pdf",
                  build: (format) async {
                    if (_isBatchMode) {
                      return PdfService.generateBatchReportCards(
                        settings: widget.settings,
                        exam: widget.exam,
                        results: widget.results,
                      );
                    } else {
                      return PdfService.generateSingleReportCard(
                        settings: widget.settings,
                        exam: widget.exam,
                        result: _selectedStudent ?? widget.results.first,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
