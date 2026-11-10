import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/academic_year.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
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
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      } catch (e) {
        // Déjà initialisé ou géré
      }
    }

    String dbDirectoryPath;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      dbDirectoryPath = p.join(docsDir.path, 'ElyxiaEB');
    } catch (_) {
      try {
        final suppDir = await getApplicationSupportDirectory();
        dbDirectoryPath = p.join(suppDir.path, 'ElyxiaEB');
      } catch (_) {
        dbDirectoryPath = p.join(Directory.current.path, 'ElyxiaEB_Data');
      }
    }

    final ebDir = Directory(dbDirectoryPath);
    if (!await ebDir.exists()) {
      await ebDir.create(recursive: true);
    }

    final path = p.join(ebDir.path, filePath);
    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Migration et vérification dynamique des tables et colonnes
    await _ensureTablesAndColumns(db);

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Paramètres de l'établissement
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        school_name TEXT NOT NULL,
        school_sub_title TEXT NOT NULL,
        school_slogan TEXT NOT NULL,
        school_address TEXT NOT NULL,
        school_po_box TEXT NOT NULL,
        school_city TEXT NOT NULL,
        school_phone TEXT NOT NULL,
        school_email TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        republic_header TEXT NOT NULL,
        director_title TEXT NOT NULL,
        director_name TEXT NOT NULL,
        jury_president_title TEXT NOT NULL,
        primary_color TEXT NOT NULL DEFAULT '#22577A',
        accent_color TEXT NOT NULL DEFAULT '#3BCC97',
        logo_base64 TEXT
      )
    ''');

    // 2. Années Académiques
    await db.execute('''
      CREATE TABLE academic_years (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_current INTEGER NOT NULL DEFAULT 0,
        is_closed INTEGER NOT NULL DEFAULT 0,
        closed_at TEXT,
        notes TEXT
      )
    ''');

    // 3. Utilisateurs & Authentification
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'admin',
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Classes (Premières et Terminales - Bac 1 et Bac 2)
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        series TEXT NOT NULL,
        exam_type TEXT NOT NULL
      )
    ''');

    // 5. Matières & Coefficients
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        coefficient REAL NOT NULL,
        order_index INTEGER NOT NULL,
        teacher_name TEXT NOT NULL DEFAULT '',
        is_optional INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
      )
    ''');

    // 6. Élèves
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
        is_repeater INTEGER NOT NULL DEFAULT 0,
        academic_year TEXT NOT NULL DEFAULT '2025-2026',
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
      )
    ''');

    // 7. Examens Blancs
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        session_date TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_closed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 8. Notes
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

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration gérée dynamiquement par _ensureTablesAndColumns
  }

  Future<void> _ensureTablesAndColumns(Database db) async {
    // Vérification de la table 'academic_years'
    await db.execute('''
      CREATE TABLE IF NOT EXISTS academic_years (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_current INTEGER NOT NULL DEFAULT 0,
        is_closed INTEGER NOT NULL DEFAULT 0,
        closed_at TEXT,
        notes TEXT
      )
    ''');

    // Seed années académiques si vide
    final yrRows = await db.rawQuery('SELECT COUNT(*) as count FROM academic_years');
    final yrCount = (yrRows.first['count'] as num?)?.toInt() ?? 0;
    if (yrCount == 0) {
      await db.insert('academic_years', {
        'name': '2024-2025',
        'is_current': 0,
        'is_closed': 1,
        'closed_at': '30/06/2025',
        'notes': 'Année précédente clôturée',
      });
      await db.insert('academic_years', {
        'name': '2025-2026',
        'is_current': 1,
        'is_closed': 0,
        'closed_at': null,
        'notes': 'Année scolaire en cours',
      });
      await db.insert('academic_years', {
        'name': '2026-2027',
        'is_current': 0,
        'is_closed': 0,
        'closed_at': null,
        'notes': 'Prochaine session',
      });
    }

    // Vérification de la table 'users'
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'admin',
        created_at TEXT NOT NULL
      )
    ''');

    // Seed admin par défaut si vide
    final userRows = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final userCount = (userRows.first['count'] as num?)?.toInt() ?? 0;
    if (userCount == 0) {
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123',
        'full_name': 'Direction Générale',
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('users', {
        'username': 'enseignant',
        'password': 'prof123',
        'full_name': 'Enseignant / Saisie',
        'role': 'teacher',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Colonnes dynamiques dans 'settings'
    await _safeAddColumn(db, 'settings', 'school_slogan', "TEXT NOT NULL DEFAULT 'Discipline - Travail - Succès'");
    await _safeAddColumn(db, 'settings', 'school_po_box', "TEXT NOT NULL DEFAULT '23 BP 124 Lomé-TOGO'");
    await _safeAddColumn(db, 'settings', 'school_city', "TEXT NOT NULL DEFAULT 'Zopomahé, Sanguéra — Lomé-TOGO'");
    await _safeAddColumn(db, 'settings', 'primary_color', "TEXT NOT NULL DEFAULT '#22577A'");
    await _safeAddColumn(db, 'settings', 'accent_color', "TEXT NOT NULL DEFAULT '#3BCC97'");
    await _safeAddColumn(db, 'settings', 'logo_base64', "TEXT");
    await _safeAddColumn(db, 'settings', 'director_signature_base64', "TEXT");
    await _safeAddColumn(db, 'settings', 'jury_signature_base64', "TEXT");
    await _safeAddColumn(db, 'settings', 'school_stamp_base64', "TEXT");
    await _safeAddColumn(db, 'settings', 'auto_apply_director_sig', "INTEGER NOT NULL DEFAULT 1");
    await _safeAddColumn(db, 'settings', 'auto_apply_jury_sig', "INTEGER NOT NULL DEFAULT 0");
    await _safeAddColumn(db, 'settings', 'auto_apply_stamp', "INTEGER NOT NULL DEFAULT 1");

    // Colonnes dynamiques dans 'students'
    await _safeAddColumn(db, 'students', 'is_repeater', "INTEGER NOT NULL DEFAULT 0");
    await _safeAddColumn(db, 'students', 'academic_year', "TEXT NOT NULL DEFAULT '2025-2026'");

    // Colonnes dynamiques dans 'subjects'
    await _safeAddColumn(db, 'subjects', 'teacher_name', "TEXT NOT NULL DEFAULT ''");
    await _safeAddColumn(db, 'subjects', 'is_optional', "INTEGER NOT NULL DEFAULT 0");

    // Colonnes dynamiques dans 'exams'
    await _safeAddColumn(db, 'exams', 'is_closed', "INTEGER NOT NULL DEFAULT 0");
  }

  Future<void> _safeAddColumn(Database db, String table, String column, String definition) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final exists = info.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
      }
    } catch (_) {}
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Paramètres initiaux
    final defaultSettings = AppSettings(
      schoolName: "COMPLEXE SCOLAIRE LES VICTORIEUX",
      schoolSubTitle: "Lycée Privé Laïc — BAC 1 & BAC 2",
      schoolSlogan: "Discipline - Travail - Succès",
      schoolAddress: "Zopomahé, Sanguéra",
      schoolPoBox: "23 BP 124 Lomé-TOGO",
      schoolCity: "Lomé - TOGO",
      schoolPhone: "+228 90 41 07 07 / 90 12 34 56",
      schoolEmail: "direction@lesvictorieux.tg",
      academicYear: "2025-2026",
      republicHeader: "RÉPUBLIQUE TOGOLAISE\nTravail - Liberté - Patrie\nMINISTÈRE DE L'EDUCATION NATIONALE",
      directorTitle: "Le Directeur / Chef d'Établissement",
      directorName: "Direction Générale",
      juryPresidentTitle: "Le Président du Jury",
      primaryColorHex: "#22577A",
      accentColorHex: "#3BCC97",
    );
    await db.insert('settings', defaultSettings.toMap());

    // 2. Examen Blanc Initial
    final examId = await db.insert('exams', {
      'title': 'Examen Blanc Régional N°1',
      'session_date': 'Mars 2026',
      'academic_year': '2025-2026',
      'is_active': 1,
      'is_closed': 0,
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

    // 4. Matières et Coefficients officiels pour le Togo avec professeurs exemples
    await _insertSubjects(db, classIds['1ère A4']!, [
      Subject(classId: classIds['1ère A4']!, name: 'Français', code: 'FRA', coefficient: 4.0, orderIndex: 1, teacherName: 'AGBOZOUHOE Kodjovi'),
      Subject(classId: classIds['1ère A4']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 2, teacherName: 'SANTE Sédou'),
      Subject(classId: classIds['1ère A4']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 3.0, orderIndex: 3, teacherName: 'ADJAYI Dosseh'),
      Subject(classId: classIds['1ère A4']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 3.0, orderIndex: 4, teacherName: 'AGBASSE Kossi Sondé'),
      Subject(classId: classIds['1ère A4']!, name: 'Allemand / Espagnol (LV2)', code: 'LV2', coefficient: 3.0, orderIndex: 5, teacherName: 'TAGBA Lidaou'),
      Subject(classId: classIds['1ère A4']!, name: 'Mathématiques', code: 'MATH', coefficient: 2.0, orderIndex: 6, teacherName: 'KEMEY Dotsè'),
      Subject(classId: classIds['1ère A4']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 2.0, orderIndex: 7, teacherName: 'APALOO Essi Dogbeda'),
      Subject(classId: classIds['1ère A4']!, name: 'Sciences Physiques', code: 'SP', coefficient: 1.0, orderIndex: 8, teacherName: 'KPATCHIDE Amou Noël'),
      Subject(classId: classIds['1ère A4']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 9, teacherName: 'NINGUEMPIEN L.'),
      Subject(classId: classIds['1ère A4']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 10, teacherName: 'NANGBANDA Bilizam'),
    ]);

    await _insertSubjects(db, classIds['1ère D']!, [
      Subject(classId: classIds['1ère D']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 4.0, orderIndex: 1, teacherName: 'APALOO Essi Dogbeda'),
      Subject(classId: classIds['1ère D']!, name: 'Mathématiques', code: 'MATH', coefficient: 4.0, orderIndex: 2, teacherName: 'KEMEY Dotsè'),
      Subject(classId: classIds['1ère D']!, name: 'Sciences Physiques', code: 'SP', coefficient: 4.0, orderIndex: 3, teacherName: 'KPATCHIDE Amou Noël'),
      Subject(classId: classIds['1ère D']!, name: 'Français', code: 'FRA', coefficient: 3.0, orderIndex: 4, teacherName: 'AGBOZOUHOE Kodjovi'),
      Subject(classId: classIds['1ère D']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 5, teacherName: 'SANTE Sédou'),
      Subject(classId: classIds['1ère D']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 2.0, orderIndex: 6, teacherName: 'AGBASSE Kossi Sondé'),
      Subject(classId: classIds['1ère D']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 2.0, orderIndex: 7, teacherName: 'ADJAYI Dosseh'),
      Subject(classId: classIds['1ère D']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 8, teacherName: 'NINGUEMPIEN L.'),
      Subject(classId: classIds['1ère D']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 9, teacherName: 'NANGBANDA Bilizam'),
    ]);

    await _insertSubjects(db, classIds['Terminale D']!, [
      Subject(classId: classIds['Terminale D']!, name: 'Sciences de la Vie et de la Terre', code: 'SVT', coefficient: 5.0, orderIndex: 1, teacherName: 'APALOO Essi Dogbeda'),
      Subject(classId: classIds['Terminale D']!, name: 'Sciences Physiques', code: 'SP', coefficient: 4.0, orderIndex: 2, teacherName: 'KPATCHIDE Amou Noël'),
      Subject(classId: classIds['Terminale D']!, name: 'Mathématiques', code: 'MATH', coefficient: 4.0, orderIndex: 3, teacherName: 'KEMEY Dotsè'),
      Subject(classId: classIds['Terminale D']!, name: 'Philosophie', code: 'PHILO', coefficient: 2.0, orderIndex: 4, teacherName: 'SANTE Sédou'),
      Subject(classId: classIds['Terminale D']!, name: 'Français', code: 'FRA', coefficient: 2.0, orderIndex: 5, teacherName: 'AGBOZOUHOE Kodjovi'),
      Subject(classId: classIds['Terminale D']!, name: 'Anglais (LV1)', code: 'ANG', coefficient: 2.0, orderIndex: 6, teacherName: 'AGBASSE Kossi Sondé'),
      Subject(classId: classIds['Terminale D']!, name: 'Histoire - Géographie', code: 'HIST-GEO', coefficient: 2.0, orderIndex: 7, teacherName: 'ADJAYI Dosseh'),
      Subject(classId: classIds['Terminale D']!, name: 'Éducation Civique et Morale', code: 'ECM', coefficient: 1.0, orderIndex: 8, teacherName: 'NINGUEMPIEN L.'),
      Subject(classId: classIds['Terminale D']!, name: 'Éducation Physique et Sportive', code: 'EPS', coefficient: 1.0, orderIndex: 9, teacherName: 'NANGBANDA Bilizam'),
    ]);

    // 5. Exemples d'élèves pour la Terminale D
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
        isRepeater: false,
        academicYear: '2025-2026',
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
        isRepeater: false,
        academicYear: '2025-2026',
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
        isRepeater: true,
        academicYear: '2025-2026',
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
        isRepeater: false,
        academicYear: '2025-2026',
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
        isRepeater: false,
        academicYear: '2025-2026',
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
      [16.5, 15.0, 16.0, 14.0, 13.5, 15.0, 14.0, 16.0, 17.0],
      [14.0, 13.5, 14.0, 13.0, 14.5, 14.0, 13.0, 15.0, 16.0],
      [11.5, 10.0, 11.0, 10.5, 11.0, 12.0, 10.0, 13.0, 15.0],
      [10.0, 10.5, 9.5, 11.0, 10.0, 11.5, 10.0, 12.0, 14.0],
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

  // ==================== ANNÉES ACADÉMIQUES ====================
  Future<List<AcademicYear>> getAcademicYears() async {
    final db = await database;
    final res = await db.query('academic_years', orderBy: 'name DESC');
    return res.map((e) => AcademicYear.fromMap(e)).toList();
  }

  Future<AcademicYear> getActiveAcademicYear() async {
    final db = await database;
    final res = await db.query('academic_years', where: 'is_current = 1', limit: 1);
    if (res.isNotEmpty) {
      return AcademicYear.fromMap(res.first);
    }
    final all = await getAcademicYears();
    if (all.isNotEmpty) return all.first;
    return AcademicYear(name: '2025-2026', isCurrent: true, isClosed: false);
  }

  Future<int> addAcademicYear(AcademicYear year) async {
    final db = await database;
    if (year.isCurrent) {
      await db.update('academic_years', {'is_current': 0});
    }
    final id = await db.insert('academic_years', year.toMap());
    if (year.isCurrent) {
      final settings = await getSettings();
      await updateSettings(settings.copyWith(academicYear: year.name));
    }
    return id;
  }

  Future<void> setCurrentAcademicYear(int id) async {
    final db = await database;
    await db.update('academic_years', {'is_current': 0});
    await db.update('academic_years', {'is_current': 1}, where: 'id = ?', whereArgs: [id]);
    final active = await db.query('academic_years', where: 'id = ?', whereArgs: [id]);
    if (active.isNotEmpty) {
      final yr = AcademicYear.fromMap(active.first);
      final settings = await getSettings();
      await updateSettings(settings.copyWith(academicYear: yr.name));
    }
  }

  Future<void> toggleCloseAcademicYear(int id, bool isClosed) async {
    final db = await database;
    final now = isClosed ? DateTime.now().toIso8601String() : null;
    await db.update(
      'academic_years',
      {'is_closed': isClosed ? 1 : 0, 'closed_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAcademicYear(int id) async {
    final db = await database;
    await db.delete('academic_years', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== UTILISATEURS & AUTH ====================
  Future<AppUser?> authenticate(String username, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'LOWER(username) = ? AND password = ?',
      whereArgs: [username.trim().toLowerCase(), password],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return AppUser.fromMap(res.first);
    }
    return null;
  }

  Future<List<AppUser>> getUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'id ASC');
    return res.map((e) => AppUser.fromMap(e)).toList();
  }

  Future<int> addUser(AppUser user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<void> updateUser(AppUser user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    final db = await database;
    await db.update('users', {'password': newPassword}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
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
  Future<List<Student>> getStudentsForClass(int classId, {String? academicYear}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (academicYear != null && academicYear.isNotEmpty) {
      res = await db.query(
        'students',
        where: 'class_id = ? AND academic_year = ?',
        whereArgs: [classId, academicYear],
        orderBy: 'table_number ASC, last_name ASC',
      );
    } else {
      res = await db.query(
        'students',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'table_number ASC, last_name ASC',
      );
    }
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

  /// Détermine le prochain numéro de table automatique pour une classe donnée
  Future<String> getNextTableNumber(int classId, {String? academicYear}) async {
    final students = await getStudentsForClass(classId, academicYear: academicYear);
    if (students.isEmpty) {
      final cls = await getClassById(classId);
      final idx = cls?.id ?? classId;
      final prefix = idx > 0 ? idx : 1;
      return "${prefix}01";
    }
    int maxNum = 0;
    for (final s in students) {
      final parsed = int.tryParse(s.tableNumber);
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      }
    }
    if (maxNum > 0) {
      return (maxNum + 1).toString().padLeft(3, '0');
    }
    return (students.length + 101).toString().padLeft(3, '0');
  }

  /// Réassigne et numérote automatiquement tous les candidats d'une classe (ex: par ordre alphabétique)
  Future<int> renumberStudentsForClass({
    required int classId,
    required String academicYear,
    int startNumber = 101,
    bool sortByAlphabetical = true,
  }) async {
    final db = await database;
    final students = await getStudentsForClass(classId, academicYear: academicYear);
    if (students.isEmpty) return 0;

    final sorted = List<Student>.from(students);
    if (sortByAlphabetical) {
      sorted.sort((a, b) {
        final lastCmp = a.lastName.toUpperCase().trim().compareTo(b.lastName.toUpperCase().trim());
        if (lastCmp != 0) return lastCmp;
        return a.firstName.toUpperCase().trim().compareTo(b.firstName.toUpperCase().trim());
      });
    }

    final batch = db.batch();
    for (int i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final newTableNumber = (startNumber + i).toString().padLeft(3, '0');
      batch.update(
        'students',
        {'table_number': newTableNumber},
        where: 'id = ?',
        whereArgs: [s.id],
      );
    }
    await batch.commit(noResult: true);
    return sorted.length;
  }

  Future<int> importStudentsFromPreviousYear({
    required List<Student> students,
    required int targetClassId,
    required String targetAcademicYear,
    bool autoRenumber = true,
  }) async {
    final db = await database;
    int nextTableNum = 1;
    final existing = await getStudentsForClass(targetClassId, academicYear: targetAcademicYear);
    if (existing.isNotEmpty) {
      for (final s in existing) {
        final parsed = int.tryParse(s.tableNumber);
        if (parsed != null && parsed >= nextTableNum) {
          nextTableNum = parsed + 1;
        }
      }
    }

    final batch = db.batch();
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final tableNum = autoRenumber ? (nextTableNum + i).toString().padLeft(3, '0') : s.tableNumber;
      final newStudent = Student(
        classId: targetClassId,
        matricule: s.matricule,
        tableNumber: tableNum,
        lastName: s.lastName,
        firstName: s.firstName,
        gender: s.gender,
        birthDate: s.birthDate,
        birthPlace: s.birthPlace,
        isRepeater: s.isRepeater,
        academicYear: targetAcademicYear,
      );
      batch.insert('students', newStudent.toMap());
    }
    await batch.commit(noResult: true);
    return students.length;
  }

  // ==================== EXAMS ====================
  Future<List<Exam>> getExams({String? academicYear}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (academicYear != null && academicYear.isNotEmpty) {
      res = await db.query(
        'exams',
        where: 'academic_year = ?',
        whereArgs: [academicYear],
        orderBy: 'id DESC',
      );
    } else {
      res = await db.query('exams', orderBy: 'id DESC');
    }
    return res.map((e) => Exam.fromMap(e)).toList();
  }

  Future<Exam?> getActiveExam({String? academicYear}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (academicYear != null && academicYear.isNotEmpty) {
      res = await db.query(
        'exams',
        where: 'academic_year = ? AND is_active = 1',
        whereArgs: [academicYear],
        limit: 1,
      );
    } else {
      res = await db.query('exams', where: 'is_active = 1', limit: 1);
    }
    if (res.isNotEmpty) return Exam.fromMap(res.first);
    final all = await getExams(academicYear: academicYear);
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

  Future<void> setActiveExam(int examId, String academicYear) async {
    final db = await database;
    await db.transaction((txn) async {
      // Désactiver toutes les autres sessions de l'année
      await txn.update('exams', {'is_active': 0}, where: 'academic_year = ?', whereArgs: [academicYear]);
      // Activer la session sélectionnée
      await txn.update('exams', {'is_active': 1}, where: 'id = ?', whereArgs: [examId]);
    });
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
    buffer.writeln("-- Export intégral : Données, Années, Utilisateurs, Paramètres");
    buffer.writeln("-- Date d'export : ${DateTime.now().toIso8601String()}");
    buffer.writeln("-- ========================================================\n");

    final tables = [
      'settings',
      'academic_years',
      'users',
      'classes',
      'subjects',
      'students',
      'exams',
      'marks',
    ];

    for (final table in tables) {
      try {
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
      } catch (_) {}
    }
    return buffer.toString();
  }

  /// Supprime les données de démonstration (élèves et notes) pour démarrer l'utilisation réelle
  Future<void> clearDemoData({bool deleteExams = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('marks');
      await txn.delete('students');
      if (deleteExams) {
        await txn.delete('exams');
      }
    });
  }

  /// Réinitialise l'application aux paramètres d'usine complets
  Future<void> resetToFactoryDefaults() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('marks');
      await txn.delete('students');
      await txn.delete('exams');
      await txn.delete('subjects');
      await txn.delete('classes');
      await txn.delete('users');
      await txn.delete('academic_years');
      await txn.delete('settings');
    });
    await _seedInitialData(db);
    await _ensureTablesAndColumns(db);
  }
}
