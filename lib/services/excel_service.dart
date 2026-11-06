import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../models/student.dart';

class ExcelService {
  /// Génère un fichier modèle Excel (.xlsx) pré-formaté pour l'import des élèves
  static Uint8List generateStudentsTemplateXlsx() {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Candidats';
    final sheet = excel[sheetName];

    // En-têtes
    sheet.appendRow([
      TextCellValue('N° Table'),
      TextCellValue('Matricule'),
      TextCellValue('Nom'),
      TextCellValue('Prénoms'),
      TextCellValue('Sexe (M/F)'),
      TextCellValue('Date de Naissance'),
      TextCellValue('Lieu de Naissance'),
      TextCellValue('Doublant (OUI/NON)'),
    ]);

    // Lignes d'exemples réalistes
    sheet.appendRow([
      TextCellValue('101'),
      TextCellValue('VIC-2025-0101'),
      TextCellValue('KOUDOSSOU'),
      TextCellValue('Koffi Jean-Luc'),
      TextCellValue('M'),
      TextCellValue('14/05/2007'),
      TextCellValue('Lomé'),
      TextCellValue('NON'),
    ]);

    sheet.appendRow([
      TextCellValue('102'),
      TextCellValue('VIC-2025-0102'),
      TextCellValue('ADJALLÉ'),
      TextCellValue('Afiwa Blandine'),
      TextCellValue('F'),
      TextCellValue('22/09/2007'),
      TextCellValue('Aného'),
      TextCellValue('NON'),
    ]);

    sheet.appendRow([
      TextCellValue('103'),
      TextCellValue('VIC-2025-0103'),
      TextCellValue('MENSAH'),
      TextCellValue('Kokou Mawunyo'),
      TextCellValue('M'),
      TextCellValue('03/01/2008'),
      TextCellValue('Kpalimé'),
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
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    // Sélectionne la première feuille contenant des données
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

    // Recherche dynamique des index de colonnes d'après l'en-tête
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

    // Si aucune colonne reconnue par en-tête, utiliser l'ordre par défaut :
    // [Table, Matricule, Nom, Prénoms, Sexe, Date, Lieu, Doublant]
    if (colLastName == -1 && colFirstName == -1) {
      colTable = 0;
      colMatricule = 1;
      colLastName = 2;
      colFirstName = 3;
      colGender = 4;
      colBirthDate = 5;
      colBirthPlace = 6;
      colRepeater = 7;
      startRow = 1;
    }

    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String getVal(int col) {
        if (col < 0 || col >= row.length) return '';
        return _cellToString(row[col]);
      }

      final lastName = colLastName >= 0 ? getVal(colLastName) : '';
      final firstName = colFirstName >= 0 ? getVal(colFirstName) : '';

      // Si le nom et le prénom sont vides, ignorer la ligne
      if (lastName.isEmpty && firstName.isEmpty) continue;

      String tableNum = colTable >= 0 ? getVal(colTable) : '';
      if (tableNum.isEmpty) {
        tableNum = (i - startRow + 1).toString().padLeft(3, '0');
      }

      String matricule = colMatricule >= 0 ? getVal(colMatricule) : '';
      if (matricule.isEmpty) {
        matricule = "VIC-$academicYear-$tableNum";
      }

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
