import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:elyxia_eb/services/pdf_service.dart';
import 'package:elyxia_eb/models/app_settings.dart';
import 'package:elyxia_eb/models/exam.dart';
import 'package:elyxia_eb/models/school_class.dart';
import 'package:elyxia_eb/models/student.dart';
import 'package:elyxia_eb/models/student_result.dart';

void main() {
  test('PageTheme buildBackground watermark test', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          buildBackground: (context) {
            return pw.Center(
              child: pw.Opacity(
                opacity: 0.05,
                child: pw.Text('WATERMARK'),
              ),
            );
          },
        ),
        build: (context) => [
          pw.Text('Hello PV'),
        ],
      ),
    );

    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, true);
  });

  test('PdfService generates single report card and PV report with watermark', () async {
    final settings = AppSettings(
      schoolName: 'Complexe Scolaire Les Victorieux',
      academicYear: '2026-2027',
      primaryColorHex: '#4A148C',
      accentColorHex: '#6A1B9A',
    );
    final exam = Exam(
      id: 1,
      title: 'Examen Blanc Régional N°1',
      academicYear: '2026-2027',
      sessionDate: 'Mars 2026',
    );
    final schoolClass = SchoolClass(
      id: 1,
      name: 'Terminale D',
      level: 'Terminale',
      series: 'D',
      examType: 'BAC 2',
    );
    final student = Student(
      id: 1,
      classId: 1,
      lastName: 'KOUDOSSOU',
      firstName: 'Koffi',
      gender: 'M',
      tableNumber: '101',
      academicYear: '2026-2027',
    );
    final result = StudentResult(
      student: student,
      schoolClass: schoolClass,
      grades: [],
      totalPoints: 250.0,
      totalCoefficient: 20.0,
      average: 12.5,
      rank: 1,
    );

    final reportCardBytes = await PdfService.generateSingleReportCard(
      settings: settings,
      exam: exam,
      result: result,
      applySignatures: false,
    );
    expect(reportCardBytes.isNotEmpty, true);

    final pvBytes = await PdfService.generatePvReport(
      settings: settings,
      exam: exam,
      schoolClass: schoolClass,
      subjects: [],
      results: [result],
      applySignatures: false,
    );
    expect(pvBytes.isNotEmpty, true);
  });
}
