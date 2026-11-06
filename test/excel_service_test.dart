import 'package:flutter_test/flutter_test.dart';
import 'package:elyxia_eb/services/excel_service.dart';
import 'package:elyxia_eb/services/csv_service.dart';

void main() {
  test('ExcelService generates valid template and parses students correctly', () {
    final templateBytes = ExcelService.generateStudentsTemplateXlsx();
    expect(templateBytes.isNotEmpty, true);

    final students = ExcelService.parseStudentsXlsx(
      templateBytes,
      1,
      academicYear: '2026-2027',
    );

    expect(students.length, 3);
    expect(students[0].lastName, 'KOUDOSSOU');
    expect(students[0].firstName, 'Koffi Jean-Luc');
    expect(students[0].tableNumber, '101');
    expect(students[0].gender, 'M');
    expect(students[0].academicYear, '2026-2027');
    expect(students[0].isRepeater, false);

    expect(students[1].lastName, 'ADJALLÉ');
    expect(students[1].gender, 'F');
    expect(students[1].academicYear, '2026-2027');

    expect(students[2].lastName, 'MENSAH');
    expect(students[2].isRepeater, true);
  });

  test('CsvService parses semicolon and comma CSV with headers correctly', () {
    const csvContent = "N° Table;Matricule;Nom;Prénoms;Sexe;Date Naissance;Lieu Naissance;Doublant\n"
        "201;VIC-2026-0201;DOSSOU;Afi;F;10/02/2007;Lomé;NON\n"
        "202;VIC-2026-0202;LAWSON;Koffi;M;11/03/2007;Aného;OUI\n";

    final students = CsvService.parseStudentsCsv(
      csvContent,
      2,
      academicYear: '2026-2027',
    );

    expect(students.length, 2);
    expect(students[0].tableNumber, '201');
    expect(students[0].lastName, 'DOSSOU');
    expect(students[0].firstName, 'Afi');
    expect(students[0].gender, 'F');
    expect(students[0].academicYear, '2026-2027');
    expect(students[0].isRepeater, false);

    expect(students[1].tableNumber, '202');
    expect(students[1].gender, 'M');
    expect(students[1].isRepeater, true);
  });
}
