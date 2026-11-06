import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/mark.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../services/calculation_service.dart';
import '../theme/app_colors.dart';

class MarksEntryScreen extends StatefulWidget {
  final AppSettings? settings;
  final Exam exam;
  final SchoolClass schoolClass;
  final List<Subject> subjects;
  final List<Student> students;
  final VoidCallback onMarksSaved;
  final bool isReadOnly;

  const MarksEntryScreen({
    super.key,
    this.settings,
    required this.exam,
    required this.schoolClass,
    required this.subjects,
    required this.students,
    required this.onMarksSaved,
    this.isReadOnly = false,
  });

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  Subject? _selectedSubject;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, bool> _absentStates = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
    }
    _initControllers();
    _loadExistingMarks();
  }

  @override
  void didUpdateWidget(covariant MarksEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolClass.id != widget.schoolClass.id || oldWidget.exam.id != widget.exam.id) {
      if (widget.subjects.isNotEmpty) {
        _selectedSubject = widget.subjects.first;
      }
      _initControllers();
      _loadExistingMarks();
    }
  }

  void _initControllers() {
    _controllers.clear();
    _focusNodes.clear();
    _absentStates.clear();

    for (final s in widget.students) {
      if (s.id != null) {
        _controllers[s.id!] = TextEditingController();
        _focusNodes[s.id!] = FocusNode();
        _absentStates[s.id!] = false;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingMarks() async {
    if (_selectedSubject == null) return;
    setState(() => _isLoading = true);

    final marks = await DatabaseHelper.instance.getMarksForExamAndClass(
      widget.exam.id!,
      widget.schoolClass.id!,
    );

    // Filtrer pour la matière sélectionnée
    for (final s in widget.students) {
      final sid = s.id;
      if (sid == null) continue;

      final mark = marks.firstWhere(
        (m) => m.studentId == sid && m.subjectId == _selectedSubject!.id,
        orElse: () => Mark(
          examId: widget.exam.id!,
          studentId: sid,
          subjectId: _selectedSubject!.id!,
        ),
      );

      _absentStates[sid] = mark.isAbsent;
      if (mark.isAbsent) {
        _controllers[sid]?.text = "";
      } else if (mark.score != null) {
        _controllers[sid]?.text = mark.score!.toStringAsFixed(mark.score! % 1 == 0 ? 0 : 2);
      } else {
        _controllers[sid]?.text = "";
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAllMarks() async {
    if (_selectedSubject == null) return;
    setState(() => _isSaving = true);

    final marksToSave = <Mark>[];

    for (final s in widget.students) {
      final sid = s.id;
      if (sid == null) continue;

      final isAbsent = _absentStates[sid] ?? false;
      final text = _controllers[sid]?.text.trim().replaceAll(',', '.') ?? '';
      final score = (text.isNotEmpty && !isAbsent) ? double.tryParse(text) : null;

      marksToSave.add(
        Mark(
          examId: widget.exam.id!,
          studentId: sid,
          subjectId: _selectedSubject!.id!,
          score: score,
          isAbsent: isAbsent,
        ),
      );
    }

    await DatabaseHelper.instance.saveMarksBatch(marksToSave);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Notes de '${_selectedSubject!.name}' enregistrées avec succès !"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onMarksSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return const Center(
        child: Text("Aucune matière configurée pour cette classe."),
      );
    }

    // Statistiques rapides de la matière sélectionnée
    double sum = 0;
    int gradedCount = 0;
    double? maxScore;
    double? minScore;

    for (final s in widget.students) {
      final sid = s.id;
      if (sid == null) continue;
      if (_absentStates[sid] == true) continue;
      final val = double.tryParse(_controllers[sid]?.text.replaceAll(',', '.') ?? '');
      if (val != null) {
        sum += val;
        gradedCount++;
        if (maxScore == null || val > maxScore) maxScore = val;
        if (minScore == null || val < minScore) minScore = val;
      }
    }

    final subjectAvg = gradedCount > 0 ? (sum / gradedCount) : 0.0;
    final primaryColor = AppColors.fromHex(widget.settings?.primaryColorHex);

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
                          "Cette année scolaire est archivée. La saisie et modification des notes sont verrouillées.",
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // En-tête : Sélecteur de Matière + Boutons d'Action
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
                        "Saisie des Notes — ${widget.schoolClass.name}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.exam.title} • Navigation clavier : Appuyez sur [Entrée] pour passer au candidat suivant",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Sélecteur de matière
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Subject>(
                      value: _selectedSubject,
                      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      items: widget.subjects.map((sub) {
                        return DropdownMenuItem<Subject>(
                          value: sub,
                          child: Text(
                            "${sub.name} (Coef: ${sub.coefficient.toInt()})",
                          ),
                        );
                      }).toList(),
                      onChanged: (newSub) {
                        if (newSub != null) {
                          setState(() => _selectedSubject = newSub);
                          _loadExistingMarks();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Bouton Enregistrer
                ElevatedButton.icon(
                  onPressed: (widget.isReadOnly || _isSaving) ? null : _saveAllMarks,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isSaving ? "Enregistrement..." : "Enregistrer les Notes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Mini bar des indicateurs de la matière
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Matière : ${_selectedSubject?.name ?? ''} (Coef : ${_selectedSubject?.coefficient.toInt() ?? 1})",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                ),
                Text(
                  "Candidats saisis : $gradedCount / ${widget.students.length}",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  "Moyenne matière : ${subjectAvg.toStringAsFixed(2)} / 20",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subjectAvg >= 10 ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  "Note Max : ${maxScore != null ? maxScore.toStringAsFixed(2) : '-'} | Min : ${minScore != null ? minScore.toStringAsFixed(2) : '-'}",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Table de saisie
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
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
                        // En-tête du tableau
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              topRight: Radius.circular(11),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 60, child: Text("N° TABLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              SizedBox(width: 110, child: Text("MATRICULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(flex: 3, child: Text("NOM & PRÉNOMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              SizedBox(width: 60, child: Text("SEXE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              SizedBox(width: 90, child: Text("ABSENT ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              SizedBox(width: 140, child: Text("NOTE /20", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              SizedBox(width: 100, child: Text("POINTS (N×C)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(flex: 2, child: Text("APPRÉCIATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                          ),
                        ),
                        // Liste des élèves
                        Expanded(
                          child: ListView.separated(
                            itemCount: widget.students.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (context, index) {
                              final student = widget.students[index];
                              final sid = student.id!;
                              final controller = _controllers[sid]!;
                              final focusNode = _focusNodes[sid]!;
                              final isAbsent = _absentStates[sid] ?? false;

                              final score = !isAbsent ? double.tryParse(controller.text.replaceAll(',', '.')) : null;
                              final coef = _selectedSubject?.coefficient ?? 1.0;
                              final points = score != null ? (score * coef) : null;
                              final appreciation = CalculationService.getAppreciation(score, isAbsent);

                              return Container(
                                color: index % 2 == 1 ? AppColors.surfaceSubtle.withValues(alpha: 0.5) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        student.tableNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 110,
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
                                      width: 60,
                                      child: Text(
                                        student.gender,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    // Checkbox Absent
                                    SizedBox(
                                      width: 90,
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: isAbsent,
                                            activeColor: AppColors.error,
                                            onChanged: widget.isReadOnly
                                                ? null
                                                : (val) {
                                                    setState(() {
                                                      _absentStates[sid] = val ?? false;
                                                      if (val == true) {
                                                        controller.text = "";
                                                      }
                                                    });
                                                  },
                                          ),
                                          const Text("ABS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    // Saisie de la Note
                                    SizedBox(
                                      width: 140,
                                      child: TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        enabled: !isAbsent && !widget.isReadOnly,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isAbsent
                                              ? AppColors.textMuted
                                              : (score != null && score < 10 ? AppColors.error : primaryColor),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: isAbsent ? "ABSENT" : "Ex: 14.5",
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: AppColors.border),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: BorderSide(color: primaryColor, width: 2),
                                          ),
                                          suffixText: isAbsent ? null : "/20",
                                        ),
                                        onChanged: (text) {
                                          setState(() {}); // Recalcul visuel direct
                                        },
                                        onSubmitted: (_) {
                                          // Aller automatiquement au candidat suivant avec [Entrée] !
                                          if (index + 1 < widget.students.length) {
                                            final nextSid = widget.students[index + 1].id;
                                            if (nextSid != null) {
                                              _focusNodes[nextSid]?.requestFocus();
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    // Points calculés
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        isAbsent ? "-" : (points != null ? points.toStringAsFixed(2) : "-"),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                                      ),
                                    ),
                                    // Appréciation
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isAbsent
                                              ? AppColors.errorBg
                                              : (score != null && score >= 10 ? AppColors.successBg : AppColors.surfaceSubtle),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          appreciation,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isAbsent
                                                ? AppColors.error
                                                : (score != null && score >= 10 ? AppColors.success : AppColors.textSecondary),
                                          ),
                                        ),
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
}
