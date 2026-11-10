import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../models/student.dart';

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

    Sheet? targetSheet;
    for (final table in excel.tables.values) {
      if (table.rows.isNotEmpty) {
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
    int colGender = -1;
    int colBirthDate = -1;
    int colBirthPlace = -1;
    int colRepeater = -1;

    for (int r = 0; r < rows.length && r < 5; r++) {
      final row = rows[r];
      final rowStr = row.map((cell) => _cellToString(cell).toLowerCase()).toList();

      final hasNom = rowStr.any((c) => c.contains('nom') && !c.contains('prénom'));
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
          } else if (val.contains('nom') && !val.contains('prénom')) {
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
      if (row.isEmpty) continue;

      String getVal(int col) {
        if (col < 0 || col >= row.length) return '';
        return _cellToString(row[col]);
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

    // Remplissage avec les élèves existants de la classe
    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.tableNumber),
        TextCellValue(s.fullName),
        TextCellValue(''),
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
      if (table.rows.isNotEmpty) {
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

    for (int r = 0; r < rows.length && r < 5; r++) {
      final row = rows[r];
      final rowStr = row.map((c) => _cellToString(c).toLowerCase()).toList();

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
      final rawScore = colScore >= 0 ? getVal(colScore).trim().replaceAll(',', '.') : '';
      final rawAbsent = colAbsent >= 0 ? getVal(colAbsent).trim().toUpperCase() : '';

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

  static String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final val = cell.value;
    if (val is TextCellValue) return (val.value.text ?? '').trim();
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
