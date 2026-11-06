import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/mark.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../models/subject.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('elyxia_eb.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialisation du moteur SQLite natif pour macOS et Windows
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final ebDir = Directory(p.join(docsDir.path, 'ElyxiaEB'));
    if (!await ebDir.exists()) {
      await ebDir.create(recursive: true);
    }

    final path = p.join(ebDir.path, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Paramètres de l'établissement
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        school_name TEXT NOT NULL,
        school_sub_title TEXT NOT NULL,
        school_address TEXT NOT NULL,
        school_phone TEXT NOT NULL,
        school_email TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        republic_header TEXT NOT NULL,
        director_title TEXT NOT NULL,
        director_name TEXT NOT NULL,
        jury_president_title TEXT NOT NULL
      )
    ''');

    // 2. Classes (Premières et Terminales - Bac 1 et Bac 2)
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        series TEXT NOT NULL,
        exam_type TEXT NOT NULL
      )
    ''');

    // 3. Matières & Coefficients
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        coefficient REAL NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
      )
    ''');

    // 4. Élèves
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        matricule TEXT NOT NULL,
        table_number TEXT NOT NULL,
        last_name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        gender TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        birth_place TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
      )
    ''');

    // 5. Examens Blancs
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        session_date TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 6. Notes
    await db.execute('''
      CREATE TABLE marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        score REAL,
        is_absent INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
        UNIQUE (exam_id, student_id, subject_id)
      )
    ''');

    // Insertion des données initiales (Curriculum Togo + Complexe Scolaire Les Victorieux)
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Paramètres initiaux
    final defaultSettings = AppSettings(
      schoolName: "COMPLEXE SCOLAIRE LES VICTORIEUX",
      schoolSubTitle: "Lycée d'Enseignement Général — BAC 1 & BAC 2",
      schoolAddress: "Lomé, République Togolaise",
      schoolPhone: "+228 90 12 34 56 / 99 87 65 43",
      schoolEmail: "direction@lesvictorieux-togo.org",
      academicYear: "2025-2026",
      republicHeader: "RÉPUBLIQUE TOGOLAISE\nTravail - Liberté - Patrie\nMINISTÈRE DES ENSEIGNEMENTS PRIMAIRE, SECONDAIRE ET TECHNIQUE",
      directorTitle: "Le Chef d'Établissement",
      directorName: "M. le Proviseur",
      juryPresidentTitle: "Le Président du Jury",
    );
    await db.insert('settings', defaultSettings.toMap());

    // 2. Examen Blanc Initial
    final examId = await db.insert('exams', {
      'title': 'Examen Blanc Régional N°1',
      'session_date': 'Mars 2026',
      'academic_year': '2025-2026',
      'is_active': 1,
    });

    // 3. Classes de Premières et Terminales (Togo)
    final classesData = [
      {'name': '1ère A4', 'level': '1ère', 'series': 'A4', 'exam_type': 'BAC 1'},
      {'name': '1ère D', 'level': '1ère', 'series': 'D', 'exam_type': 'BAC 1'},
      {'name': '1ère C', 'level': '1ère', 'series': 'C', 'exam_type': 'BAC 1'},
      {'name': 'Terminale A4', 'level': 'Terminale', 'series': 'A4', 'exam_type': 'BAC 2'},
      {'name': 'Terminale D', 'level': 'Terminale', 'series': 'D', 'exam_type': 'BAC 2'},
      {'name': 'Terminale C', 'level': 'Terminale', 'series': 'C', 'exam_type': 'BAC 2'},
    ];

    final classIds = <String, int>{};
    for (final c in classesData) {
      final id = await db.insert('classes', c);
      classIds[c['name']!] = id;
    }

    // 4. Matières et Coefficients officiels pour le Togo
    // --- 1ère A4 ---
    await _insertSubjects(db, classIds['1ère A4']!, [
      Subject(classId: classIds['1ère A4']!, name: 'Français', code: 'FRA', coefficient: 4.0, orderIndex: 1),
      Subject(classId: classIds['1ère A4']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 2),
      Subject(classId: classIds['1ère A4']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 3.0, orderIndex: 3),
      Subject(classId: classIds['1ère A4']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 3.0, orderIndex: 4),
      Subject(classId: classIds['1ère A4']!, name: 'Allemand / Espagnol (LV2)', code: 'LV2', coefficient: 3.0, orderIndex: 5),
      Subject(classId: classIds['1ère A4']!, name: 'Mathématiques', code: 'MATH', coefficient: 2.0, orderIndex: 6),
      Subject(classId: classIds['1ère A4']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 2.0, orderIndex: 7),
      Subject(classId: classIds['1ère A4']!, name: 'Sciences Physiques', code: 'SP', coefficient: 1.0, orderIndex: 8),
      Subject(classId: classIds['1ère A4']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 9),
      Subject(classId: classIds['1ère A4']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 10),
    ]);

    // --- 1ère D ---
    await _insertSubjects(db, classIds['1ère D']!, [
      Subject(classId: classIds['1ère D']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 4.0, orderIndex: 1),
      Subject(classId: classIds['1ère D']!, name: 'Mathématiques', code: 'MATH', coefficient: 4.0, orderIndex: 2),
      Subject(classId: classIds['1ère D']!, name: 'Sciences Physiques', code: 'SP', coefficient: 4.0, orderIndex: 3),
      Subject(classId: classIds['1ère D']!, name: 'Français', code: 'FRA', coefficient: 3.0, orderIndex: 4),
      Subject(classId: classIds['1ère D']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 5),
      Subject(classId: classIds['1ère D']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 2.0, orderIndex: 6),
      Subject(classId: classIds['1ère D']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 2.0, orderIndex: 7),
      Subject(classId: classIds['1ère D']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 8),
      Subject(classId: classIds['1ère D']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 9),
    ]);

    // --- 1ère C ---
    await _insertSubjects(db, classIds['1ère C']!, [
      Subject(classId: classIds['1ère C']!, name: 'Mathématiques', code: 'MATH', coefficient: 6.0, orderIndex: 1),
      Subject(classId: classIds['1ère C']!, name: 'Sciences Physiques', code: 'SP', coefficient: 5.0, orderIndex: 2),
      Subject(classId: classIds['1ère C']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 2.0, orderIndex: 3),
      Subject(classId: classIds['1ère C']!, name: 'Français', code: 'FRA', coefficient: 3.0, orderIndex: 4),
      Subject(classId: classIds['1ère C']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 5),
      Subject(classId: classIds['1ère C']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 2.0, orderIndex: 6),
      Subject(classId: classIds['1ère C']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 2.0, orderIndex: 7),
      Subject(classId: classIds['1ère C']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 8),
      Subject(classId: classIds['1ère C']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 9),
    ]);

    // --- Terminale A4 ---
    await _insertSubjects(db, classIds['Terminale A4']!, [
      Subject(classId: classIds['Terminale A4']!, name: 'Philosophie', code: 'PHILO', coefficient: 5.0, orderIndex: 1),
      Subject(classId: classIds['Terminale A4']!, name: 'Français', code: 'FRA', coefficient: 4.0, orderIndex: 2),
      Subject(classId: classIds['Terminale A4']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 3.0, orderIndex: 3),
      Subject(classId: classIds['Terminale A4']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 3.0, orderIndex: 4),
      Subject(classId: classIds['Terminale A4']!, name: 'Allemand / Espagnol (LV2)', code: 'LV2', coefficient: 3.0, orderIndex: 5),
      Subject(classId: classIds['Terminale A4']!, name: 'Mathématiques', code: 'MATH', coefficient: 2.0, orderIndex: 6),
      Subject(classId: classIds['Terminale A4']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 2.0, orderIndex: 7),
      Subject(classId: classIds['Terminale A4']!, name: 'Sciences Physiques', code: 'SP', coefficient: 1.0, orderIndex: 8),
      Subject(classId: classIds['Terminale A4']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 9),
      Subject(classId: classIds['Terminale A4']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 10),
    ]);

    // --- Terminale D ---
    final tleDSubjects = [
      Subject(classId: classIds['Terminale D']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 5.0, orderIndex: 1),
      Subject(classId: classIds['Terminale D']!, name: 'Sciences Physiques', code: 'SP', coefficient: 4.0, orderIndex: 2),
      Subject(classId: classIds['Terminale D']!, name: 'Mathématiques', code: 'MATH', coefficient: 4.0, orderIndex: 3),
      Subject(classId: classIds['Terminale D']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 4),
      Subject(classId: classIds['Terminale D']!, name: 'Français', code: 'FRA', coefficient: 2.0, orderIndex: 5),
      Subject(classId: classIds['Terminale D']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 2.0, orderIndex: 6),
      Subject(classId: classIds['Terminale D']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 2.0, orderIndex: 7),
      Subject(classId: classIds['Terminale D']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 8),
      Subject(classId: classIds['Terminale D']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 9),
    ];
    await _insertSubjects(db, classIds['Terminale D']!, tleDSubjects);

    // --- Terminale C ---
    await _insertSubjects(db, classIds['Terminale C']!, [
      Subject(classId: classIds['Terminale C']!, name: 'Mathématiques', code: 'MATH', coefficient: 6.0, orderIndex: 1),
      Subject(classId: classIds['Terminale C']!, name: 'Sciences Physiques', code: 'SP', coefficient: 5.0, orderIndex: 2),
      Subject(classId: classIds['Terminale C']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 3.0, orderIndex: 3),
      Subject(classId: classIds['Terminale C']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 4),
      Subject(classId: classIds['Terminale C']!, name: 'Français', code: 'FRA', coefficient: 2.0, orderIndex: 5),
      Subject(classId: classIds['Terminale C']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 2.0, orderIndex: 6),
      Subject(classId: classIds['Terminale C']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 2.0, orderIndex: 7),
      Subject(classId: classIds['Terminale C']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 8),
      Subject(classId: classIds['Terminale C']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 9),
    ]);

    // 5. Exemples d'élèves pour la Terminale D afin de permettre un test direct
    final sampleStudents = [
      Student(
        classId: classIds['Terminale D']!,
        matricule: 'VIC-2025-0101',
        tableNumber: '101',
        lastName: 'KOUDOSSOU',
        firstName: 'Koffi Jean-Luc',
        gender: 'M',
        birthDate: '14/05/2007',
        birthPlace: 'Lomé',
      ),
      Student(
        classId: classIds['Terminale D']!,
        matricule: 'VIC-2025-0102',
        tableNumber: '102',
        lastName: 'ADJALLÉ',
        firstName: 'Afiwa Blandine',
        gender: 'F',
        birthDate: '22/09/2007',
        birthPlace: 'Aného',
      ),
      Student(
        classId: classIds['Terminale D']!,
        matricule: 'VIC-2025-0103',
        tableNumber: '103',
        lastName: 'MENSAH',
        firstName: 'Kokou Mawunyo',
        gender: 'M',
        birthDate: '03/01/2008',
        birthPlace: 'Kpalimé',
      ),
      Student(
        classId: classIds['Terminale D']!,
        matricule: 'VIC-2025-0104',
        tableNumber: '104',
        lastName: 'LAWSON',
        firstName: 'Latré Pierrette',
        gender: 'F',
        birthDate: '19/11/2007',
        birthPlace: 'Lomé',
      ),
      Student(
        classId: classIds['Terminale D']!,
        matricule: 'VIC-2025-0105',
        tableNumber: '105',
        lastName: 'AMOUZOU',
        firstName: 'Kodjo François',
        gender: 'M',
        birthDate: '07/07/2007',
        birthPlace: 'Atakpamé',
      ),
    ];

    final studentIds = <int>[];
    for (final s in sampleStudents) {
      final sid = await db.insert('students', s.toMap());
      studentIds.add(sid);
    }

    // Récupérer les ID des matières de Terminale D
    final subRows = await db.query(
      'subjects',
      where: 'class_id = ?',
      whereArgs: [classIds['Terminale D']!],
      orderBy: 'order_index ASC',
    );
    final subIds = subRows.map((r) => r['id'] as int).toList();

    // Notes d'exemples réalistes
    final sampleScores = [
      // KOUDOSSOU Koffi Jean-Luc (Excellente moyenne ~15.20)
      [16.5, 15.0, 16.0, 14.0, 13.5, 15.0, 14.0, 16.0, 17.0],
      // ADJALLÉ Afiwa Blandine (Très bonne moyenne ~13.80)
      [14.0, 13.5, 14.0, 13.0, 14.5, 14.0, 13.0, 15.0, 16.0],
      // MENSAH Kokou Mawunyo (Moyenne passable ~11.10)
      [11.5, 10.0, 11.0, 10.5, 11.0, 12.0, 10.0, 13.0, 15.0],
      // LAWSON Latré Pierrette (Moyenne moyenne ~10.40)
      [10.0, 10.5, 9.5, 11.0, 10.0, 11.5, 10.0, 12.0, 14.0],
      // AMOUZOU Kodjo François (Ajourné ~8.70)
      [8.0, 8.5, 7.5, 9.0, 9.5, 10.0, 9.0, 11.0, 13.0],
    ];

    for (int i = 0; i < studentIds.length; i++) {
      final sid = studentIds[i];
      final scores = sampleScores[i];
      for (int j = 0; j < subIds.length; j++) {
        await db.insert('marks', {
          'exam_id': examId,
          'student_id': sid,
          'subject_id': subIds[j],
          'score': scores[j],
          'is_absent': 0,
        });
      }
    }
  }

  Future<void> _insertSubjects(Database db, int classId, List<Subject> subjects) async {
    for (final s in subjects) {
      await db.insert('subjects', s.toMap());
    }
  }

  // ==================== APP SETTINGS ====================
  Future<AppSettings> getSettings() async {
    final db = await database;
    final res = await db.query('settings', limit: 1);
    if (res.isNotEmpty) {
      return AppSettings.fromMap(res.first);
    }
    return AppSettings(
      schoolName: "COMPLEXE SCOLAIRE LES VICTORIEUX",
      academicYear: "2025-2026",
    );
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await database;
    await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [settings.id]);
  }

  // ==================== CLASSES ====================
  Future<List<SchoolClass>> getClasses() async {
    final db = await database;
    final res = await db.query('classes', orderBy: 'level ASC, series ASC');
    return res.map((e) => SchoolClass.fromMap(e)).toList();
  }

  Future<SchoolClass?> getClassById(int id) async {
    final db = await database;
    final res = await db.query('classes', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return SchoolClass.fromMap(res.first);
    return null;
  }

  Future<int> addClass(SchoolClass schoolClass) async {
    final db = await database;
    return await db.insert('classes', schoolClass.toMap());
  }

  Future<void> updateClass(SchoolClass schoolClass) async {
    final db = await database;
    await db.update('classes', schoolClass.toMap(), where: 'id = ?', whereArgs: [schoolClass.id]);
  }

  Future<void> deleteClass(int id) async {
    final db = await database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SUBJECTS ====================
  Future<List<Subject>> getSubjectsForClass(int classId) async {
    final db = await database;
    final res = await db.query(
      'subjects',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'order_index ASC, id ASC',
    );
    return res.map((e) => Subject.fromMap(e)).toList();
  }

  Future<int> addSubject(Subject subject) async {
    final db = await database;
    return await db.insert('subjects', subject.toMap());
  }

  Future<void> updateSubject(Subject subject) async {
    final db = await database;
    await db.update('subjects', subject.toMap(), where: 'id = ?', whereArgs: [subject.id]);
  }

  Future<void> deleteSubject(int id) async {
    final db = await database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== STUDENTS ====================
  Future<List<Student>> getStudentsForClass(int classId) async {
    final db = await database;
    final res = await db.query(
      'students',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'table_number ASC, last_name ASC',
    );
    return res.map((e) => Student.fromMap(e)).toList();
  }

  Future<int> addStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update('students', student.toMap(), where: 'id = ?', whereArgs: [student.id]);
  }

  Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addStudentsBatch(List<Student> students) async {
    final db = await database;
    final batch = db.batch();
    for (final s in students) {
      batch.insert('students', s.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ==================== EXAMS ====================
  Future<List<Exam>> getExams() async {
    final db = await database;
    final res = await db.query('exams', orderBy: 'id DESC');
    return res.map((e) => Exam.fromMap(e)).toList();
  }

  Future<Exam?> getActiveExam() async {
    final db = await database;
    final res = await db.query('exams', where: 'is_active = 1', limit: 1);
    if (res.isNotEmpty) return Exam.fromMap(res.first);
    final all = await getExams();
    if (all.isNotEmpty) return all.first;
    return null;
  }

  Future<int> addExam(Exam exam) async {
    final db = await database;
    return await db.insert('exams', exam.toMap());
  }

  Future<void> updateExam(Exam exam) async {
    final db = await database;
    await db.update('exams', exam.toMap(), where: 'id = ?', whereArgs: [exam.id]);
  }

  Future<void> deleteExam(int id) async {
    final db = await database;
    await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MARKS ====================
  Future<List<Mark>> getMarksForExamAndClass(int examId, int classId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT m.* FROM marks m
      INNER JOIN students s ON m.student_id = s.id
      WHERE m.exam_id = ? AND s.class_id = ?
    ''', [examId, classId]);
    return res.map((e) => Mark.fromMap(e)).toList();
  }

  Future<void> saveOrUpdateMark(Mark mark) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO marks (exam_id, student_id, subject_id, score, is_absent)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(exam_id, student_id, subject_id) DO UPDATE SET
        score = excluded.score,
        is_absent = excluded.is_absent
    ''', [
      mark.examId,
      mark.studentId,
      mark.subjectId,
      mark.score,
      mark.isAbsent ? 1 : 0,
    ]);
  }

  Future<void> saveMarksBatch(List<Mark> marksList) async {
    final db = await database;
    final batch = db.batch();
    for (final m in marksList) {
      batch.rawInsert('''
        INSERT INTO marks (exam_id, student_id, subject_id, score, is_absent)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(exam_id, student_id, subject_id) DO UPDATE SET
          score = excluded.score,
          is_absent = excluded.is_absent
      ''', [
        m.examId,
        m.studentId,
        m.subjectId,
        m.score,
        m.isAbsent ? 1 : 0,
      ]);
    }
    await batch.commit(noResult: true);
  }

  // ==================== SAUVEGARDE & PORTABILITÉ SQL (CROSS-PLATFORM) ====================
  Future<String> getDatabasePath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'ElyxiaEB', 'elyxia_eb.db');
  }

  Future<List<int>> exportDatabaseBytes() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (!await file.exists()) {
      await database; // force initialisation
    }
    return await file.readAsBytes();
  }

  Future<void> importDatabaseBytes(List<int> newBytes) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final path = await getDatabasePath();
    final file = File(path);
    await file.writeAsBytes(newBytes, flush: true);
    _database = await _initDB('elyxia_eb.db');
  }

  Future<String> exportSqlScript() async {
    final db = await database;
    final buffer = StringBuffer();
    buffer.writeln("-- ========================================================");
    buffer.writeln("-- Elyxia EB - Sauvegarde SQL Portative (Windows & macOS)");
    buffer.writeln("-- Établissement : Complexe Scolaire Les Victorieux");
    buffer.writeln("-- ========================================================\n");

    final tables = ['settings', 'classes', 'subjects', 'students', 'exams', 'marks'];
    for (final table in tables) {
      final rows = await db.query(table);
      buffer.writeln("\n-- Table: $table (${rows.length} enregistrements)");
      for (final row in rows) {
        final cols = row.keys.join(', ');
        final values = row.values.map((v) {
          if (v == null) return "NULL";
          if (v is num) return "$v";
          return "'${v.toString().replaceAll("'", "''")}'";
        }).join(', ');
        buffer.writeln("INSERT OR REPLACE INTO $table ($cols) VALUES ($values);");
      }
    }
    return buffer.toString();
  }
}
