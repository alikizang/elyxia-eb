import 'package:csv/csv.dart';

import '../models/student.dart';
import '../models/student_result.dart';
import '../models/subject.dart';
import 'excel_service.dart';

class CsvService {
  /// Importe une liste d'étudiants depuis une chaîne CSV
  static List<Student> parseStudentsCsv(
    String csvData,
    int classId, {
    String academicYear = '2025-2026',
    int startDefaultTableNumber = 101,
  }) {
    // Détection automatique du délimiteur (; ou , ou \t)
    String delimiter = ',';
    if (csvData.contains(';') && (!csvData.contains(',') || csvData.indexOf(';') < csvData.indexOf(','))) {
      delimiter = ';';
    } else if (csvData.contains('\t') && !csvData.contains(',')) {
      delimiter = '\t';
    }

    final csvCodec = Csv(fieldDelimiter: delimiter, lineDelimiter: '\n');
    final rows = csvCodec.decode(csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    if (rows.isEmpty) return [];

    final students = <Student>[];

    int startRow = 0;
    int colTable = -1;
    int colMatricule = -1;
    int colLastName = -1;
    int colFirstName = -1;
    int colGender = -1;
    int colBirthDate = -1;
    int colBirthPlace = -1;
    int colRepeater = -1;

    for (int r = 0; r < rows.length && r < 5; r++) {
      final row = rows[r];
      final rowStr = row.map((e) => e.toString().toLowerCase().trim()).toList();

      final hasNom = rowStr.any((c) => c.contains('nom') && !c.contains('prénom') && !c.contains('prenom'));
      final hasMatricule = rowStr.any((c) => c.contains('matricule'));
      final hasTable = rowStr.any((c) => c.contains('table') || c.contains('n°') || c.contains('numéro'));

      if (hasNom || hasMatricule || hasTable) {
        startRow = r + 1;
        for (int c = 0; c < rowStr.length; c++) {
          final val = rowStr[c];
          if (val.contains('table') || val.contains('n°') || val.contains('numéro')) {
            colTable = c;
          } else if (val.contains('matricule')) {
            colMatricule = c;
          } else if (val.contains('nom') && !val.contains('prénom') && !val.contains('prenom')) {
            colLastName = c;
          } else if (val.contains('prénom') || val.contains('prenom')) {
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

    if (colLastName == -1 && colFirstName == -1) {
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
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) continue;

      String getVal(int col) {
        if (col < 0 || col >= row.length) return '';
        return row[col].toString().trim();
      }

      final lastName = colLastName >= 0 ? getVal(colLastName) : '';
      final firstName = colFirstName >= 0 ? getVal(colFirstName) : '';

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

      // Le matricule est optionnel (vide si non spécifié)
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

  /// Exporte la liste des étudiants en CSV
  static String exportStudentsToCsv(List<Student> students) {
    final rows = <List<dynamic>>[];
    rows.add(['N° Table', 'Nom', 'Prénoms', 'Sexe', 'Date Naissance', 'Lieu Naissance', 'Matricule', 'Doublant']);
    for (final s in students) {
      rows.add([
        s.tableNumber,
        s.lastName,
        s.firstName,
        s.gender,
        s.birthDate,
        s.birthPlace,
        s.matricule,
        s.isRepeater ? 'OUI' : 'NON',
      ]);
    }
    return Csv(fieldDelimiter: ';', lineDelimiter: '\r\n').encode(rows);
  }

  // ==================== GESTION DES NOTES (MARKS) ====================

  /// Génère un modèle CSV pré-rempli avec les élèves de la classe pour une matière
  static String generateMarksTemplateCsv({required List<Student> students}) {
    final rows = <List<dynamic>>[];
    rows.add(['N° Table', 'Nom & Prénoms', 'Note /20', 'Absent (OUI/NON)']);
    for (final s in students) {
      rows.add([s.tableNumber, s.fullName, '', 'NON']);
    }
    return Csv(fieldDelimiter: ';', lineDelimiter: '\r\n').encode(rows);
  }

  /// Parse un CSV contenant des notes de classe
  static List<ParsedMarkEntry> parseMarksCsv(String csvData) {
    String delimiter = ';';
    if (csvData.contains(';') && (!csvData.contains(',') || csvData.indexOf(';') < csvData.indexOf(','))) {
      delimiter = ';';
    } else if (csvData.contains(',')) {
      delimiter = ',';
    }

    final csvCodec = Csv(fieldDelimiter: delimiter, lineDelimiter: '\n');
    final rows = csvCodec.decode(csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    if (rows.isEmpty) return [];

    final entries = <ParsedMarkEntry>[];
    int startRow = 0;
    int colTable = -1;
    int colName = -1;
    int colScore = -1;
    int colAbsent = -1;

    for (int r = 0; r < rows.length && r < 5; r++) {
      final row = rows[r];
      final rowStr = row.map((c) => c.toString().toLowerCase().trim()).toList();

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
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) continue;

      String getVal(int col) {
        if (col < 0 || col >= row.length) return '';
        return row[col].toString().trim();
      }

      final tableNum = colTable >= 0 ? getVal(colTable) : '';
      final studentName = colName >= 0 ? getVal(colName) : '';
      final rawScore = colScore >= 0 ? getVal(colScore).replaceAll(',', '.') : '';
      final rawAbsent = colAbsent >= 0 ? getVal(colAbsent).toUpperCase() : '';

      final isAbsent = rawAbsent == 'OUI' || rawAbsent == 'ABS' || rawAbsent == 'TRUE' || rawAbsent == '1';
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

  /// Exporte le tableau récapitulatif complet des notes et moyennes en CSV
  static String exportClassResultsToCsv(List<Subject> subjects, List<StudentResult> results) {
    final rows = <List<dynamic>>[];
    final header = <dynamic>[
      'Rang',
      'N° Table',
      'Matricule',
      'Nom & Prénoms',
      'Sexe',
    ];
    for (final s in subjects) {
      header.add('${s.name} (${s.coefficient.toInt()})');
    }
    header.addAll(['Total Points', 'Moyenne /20', 'Décision', 'Mention']);
    rows.add(header);

    for (final r in results) {
      final row = <dynamic>[
        r.rankFormatted,
        r.student.tableNumber,
        r.student.matricule,
        r.student.fullName,
        r.student.gender,
      ];
      for (final g in r.grades) {
        row.add(g.scoreFormatted);
      }
      row.addAll([
        r.totalPointsFormatted,
        r.averageFormatted,
        r.decision,
        r.mention,
      ]);
      rows.add(row);
    }

    return Csv(fieldDelimiter: ';', lineDelimiter: '\r\n').encode(rows);
  }
}
