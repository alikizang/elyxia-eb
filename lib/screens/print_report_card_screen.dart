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
  double _zoomWidth = 650; // Largeur par défaut permettant un affichage A5 net et lisible
  bool _includeSignatures = true;

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

  void _zoomIn() {
    setState(() {
      if (_zoomWidth < 1300) _zoomWidth += 75;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoomWidth > 425) _zoomWidth -= 75;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomWidth = 650;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const Center(
        child: Text("Aucun résultat disponible pour cette classe."),
      );
    }

    final primaryColor = AppColors.fromHex(widget.settings.primaryColorHex);
    final zoomPercent = ((_zoomWidth / 650) * 100).round();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre d'options et de contrôle
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne 1 : Titre à gauche + Contrôles de Zoom à droite
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Impression des Relevés de Notes (Format A5)",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
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
                    const SizedBox(width: 16),

                    // Barre de Zoom interactive
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
                            onPressed: _zoomWidth > 425 ? _zoomOut : null,
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
                            onPressed: _zoomWidth < 1300 ? _zoomIn : null,
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
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),

                // Ligne 2 : Sélecteur de Mode (Ensemble vs Unique) + Choix de l'élève
                Row(
                  children: [
                    // Sélecteur Mode
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.copy_all_rounded, size: 16),
                          label: Text("Toute la classe (Lot)"),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.person_rounded, size: 16),
                          label: Text("Par élève (Individuel)"),
                        ),
                      ],
                      selected: {_isBatchMode},
                      onSelectionChanged: (val) {
                        setState(() => _isBatchMode = val.first);
                      },
                    ),

                    if (!_isBatchMode) ...[
                      const SizedBox(width: 16),
                      // Dropdown occupant tout l'espace disponible sans être tronqué
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<StudentResult>(
                              isExpanded: true,
                              value: _selectedStudent,
                              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                              items: widget.results.map((r) {
                                return DropdownMenuItem<StudentResult>(
                                  value: r,
                                  child: Text(
                                    "[N° ${r.student.tableNumber}] ${r.student.fullName}  •  Moyenne : ${r.averageFormatted}/20  •  Rang : ${r.rankFormatted}",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                      ),
                      const SizedBox(width: 16),
                    ] else ...[
                      const Spacer(),
                    ],

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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Zone de Prévisualisation interactive PDF (A5) avec support de Zoom
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
                        applySignatures: _includeSignatures,
                      );
                    } else {
                      return PdfService.generateSingleReportCard(
                        settings: widget.settings,
                        exam: widget.exam,
                        result: _selectedStudent ?? widget.results.first,
                        applySignatures: _includeSignatures,
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
