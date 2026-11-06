import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/academic_year.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../models/student_result.dart';
import '../models/subject.dart';
import '../services/calculation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'marks_entry_screen.dart';
import 'print_pv_screen.dart';
import 'print_report_card_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'students_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final AppUser currentUser;
  final AcademicYear initialYear;
  final VoidCallback onLogout;
  final VoidCallback onThemeChanged;

  const MainLayoutScreen({
    super.key,
    required this.currentUser,
    required this.initialYear,
    required this.onLogout,
    required this.onThemeChanged,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedNavIndex = 0;
  bool _isLoading = true;
  bool _isSidebarCollapsed = false;

  AppSettings? _settings;
  List<AcademicYear> _academicYears = [];
  AcademicYear? _selectedYear;

  List<Exam> _exams = [];
  Exam? _selectedExam;

  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;

  List<Subject> _subjects = [];
  List<Student> _students = [];
  List<StudentResult> _results = [];

  StudentResult? _targetStudentForA5;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final db = DatabaseHelper.instance;
    final settings = await db.getSettings();
    final years = await db.getAcademicYears();
    final activeYear = _selectedYear ?? await db.getActiveAcademicYear();

    final exams = await db.getExams(academicYear: activeYear.name);
    final activeExam = await db.getActiveExam(academicYear: activeYear.name);
    final classes = await db.getClasses();

    SchoolClass? defaultClass;
    if (classes.isNotEmpty) {
      defaultClass = classes.firstWhere(
        (c) => c.name.contains('Terminale D'),
        orElse: () => classes.first,
      );
    }

    _settings = settings;
    _academicYears = years;
    _selectedYear = activeYear;
    _exams = exams;
    _selectedExam = activeExam ?? (exams.isNotEmpty ? exams.first : null);
    _classes = classes;
    _selectedClass = defaultClass;

    await _loadClassData();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClassData() async {
    if (_selectedClass == null || _selectedClass!.id == null || _selectedExam == null || _selectedExam!.id == null) {
      _subjects = [];
      _students = [];
      _results = [];
      return;
    }

    final db = DatabaseHelper.instance;
    final subs = await db.getSubjectsForClass(_selectedClass!.id!);
    final studs = await db.getStudentsForClass(
      _selectedClass!.id!,
      academicYear: _selectedYear?.name,
    );
    final mrks = await db.getMarksForExamAndClass(_selectedExam!.id!, _selectedClass!.id!);

    final res = CalculationService.computeClassResults(
      schoolClass: _selectedClass!,
      subjects: subs,
      students: studs,
      marks: mrks,
    );

    _subjects = subs;
    _students = studs;
    _results = res;
  }

  void _onYearChanged(AcademicYear newYear) async {
    setState(() {
      _selectedYear = newYear;
      _isLoading = true;
    });

    final db = DatabaseHelper.instance;
    final exams = await db.getExams(academicYear: newYear.name);
    final activeExam = await db.getActiveExam(academicYear: newYear.name);

    _exams = exams;
    _selectedExam = activeExam ?? (exams.isNotEmpty ? exams.first : null);

    await _loadClassData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onClassChanged(SchoolClass newClass) async {
    setState(() {
      _selectedClass = newClass;
      _isLoading = true;
    });
    await _loadClassData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onExamChanged(Exam newExam) async {
    setState(() {
      _selectedExam = newExam;
      _isLoading = true;
    });
    await _loadClassData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onDataChanged() async {
    final db = DatabaseHelper.instance;
    final settings = await db.getSettings();
    final years = await db.getAcademicYears();
    final exams = await db.getExams(academicYear: _selectedYear?.name);
    final classes = await db.getClasses();

    Exam? activeExam = _selectedExam;
    if (exams.isNotEmpty) {
      final foundActive = exams.where((e) => e.isActive).toList();
      if (foundActive.isNotEmpty) {
        activeExam = foundActive.first;
      } else if (!exams.any((e) => e.id == _selectedExam?.id)) {
        activeExam = exams.first;
      }
    } else {
      activeExam = null;
    }

    setState(() {
      _settings = settings;
      _academicYears = years;
      _exams = exams;
      _classes = classes;
      _selectedExam = activeExam;
    });

    widget.onThemeChanged();
    await _loadClassData();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.fromHex(_settings?.primaryColorHex)),
              const SizedBox(height: 16),
              const Text(
                "Chargement des données de l'examen...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final isYearClosed = _selectedYear?.isClosed ?? false;

    Widget content;
    if (_selectedExam == null && _selectedNavIndex < 5) {
      content = _buildNoExamState();
    } else {
      switch (_selectedNavIndex) {
        case 0:
          content = DashboardScreen(
            settings: _settings,
            selectedYear: _selectedYear,
            exam: _selectedExam,
            schoolClass: _selectedClass,
            results: _results,
            onGoToMarks: () => setState(() => _selectedNavIndex = 1),
            onGoToResults: () => setState(() => _selectedNavIndex = 2),
            onGoToPrintA5: () => setState(() {
              _targetStudentForA5 = null;
              _selectedNavIndex = 3;
            }),
            onGoToPrintPv: () => setState(() => _selectedNavIndex = 4),
          );
          break;
        case 1:
          content = MarksEntryScreen(
            settings: _settings,
            exam: _selectedExam!,
            schoolClass: _selectedClass!,
            subjects: _subjects,
            students: _students,
            onMarksSaved: _onDataChanged,
            isReadOnly: isYearClosed,
          );
          break;
        case 2:
          content = ResultsScreen(
            settings: _settings,
            exam: _selectedExam!,
            schoolClass: _selectedClass!,
            subjects: _subjects,
            results: _results,
            onPreviewSingleStudent: (studentResult) {
              setState(() {
                _targetStudentForA5 = studentResult;
                _selectedNavIndex = 3;
              });
            },
            onPreviewAllStudentsA5: () {
              setState(() {
                _targetStudentForA5 = null;
                _selectedNavIndex = 3;
              });
            },
            onPreviewPvA4: () => setState(() => _selectedNavIndex = 4),
          );
          break;
        case 3:
          content = PrintReportCardScreen(
            settings: _settings!,
            exam: _selectedExam!,
            schoolClass: _selectedClass!,
            results: _results,
            initialSelectedStudent: _targetStudentForA5,
          );
          break;
        case 4:
          content = PrintPvScreen(
            settings: _settings!,
            exam: _selectedExam!,
            schoolClass: _selectedClass!,
            subjects: _subjects,
            results: _results,
          );
          break;
        case 5:
          content = StudentsScreen(
            settings: _settings,
            schoolClass: _selectedClass!,
            students: _students,
            onStudentsChanged: _onDataChanged,
            isReadOnly: isYearClosed,
            academicYear: _selectedYear?.name ?? '2025-2026',
          );
          break;
        case 6:
          content = SettingsScreen(
            settings: _settings!,
            academicYears: _academicYears,
            activeYear: _selectedYear,
            exams: _exams,
            activeExam: _selectedExam,
            classes: _classes,
            currentUser: widget.currentUser,
            onSettingsUpdated: _onDataChanged,
            onYearChanged: _onYearChanged,
            onExamChanged: _onExamChanged,
          );
          break;
        default:
          content = const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sidebar(
            selectedIndex: _selectedNavIndex,
            onItemSelected: (idx) => setState(() => _selectedNavIndex = idx),
            settings: _settings,
            academicYears: _academicYears,
            selectedYear: _selectedYear,
            onYearChanged: _onYearChanged,
            exams: _exams,
            selectedExam: _selectedExam,
            onExamChanged: _onExamChanged,
            classes: _classes,
            selectedClass: _selectedClass,
            onClassChanged: _onClassChanged,
            currentUser: widget.currentUser,
            onLogout: widget.onLogout,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildNoExamState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              "Aucune session d'examen pour l'année ${_selectedYear?.name ?? ''}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pour démarrer la saisie des notes et générer les relevés A5, veuillez créer la première session d'examen blanc de cette année scolaire.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Créer une Session d'Examen Blanc"),
              onPressed: _showQuickCreateExamDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCreateExamDialog() {
    final titleCtrl = TextEditingController(text: "Examen Blanc Régional N°1");
    final dateCtrl = TextEditingController(text: "Mars ${_selectedYear?.name.split('-').last ?? DateTime.now().year}");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nouvel Examen Blanc (${_selectedYear?.name ?? ''})"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Intitulé de la session")),
            const SizedBox(height: 10),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date / Période")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final newEx = Exam(
                title: titleCtrl.text.trim(),
                sessionDate: dateCtrl.text.trim(),
                academicYear: _selectedYear?.name ?? '2025-2026',
                isActive: true,
              );
              await DatabaseHelper.instance.addExam(newEx);
              if (mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                _onYearChanged(_selectedYear!);
              }
            },
            child: const Text("Créer et Activer"),
          ),
        ],
      ),
    );
  }
}
