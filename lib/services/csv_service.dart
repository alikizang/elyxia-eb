import 'package:csv/csv.dart';

import '../models/student.dart';
import '../models/student_result.dart';
import '../models/subject.dart';

class CsvService {
  /// Importe une liste d'étudiants depuis une chaîne CSV
  static List<Student> parseStudentsCsv(String csvData, int classId) {
    // Détection automatique du délimiteur (; ou ,)
    String delimiter = ',';
    if (csvData.contains(';') && !csvData.contains(',')) {
      delimiter = ';';
    } else if (csvData.split('\n').first.contains(';')) {
      delimiter = ';';
    }

    final csvCodec = Csv(fieldDelimiter: delimiter, lineDelimiter: '\n');
    final rows = csvCodec.decode(csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    if (rows.isEmpty) return [];

    final students = <Student>[];
    // Ignorer l'en-tête s'il contient des mots comme 'nom', 'name', 'matricule'
    int startIdx = 0;
    if (rows.isNotEmpty) {
      final firstRowStr = rows.first.map((e) => e.toString().toLowerCase()).join(' ');
      if (firstRowStr.contains('nom') || firstRowStr.contains('matricule') || firstRowStr.contains('table')) {
        startIdx = 1;
      }
    }

    for (int i = startIdx; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) continue;

      final matricule = row.isNotEmpty ? row[0].toString().trim() : '';
      final tableNum = row.length > 1 ? row[1].toString().trim() : (i + 1).toString().padLeft(3, '0');
      final lastName = row.length > 2 ? row[2].toString().trim() : '';
      final firstName = row.length > 3 ? row[3].toString().trim() : '';
      final gender = row.length > 4 ? row[4].toString().trim().toUpperCase() : 'M';
      final birthDate = row.length > 5 ? row[5].toString().trim() : '';
      final birthPlace = row.length > 6 ? row[6].toString().trim() : '';

      if (lastName.isNotEmpty || firstName.isNotEmpty) {
        students.add(
          Student(
            classId: classId,
            matricule: matricule.isNotEmpty ? matricule : "VIC-$tableNum",
            tableNumber: tableNum,
            lastName: lastName,
            firstName: firstName,
            gender: (gender == 'F' || gender == 'FEMME' || gender == 'FILLE') ? 'F' : 'M',
            birthDate: birthDate,
            birthPlace: birthPlace,
          ),
        );
      }
    }

    return students;
  }

  /// Exporte la liste des étudiants en CSV
  static String exportStudentsToCsv(List<Student> students) {
    final rows = <List<dynamic>>[];
    rows.add(['Matricule', 'N° Table', 'Nom', 'Prénoms', 'Sexe', 'Date Naissance', 'Lieu Naissance']);
    for (final s in students) {
      rows.add([s.matricule, s.tableNumber, s.lastName, s.firstName, s.gender, s.birthDate, s.birthPlace]);
    }
    return Csv(fieldDelimiter: ';', lineDelimiter: '\r\n').encode(rows);
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
