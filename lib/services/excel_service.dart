import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../models/student.dart';
import '../models/student_result.dart';
import '../models/subject.dart';

class ParsedMarkEntry {
  final String tableNumber;
  final String studentName;
  final double? score;
  final bool isAbsent;

  ParsedMarkEntry({
    required this.tableNumber,
    this.studentName = '',
    this.score,
    this.isAbsent = false,
  });
}

class ExcelService {
  /// Sépare intelligemment un nom complet en Nom de famille et Prénoms
  static ({String lastName, String firstName}) splitFullName(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return (lastName: '', firstName: '');
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (lastName: parts[0].toUpperCase(), firstName: '');
    }

    // Détecte les parties entièrement en majuscules (convention togolaise/francophone pour le patronyme)
    final upperParts = <String>[];
    final otherParts = <String>[];
    for (final p in parts) {
      if (p == p.toUpperCase() && p.length > 1 && !RegExp(r'^\d+$').hasMatch(p)) {
        upperParts.add(p);
      } else {
        otherParts.add(p);
      }
    }

    if (upperParts.isNotEmpty && otherParts.isNotEmpty) {
      return (lastName: upperParts.join(' '), firstName: otherParts.join(' '));
    }

    // Par défaut : premier mot = Nom, reste = Prénoms
    return (lastName: parts[0].toUpperCase(), firstName: parts.sublist(1).join(' '));
  }

  /// Génère un fichier modèle Excel (.xlsx) pré-formaté pour l'import des élèves
  static Uint8List generateStudentsTemplateXlsx() {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Candidats';
    final sheet = excel[sheetName];

    // En-têtes (Matricule est optionnel)
    sheet.appendRow([
      TextCellValue('N° Table'),
      TextCellValue('Nom'),
      TextCellValue('Prénoms'),
      TextCellValue('Sexe (M/F)'),
      TextCellValue('Date de Naissance'),
      TextCellValue('Lieu de Naissance'),
      TextCellValue('Matricule (Optionnel)'),
      TextCellValue('Doublant (OUI/NON)'),
    ]);

    // Lignes d'exemples réalistes
    sheet.appendRow([
      TextCellValue('101'),
      TextCellValue('KOUDOSSOU'),
      TextCellValue('Koffi Jean-Luc'),
      TextCellValue('M'),
      TextCellValue('14/05/2007'),
      TextCellValue('Lomé'),
      TextCellValue('VIC-2025-0101'),
      TextCellValue('NON'),
    ]);

    sheet.appendRow([
      TextCellValue('102'),
      TextCellValue('ADJALLÉ'),
      TextCellValue('Afiwa Blandine'),
      TextCellValue('F'),
      TextCellValue('22/09/2007'),
      TextCellValue('Aného'),
      TextCellValue(''),
      TextCellValue('NON'),
    ]);

    sheet.appendRow([
      TextCellValue('103'),
      TextCellValue('MENSAH'),
      TextCellValue('Kokou Mawunyo'),
      TextCellValue('M'),
      TextCellValue('03/01/2008'),
      TextCellValue('Kpalimé'),
      TextCellValue(''),
      TextCellValue('OUI'),
    ]);

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Parse un fichier Excel (.xlsx / .xls) et renvoie la liste des candidats
  static List<Student> parseStudentsXlsx(
    List<int> bytes,
    int classId, {
    required String academicYear,
    int startDefaultTableNumber = 101,
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    // Recherche de la première feuille contenant des données textuelles utiles
    Sheet? targetSheet;
    for (final table in excel.tables.values) {
      final hasData = table.rows.any((row) => row.any((cell) => _cellToString(cell).isNotEmpty));
      if (hasData) {
        targetSheet = table;
        break;
      }
    }
    if (targetSheet == null || targetSheet.rows.isEmpty) return [];

    final rows = targetSheet.rows;
    final students = <Student>[];

    int startRow = 0;
    int colTable = -1;
    int colMatricule = -1;
    int colLastName = -1;
    int colFirstName = -1;
    int colFullName = -1;
    int colGender = -1;
    int colBirthDate = -1;
    int colBirthPlace = -1;
    int colRepeater = -1;

    for (int r = 0; r < rows.length && r < 6; r++) {
      final row = rows[r];
      final rowStr = row.map((cell) => _cellToString(cell).toLowerCase().trim()).toList();

      final hasNom = rowStr.any((c) => c.contains('nom'));
      final hasMatricule = rowStr.any((c) => c.contains('matricule'));
      final hasTable = rowStr.any((c) => c.contains('table') || c.contains('n°') || c.contains('numéro'));
      final hasPrenom = rowStr.any((c) => c.contains('prénom') || c.contains('prenom'));

      if (hasNom || hasMatricule || hasTable || hasPrenom) {
        startRow = r + 1;
        for (int c = 0; c < rowStr.length; c++) {
          final val = rowStr[c];
          final withoutPrenom = val.replaceAll('prénom', '').replaceAll('prenom', '');
          final hasNom = withoutPrenom.contains('nom');
          final hasPrenom = val.contains('prénom') || val.contains('prenom');

          if (val.contains('table') || val.contains('n°') || val.contains('numéro') || val == 'n') {
            colTable = c;
          } else if (val.contains('matricule') || val.contains('mtle') || val.contains('identifiant')) {
            colMatricule = c;
          } else if ((hasNom && hasPrenom) || val.contains('complet') || (hasNom && (val.contains('&') || val.contains('et')))) {
            colFullName = c;
          } else if (hasNom) {
            colLastName = c;
          } else if (hasPrenom) {
            colFirstName = c;
          } else if (val.contains('sexe') || val.contains('genre') || val == 'm/f') {
            colGender = c;
          } else if (val.contains('date') || val.contains('naissance') || val.contains('né(e)')) {
            colBirthDate = c;
          } else if (val.contains('lieu')) {
            colBirthPlace = c;
          } else if (val.contains('doublant') || val.contains('redoublant') || val.contains('rep')) {
            colRepeater = c;
          }
        }
        break;
      }
    }

    if (colLastName == -1 && colFirstName == -1 && colFullName == -1) {
      colTable = 0;
      colLastName = 1;
      colFirstName = 2;
      colGender = 3;
      colBirthDate = 4;
      colBirthPlace = 5;
      colMatricule = 6;
      colRepeater = 7;
      startRow = 1;
    }

    int autoTableCounter = startDefaultTableNumber;

    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String getVal(int col) {
        if (col < 0 || col >= row.length) return '';
        return _cellToString(row[col]);
      }

      String lastName = '';
      String firstName = '';

      if (colLastName >= 0 && colFirstName >= 0) {
        lastName = getVal(colLastName);
        firstName = getVal(colFirstName);
      } else if (colFullName >= 0) {
        final full = getVal(colFullName);
        final split = splitFullName(full);
        lastName = split.lastName;
        firstName = split.firstName;
      } else if (colLastName >= 0) {
        final full = getVal(colLastName);
        final split = splitFullName(full);
        lastName = split.lastName;
        firstName = split.firstName;
      } else if (colFirstName >= 0) {
        final full = getVal(colFirstName);
        final split = splitFullName(full);
        lastName = split.lastName;
        firstName = split.firstName;
      }

      if (lastName.isEmpty && firstName.isEmpty) continue;

      String tableNum = colTable >= 0 ? getVal(colTable) : '';
      if (tableNum.isEmpty) {
        tableNum = (autoTableCounter++).toString().padLeft(3, '0');
      } else {
        final parsed = int.tryParse(tableNum);
        if (parsed != null && parsed >= autoTableCounter) {
          autoTableCounter = parsed + 1;
        }
      }

      // Matricule est optionnel (vide si non spécifié)
      final matricule = colMatricule >= 0 ? getVal(colMatricule) : '';

      final rawGender = (colGender >= 0 ? getVal(colGender) : 'M').toUpperCase().trim();
      final gender = (rawGender == 'F' || rawGender.contains('FILLE') || rawGender.contains('FEMME')) ? 'F' : 'M';

      final birthDate = colBirthDate >= 0 ? getVal(colBirthDate) : '';
      final birthPlace = colBirthPlace >= 0 ? getVal(colBirthPlace) : '';

      final rawRepeater = (colRepeater >= 0 ? getVal(colRepeater) : '').toUpperCase().trim();
      final isRepeater = rawRepeater == 'OUI' || rawRepeater == 'TRUE' || rawRepeater == '1' || rawRepeater == 'D';

      students.add(
        Student(
          classId: classId,
          matricule: matricule,
          tableNumber: tableNum,
          lastName: lastName.toUpperCase(),
          firstName: firstName,
          gender: gender,
          birthDate: birthDate,
          birthPlace: birthPlace,
          isRepeater: isRepeater,
          academicYear: academicYear,
        ),
      );
    }

    return students;
  }

  // ==================== GESTION DES NOTES (MARKS) ====================

  /// Génère une feuille Excel pré-remplie avec la liste des élèves de la classe
  static Uint8List generateMarksTemplateXlsx({
    required String subjectName,
    required String className,
    required String examTitle,
    required List<Student> students,
  }) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Notes';
    final sheet = excel[sheetName];

    // En-têtes
    sheet.appendRow([
      TextCellValue('N° Table'),
      TextCellValue('Nom & Prénoms'),
      TextCellValue('Note /20'),
      TextCellValue('Absent (OUI/NON)'),
    ]);

    // Remplissage avec les candidats existants
    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.tableNumber),
        TextCellValue(s.fullName),
        TextCellValue(''), // Note vide à saisir
        TextCellValue('NON'),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Parse un fichier Excel contenant des notes
  static List<ParsedMarkEntry> parseMarksXlsx(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    Sheet? targetSheet;
    for (final table in excel.tables.values) {
      final hasData = table.rows.any((row) => row.any((cell) => _cellToString(cell).isNotEmpty));
      if (hasData) {
        targetSheet = table;
        break;
      }
    }
    if (targetSheet == null || targetSheet.rows.isEmpty) return [];

    final rows = targetSheet.rows;
    final entries = <ParsedMarkEntry>[];

    int startRow = 0;
    int colTable = -1;
    int colName = -1;
    int colScore = -1;
    int colAbsent = -1;

    for (int r = 0; r < rows.length && r < 6; r++) {
      final row = rows[r];
      final rowStr = row.map((c) => _cellToString(c).toLowerCase().trim()).toList();

      final hasScore = rowStr.any((c) => c.contains('note') || c.contains('score') || c.contains('/20'));
      final hasTable = rowStr.any((c) => c.contains('table') || c.contains('n°') || c.contains('numéro'));

      if (hasScore || hasTable) {
        startRow = r + 1;
        for (int c = 0; c < rowStr.length; c++) {
          final val = rowStr[c];
          if (val.contains('table') || val.contains('n°') || val.contains('numéro')) {
            colTable = c;
          } else if (val.contains('nom') || val.contains('élève') || val.contains('candidat') || val.contains('prénom')) {
            colName = c;
          } else if (val.contains('note') || val.contains('score') || val.contains('/20')) {
            colScore = c;
          } else if (val.contains('abs') || val.contains('absence')) {
            colAbsent = c;
          }
        }
        break;
      }
    }

    if (colTable == -1 && colScore == -1) {
      colTable = 0;
      colName = 1;
      colScore = 2;
      colAbsent = 3;
      startRow = 1;
    }

    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String getVal(int col) {
        if (col < 0 || col >= row.length) return '';
        return _cellToString(row[col]);
      }

      final tableNum = colTable >= 0 ? getVal(colTable).trim() : '';
      final studentName = colName >= 0 ? getVal(colName).trim() : '';
      String rawScore = colScore >= 0 ? getVal(colScore).trim().replaceAll(',', '.') : '';
      final rawAbsent = colAbsent >= 0 ? getVal(colAbsent).trim().toUpperCase() : '';

      // Gestion directe des mentions "ABS" ou "A" écrites directement dans la colonne Note
      bool isAbsent = rawAbsent == 'OUI' || rawAbsent == 'ABS' || rawAbsent == 'TRUE' || rawAbsent == '1';
      if (rawScore.toUpperCase() == 'ABS' || rawScore.toUpperCase() == 'A' || rawScore.toUpperCase() == 'ABSENT') {
        isAbsent = true;
        rawScore = '';
      }

      // Nettoie les suffixes éventuels comme "/20"
      rawScore = rawScore.replaceAll('/20', '').trim();

      double? score;
      if (!isAbsent && rawScore.isNotEmpty) {
        final parsed = double.tryParse(rawScore);
        if (parsed != null && parsed >= 0 && parsed <= 20) {
          score = parsed;
        }
      }

      if (tableNum.isNotEmpty || studentName.isNotEmpty) {
        entries.add(
          ParsedMarkEntry(
            tableNumber: tableNum,
            studentName: studentName,
            score: score,
            isAbsent: isAbsent,
          ),
        );
      }
    }

    return entries;
  }

  /// Exporte la liste des candidats d'une classe au format Excel (.xlsx)
  static Uint8List exportStudentsToXlsx({
    required List<Student> students,
    required String className,
    required String academicYear,
  }) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Candidats';
    final sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue('N° Table'),
      TextCellValue('Matricule'),
      TextCellValue('Nom'),
      TextCellValue('Prénoms'),
      TextCellValue('Sexe'),
      TextCellValue('Date de Naissance'),
      TextCellValue('Lieu de Naissance'),
      TextCellValue('Classe'),
      TextCellValue('Année Académique'),
      TextCellValue('Doublant'),
    ]);

    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.tableNumber),
        TextCellValue(s.matricule),
        TextCellValue(s.lastName),
        TextCellValue(s.firstName),
        TextCellValue(s.gender),
        TextCellValue(s.birthDate),
        TextCellValue(s.birthPlace),
        TextCellValue(className),
        TextCellValue(academicYear),
        TextCellValue(s.isRepeater ? 'OUI' : 'NON'),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Exporte les résultats officiels complets de la classe au format Excel (.xlsx)
  static Uint8List exportClassResultsToXlsx(List<Subject> subjects, List<StudentResult> results) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Délibérations';
    final sheet = excel[sheetName];

    final header = <CellValue>[
      TextCellValue('Rang'),
      TextCellValue('N° Table'),
      TextCellValue('Matricule'),
      TextCellValue('Nom & Prénoms'),
      TextCellValue('Sexe'),
    ];
    for (final s in subjects) {
      header.add(TextCellValue('${s.name} (${s.coefficient.toInt()})'));
    }
    header.addAll([
      TextCellValue('Total Points'),
      TextCellValue('Moyenne /20'),
      TextCellValue('Décision'),
      TextCellValue('Mention'),
    ]);
    sheet.appendRow(header);

    for (final r in results) {
      final row = <CellValue>[
        TextCellValue(r.rankFormatted),
        TextCellValue(r.student.tableNumber),
        TextCellValue(r.student.matricule),
        TextCellValue(r.student.fullName),
        TextCellValue(r.student.gender),
      ];
      for (final g in r.grades) {
        row.add(TextCellValue(g.scoreFormatted));
      }
      row.addAll([
        TextCellValue(r.totalPointsFormatted),
        TextCellValue(r.averageFormatted),
        TextCellValue(r.decision),
        TextCellValue(r.mention),
      ]);
      sheet.appendRow(row);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  static String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final val = cell.value;
    if (val is TextCellValue) {
      return val.value.toString().trim();
    }
    if (val is IntCellValue) return val.value.toString();
    if (val is DoubleCellValue) {
      if (val.value % 1 == 0) {
        return val.value.toInt().toString();
      }
      return val.value.toString();
    }
    if (val is DateCellValue) {
      final y = val.year.toString().padLeft(4, '0');
      final m = val.month.toString().padLeft(2, '0');
      final d = val.day.toString().padLeft(2, '0');
      return '$d/$m/$y';
    }
    return val.toString().trim();
  }
}
