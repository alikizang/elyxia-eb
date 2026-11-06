import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/student_result.dart';
import '../models/subject.dart';

class PdfService {
  // Palette de couleurs pour le PDF (assortie à l'ADN Elyxia)
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF22577A);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF3BCC97);
  static const PdfColor darkColor = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor headerBg = PdfColor.fromInt(0xFFEDF2F7);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor successColor = PdfColor.fromInt(0xFF15803D);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFB91C1C);

  /// Génère le relevé individuel A5 pour un élève
  static Future<Uint8List> generateSingleReportCard({
    required AppSettings settings,
    required Exam exam,
    required StudentResult result,
  }) async {
    final pdf = pw.Document(
      title: "Relevé - ${result.student.fullName}",
      author: "Elyxia EB",
    );

    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        build: (context) => _buildReportCardContent(
          context: context,
          settings: settings,
          exam: exam,
          result: result,
          logoBytes: logoBytes,
        ),
      ),
    );

    return pdf.save();
  }

  /// Génère l'ensemble des relevés A5 de toute la classe (1 page par élève)
  static Future<Uint8List> generateBatchReportCards({
    required AppSettings settings,
    required Exam exam,
    required List<StudentResult> results,
  }) async {
    final pdf = pw.Document(
      title: "Relevés de notes - ${results.isNotEmpty ? results.first.schoolClass.name : ''}",
      author: "Elyxia EB",
    );

    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    for (final result in results) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          build: (context) => _buildReportCardContent(
            context: context,
            settings: settings,
            exam: exam,
            result: result,
            logoBytes: logoBytes,
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Contenu d'un Relevé de Notes A5
  static pw.Widget _buildReportCardContent({
    required pw.Context context,
    required AppSettings settings,
    required Exam exam,
    required StudentResult result,
    Uint8List? logoBytes,
  }) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // 1. EN-TÊTE OFFICIEL
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Côté Gauche : Ministère
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "RÉPUBLIQUE TOGOLAISE",
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                  ),
                  pw.Text(
                    "Travail - Liberté - Patrie",
                    style: const pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "MINISTÈRE DES ENSEIGNEMENTS PRIMAIRE,\nSECONDAIRE ET TECHNIQUE",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ],
              ),
            ),

            // Logo central
            if (logoBytes != null)
              pw.Container(
                width: 34,
                height: 34,
                margin: const pw.EdgeInsets.symmetric(horizontal: 6),
                child: pw.Image(pw.MemoryImage(logoBytes)),
              )
            else
              pw.SizedBox(width: 20),

            // Côté Droit : Établissement
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    settings.schoolName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                  pw.Text(
                    settings.schoolSubTitle,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 5.5),
                  ),
                  pw.Text(
                    "Tél: ${settings.schoolPhone} — ${settings.schoolAddress}",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    "Année Scolaire : ${settings.academicYear}",
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 6),

        // 2. BANNIÈRE TITRE DU RELEVÉ
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "RELEVÉ DE NOTES — ${exam.title.toUpperCase()}",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                  letterSpacing: 0.5,
                ),
              ),
              pw.Text(
                "SESSION DE ${exam.sessionDate.toUpperCase()}",
                style: pw.TextStyle(
                  color: accentColor,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 7.5,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 5),

        // 3. CARTOUCHE D'IDENTITÉ DU CANDIDAT
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: headerBg,
            border: pw.Border.all(color: borderColor, width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoLine("Candidat(e) :", result.student.fullName, isBold: true, fontSize: 8),
                    _buildInfoLine("Né(e) le :", "${result.student.birthDate.isNotEmpty ? result.student.birthDate : '-'} à ${result.student.birthPlace.isNotEmpty ? result.student.birthPlace : '-'}"),
                    _buildInfoLine("Sexe :", result.student.gender == 'F' ? 'Féminin' : 'Masculin'),
                  ],
                ),
              ),
              pw.Container(width: 0.8, height: 32, color: borderColor, margin: const pw.EdgeInsets.symmetric(horizontal: 8)),
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoLine("Classe :", "${result.schoolClass.name} (${result.schoolClass.examType})", isBold: true),
                    _buildInfoLine("Série :", result.schoolClass.series),
                    _buildInfoLine("N° de Table :", result.student.tableNumber.isNotEmpty ? result.student.tableNumber : "-", isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 5),

        // 4. TABLEAU DES NOTES
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(4.5), // Matière
            1: pw.FlexColumnWidth(1.8), // Note /20
            2: pw.FlexColumnWidth(1.4), // Coef
            3: pw.FlexColumnWidth(2.0), // Points (N*C)
            4: pw.FlexColumnWidth(1.8), // Rang Mat.
            5: pw.FlexColumnWidth(2.8), // Appréciation
          },
          children: [
            // Ligne d'en-tête du tableau
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: primaryColor),
              children: [
                _buildTableHeader("MATIÈRES D'EXAMEN", align: pw.TextAlign.left),
                _buildTableHeader("NOTE /20"),
                _buildTableHeader("COEF"),
                _buildTableHeader("POINTS"),
                _buildTableHeader("RANG"),
                _buildTableHeader("APPRÉCIATION"),
              ],
            ),
            // Lignes des matières
            ...result.grades.asMap().entries.map((entry) {
              final idx = entry.key;
              final g = entry.value;
              final isAlt = idx % 2 == 1;

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isAlt ? headerBg : PdfColors.white),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                    child: pw.Text(
                      g.subject.name,
                      style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Text(
                      g.scoreFormatted,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 7.2,
                        fontWeight: pw.FontWeight.bold,
                        color: g.isAbsent ? errorColor : ((g.score ?? 0) < 10 ? errorColor : darkColor),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Text(
                      g.coefficient.toStringAsFixed(0),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.2),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Text(
                      g.pointsFormatted,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Text(
                      g.rankFormatted,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 6.8),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                    child: pw.Text(
                      g.appreciation,
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        fontSize: 6.8,
                        color: g.isAbsent ? errorColor : darkColor,
                      ),
                    ),
                  ),
                ],
              );
            }),
            // Ligne TOTAL
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: headerBg),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: pw.Text(
                    "TOTAL GÉNÉRAL",
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text("-", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text(
                    result.totalCoefficientFormatted,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text(
                    result.totalPointsFormatted,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text("-", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text("", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 6),

        // 5. BILAN DE L'EXAMEN & CLASSEMENT (3 Blocs Clés)
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: primaryColor, width: 1.2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            color: lightBg,
          ),
          child: pw.Row(
            children: [
              // Bloc 1 : Moyenne & Rang
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "MOYENNE GÉNÉRALE",
                      style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          result.averageFormatted,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: result.isAdmitted ? primaryColor : errorColor,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2, left: 2),
                          child: pw.Text(
                            "/ 20",
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      "RANG : ${result.rankFormatted} / ${result.totalCandidates} élèves",
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                  ],
                ),
              ),

              pw.Container(width: 0.8, height: 38, color: borderColor, margin: const pw.EdgeInsets.symmetric(horizontal: 6)),

              // Bloc 2 : Décision du Jury & Mention
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      "DÉCISION DU JURY",
                      style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: result.isAdmitted ? const PdfColor(0.85, 0.98, 0.90) : const PdfColor(0.99, 0.88, 0.88),
                        border: pw.Border.all(
                          color: result.isAdmitted ? successColor : errorColor,
                          width: 1,
                        ),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                      child: pw.Text(
                        result.decision,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: result.isAdmitted ? successColor : errorColor,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Mention : ${result.mention}",
                      style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: darkColor),
                    ),
                  ],
                ),
              ),

              pw.Container(width: 0.8, height: 38, color: borderColor, margin: const pw.EdgeInsets.symmetric(horizontal: 6)),

              // Bloc 3 : Profil de la Promotion / Classe
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "STATISTIQUES CLASSE",
                      style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                    pw.SizedBox(height: 2),
                    _buildStatLine("Moyenne classe :", "${result.classAverage.toStringAsFixed(2)} / 20"),
                    _buildStatLine("Plus forte moyenne :", "${result.classMaxAverage.toStringAsFixed(2)} / 20"),
                    _buildStatLine("Plus faible moyenne :", "${result.classMinAverage.toStringAsFixed(2)} / 20"),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.Spacer(),

        // 6. SIGNATURES & VALIDATION
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  settings.juryPresidentTitle,
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  "(Visa & Signature)",
                  style: const pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  "Fait à Lomé, le $today",
                  style: const pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  settings.directorTitle,
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                ),
                pw.SizedBox(height: 22),
                pw.Text(
                  settings.directorName,
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 2),
        // Bas de page Elyxia
        pw.Center(
          child: pw.Text(
            "Elyxia EB • Logiciel d'Examen Blanc Hors Ligne • Complexe Scolaire Les Victorieux",
            style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  /// Procès-Verbal (PV) / Fiche Récapitulative officielle en A4 Paysage
  static Future<Uint8List> generatePvReport({
    required AppSettings settings,
    required Exam exam,
    required SchoolClass schoolClass,
    required List<Subject> subjects,
    required List<StudentResult> results,
  }) async {
    final pdf = pw.Document(
      title: "PV Délibération - ${schoolClass.name} - ${exam.title}",
      author: "Elyxia EB",
    );

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Calcul stats
    int admitted = 0;
    for (final r in results) {
      if (r.isAdmitted) admitted++;
    }
    final rate = results.isNotEmpty ? (admitted / results.length * 100).toStringAsFixed(1) : "0.0";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.schoolName,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                    pw.Text(
                      "${settings.schoolSubTitle} • Année ${settings.academicYear}",
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "PROCÈS-VERBAL DE DÉLIBÉRATION",
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                    pw.Text(
                      "${exam.title.toUpperCase()} — ${schoolClass.name} (${schoolClass.examType}) — Session : ${exam.sessionDate}",
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              decoration: const pw.BoxDecoration(color: headerBg),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Effectif total : ${results.length} candidats", style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text("Admis : $admitted", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: successColor)),
                  pw.Text("Ajournés : ${results.length - admitted}", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: errorColor)),
                  pw.Text("Taux de réussite : $rate %", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.Text("Date d'édition : $today", style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: primaryColor),
                children: [
                  _buildTableHeader("RANG", width: 30),
                  _buildTableHeader("N° TABLE", width: 40),
                  _buildTableHeader("NOM & PRÉNOMS", align: pw.TextAlign.left),
                  _buildTableHeader("SEXE", width: 25),
                  ...subjects.map((s) => _buildTableHeader("${s.code}\n(${s.coefficient.toInt()})")),
                  _buildTableHeader("TOTAL\nPTS", width: 45),
                  _buildTableHeader("MOY.\n/20", width: 45),
                  _buildTableHeader("DÉCISION", width: 55),
                  _buildTableHeader("MENTION", width: 50),
                ],
              ),
              // Student rows
              ...results.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final isAlt = idx % 2 == 1;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isAlt ? headerBg : PdfColors.white),
                  children: [
                    _buildTableCell(r.rankFormatted, isBold: true, align: pw.TextAlign.center),
                    _buildTableCell(r.student.tableNumber, align: pw.TextAlign.center),
                    _buildTableCell(r.student.fullName, isBold: true, align: pw.TextAlign.left),
                    _buildTableCell(r.student.gender, align: pw.TextAlign.center),
                    ...r.grades.map((g) => _buildTableCell(
                      g.scoreFormatted,
                      align: pw.TextAlign.center,
                      textColor: g.isAbsent ? errorColor : ((g.score ?? 0) < 10 ? errorColor : darkColor),
                    )),
                    _buildTableCell(r.totalPointsFormatted, isBold: true, align: pw.TextAlign.center),
                    _buildTableCell(
                      r.averageFormatted,
                      isBold: true,
                      align: pw.TextAlign.center,
                      textColor: r.isAdmitted ? successColor : errorColor,
                    ),
                    _buildTableCell(
                      r.decision,
                      isBold: true,
                      align: pw.TextAlign.center,
                      textColor: r.isAdmitted ? successColor : errorColor,
                    ),
                    _buildTableCell(r.mention, align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(settings.juryPresidentTitle, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                  pw.Text("(Visa & Signature)", style: const pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(settings.directorTitle, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                  pw.Text(settings.directorName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // --- Helpers d'affichage PDF ---
  static pw.Widget _buildTableHeader(String text, {double? width, pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isBold = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? darkColor,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoLine(String label, String value, {bool isBold = false, double fontSize = 7}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.8),
      child: pw.Row(
        children: [
          pw.Text("$label ", style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: darkColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: darkColor)),
        ],
      ),
    );
  }
}
