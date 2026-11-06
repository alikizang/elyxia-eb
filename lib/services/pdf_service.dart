import 'dart:convert' show base64Decode;
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
import '../theme/app_colors.dart';

class PdfService {
  /// Nettoie les caractères typographiques complexes pour éviter les symboles bizarres
  static String sanitizeText(String text) {
    return text
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...')
        .replaceAll('\u00A0', ' '); // espace insécable
  }

  /// Charge les polices TTF Unicode (Roboto) pour un affichage parfait 100% hors-ligne
  static Future<pw.ThemeData> _loadPdfTheme() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');

      final fontRegular = pw.Font.ttf(regularData);
      final fontBold = pw.Font.ttf(boldData);
      final fontItalic = pw.Font.ttf(italicData);

      return pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
      );
    } catch (_) {
      return pw.ThemeData();
    }
  }

  /// Charge le logo de l'établissement (depuis la base SQLite en Base64 ou depuis les assets)
  static Future<Uint8List?> _loadSchoolLogo(AppSettings settings) async {
    if (settings.logoBase64 != null && settings.logoBase64!.isNotEmpty) {
      try {
        return base64Decode(settings.logoBase64!);
      } catch (_) {}
    }
    // Logo par défaut de l'établissement (Complexe Scolaire Les Victorieux)
    try {
      final byteData = await rootBundle.load('assets/images/school_logo_default.jpg');
      return byteData.buffer.asUint8List();
    } catch (_) {}
    return null;
  }

  /// Décode une chaîne Base64 en bytes
  static Uint8List? _decodeBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  /// Convertit une couleur Hex en PdfColor
  static PdfColor _getPdfPrimary(AppSettings settings) {
    final c = AppColors.fromHex(settings.primaryColorHex);
    return PdfColor(c.r, c.g, c.b);
  }

  static PdfColor _getPdfAccent(AppSettings settings) {
    final c = AppColors.fromHex(settings.accentColorHex);
    return PdfColor(c.r, c.g, c.b);
  }

  /// Génère le relevé individuel A5 pour un élève
  static Future<Uint8List> generateSingleReportCard({
    required AppSettings settings,
    required Exam exam,
    required StudentResult result,
    bool applySignatures = true,
  }) async {
    final theme = await _loadPdfTheme();
    final logoBytes = await _loadSchoolLogo(settings);
    final directorSigBytes = (applySignatures && settings.autoApplyDirectorSignature) ? _decodeBase64(settings.directorSignatureBase64) : null;
    final jurySigBytes = (applySignatures && settings.autoApplyJurySignature) ? _decodeBase64(settings.jurySignatureBase64) : null;
    final stampBytes = (applySignatures && settings.autoApplyStamp) ? _decodeBase64(settings.schoolStampBase64) : null;

    final pdf = pw.Document(
      title: "Relevé - ${result.student.fullName}",
      author: settings.schoolName,
      theme: theme,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        build: (context) => _buildReportCardContent(
          context: context,
          settings: settings,
          exam: exam,
          result: result,
          logoBytes: logoBytes,
          directorSigBytes: directorSigBytes,
          jurySigBytes: jurySigBytes,
          stampBytes: stampBytes,
          applySignatures: applySignatures,
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
    bool applySignatures = true,
  }) async {
    final theme = await _loadPdfTheme();
    final logoBytes = await _loadSchoolLogo(settings);
    final directorSigBytes = (applySignatures && settings.autoApplyDirectorSignature) ? _decodeBase64(settings.directorSignatureBase64) : null;
    final jurySigBytes = (applySignatures && settings.autoApplyJurySignature) ? _decodeBase64(settings.jurySignatureBase64) : null;
    final stampBytes = (applySignatures && settings.autoApplyStamp) ? _decodeBase64(settings.schoolStampBase64) : null;

    final pdf = pw.Document(
      title: "Relevés de notes - ${results.isNotEmpty ? results.first.schoolClass.name : ''}",
      author: settings.schoolName,
      theme: theme,
    );

    for (final result in results) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          build: (context) => _buildReportCardContent(
            context: context,
            settings: settings,
            exam: exam,
            result: result,
            logoBytes: logoBytes,
            directorSigBytes: directorSigBytes,
            jurySigBytes: jurySigBytes,
            stampBytes: stampBytes,
            applySignatures: applySignatures,
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Contenu d'un Relevé de Notes A5 officiel, prestigieux et authentique
  static pw.Widget _buildReportCardContent({
    required pw.Context context,
    required AppSettings settings,
    required Exam exam,
    required StudentResult result,
    Uint8List? logoBytes,
    Uint8List? directorSigBytes,
    Uint8List? jurySigBytes,
    Uint8List? stampBytes,
    bool applySignatures = true,
  }) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final primaryColor = _getPdfPrimary(settings);
    final accentColor = _getPdfAccent(settings);
    const darkColor = PdfColor.fromInt(0xFF1E293B);
    const lightBg = PdfColor.fromInt(0xFFF8FAFC);
    const headerBg = PdfColor.fromInt(0xFFF1F5F9);
    const borderColor = PdfColor.fromInt(0xFFCBD5E1);
    const successColor = PdfColor.fromInt(0xFF15803D);
    const errorColor = PdfColor.fromInt(0xFFB91C1C);

    return pw.Stack(
      children: [
        // 1. FILIGRANE CENTRAL DE L'ÉTABLISSEMENT (Subtil, chic et authentique)
        if (logoBytes != null)
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.045,
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 220,
                  height: 220,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),

        // 2. CADRE DE SÉCURITÉ OFFICIEL (Double filet institutionnel de diplôme)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: primaryColor, width: 1.0),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          padding: const pw.EdgeInsets.all(2.0),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.45),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // A. EN-TÊTE OFFICIEL DE L'ÉTABLISSEMENT
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo Gauche
                    if (logoBytes != null)
                      pw.Container(
                        width: 34,
                        height: 34,
                        margin: const pw.EdgeInsets.only(right: 6),
                        child: pw.ClipOval(
                          child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                        ),
                      )
                    else
                      pw.SizedBox(width: 34),

                    // Bloc Central : Ministère & Informations Établissement
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "MINISTÈRE DE L'EDUCATION NATIONALE",
                                style: pw.TextStyle(fontSize: 6.2, fontWeight: pw.FontWeight.bold, color: darkColor),
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    "RÉPUBLIQUE TOGOLAISE",
                                    style: pw.TextStyle(fontSize: 6.2, fontWeight: pw.FontWeight.bold, color: darkColor),
                                  ),
                                  pw.Text(
                                    "Travail - Liberté - Patrie",
                                    style: const pw.TextStyle(fontSize: 4.8, fontStyle: pw.FontStyle.italic),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 1.5),
                          pw.Text(
                            sanitizeText(settings.schoolName),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 9.2, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          pw.Text(
                            sanitizeText(settings.schoolSlogan),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 5.8, fontStyle: pw.FontStyle.italic, color: darkColor),
                          ),
                          pw.Text(
                            sanitizeText(settings.schoolAddress),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 5.6, color: PdfColors.grey800),
                          ),
                          pw.Text(
                            sanitizeText("${settings.schoolPoBox} • Tél : ${settings.schoolPhone}"),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 5.4, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),

                    // Logo Droit
                    if (logoBytes != null)
                      pw.Container(
                        width: 34,
                        height: 34,
                        margin: const pw.EdgeInsets.only(left: 6),
                        child: pw.ClipOval(
                          child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                        ),
                      )
                    else
                      pw.SizedBox(width: 34),
                  ],
                ),

                pw.SizedBox(height: 4),

                // B. BANNIÈRE TITRE DU RELEVÉ & SÉRIE
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3.2, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2.5)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        sanitizeText("RELEVÉ DE NOTES OFFICIEL - ${exam.title.toUpperCase()}"),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        sanitizeText("SÉRIE ${result.schoolClass.series.toUpperCase()} (${result.schoolClass.examType})"),
                        style: pw.TextStyle(
                          color: accentColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ligne Métadonnées Session & Promotion
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: const pw.BoxDecoration(color: headerBg),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Année Scolaire : ${exam.academicYear}",
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                      pw.Text(
                        "Classe : ${result.schoolClass.name}",
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                      pw.Text(
                        "Session : ${exam.sessionDate}",
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                      pw.Text(
                        "Effectif : ${result.totalCandidates} candidats",
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 3.5),

                // C. CARTOUCHE D'IDENTITÉ STRUCTURÉ DU CANDIDAT
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: pw.BoxDecoration(
                    color: lightBg,
                    border: pw.Border.all(color: borderColor, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2.5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(
                            flex: 6,
                            child: pw.RichText(
                              text: pw.TextSpan(
                                style: const pw.TextStyle(fontSize: 7.2, color: darkColor),
                                children: [
                                  const pw.TextSpan(text: "NOM ET PRÉNOMS : ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.TextSpan(
                                    text: sanitizeText(result.student.fullName),
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.0, color: primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: pw.BoxDecoration(
                              color: headerBg,
                              border: pw.Border.all(color: primaryColor, width: 0.5),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                            ),
                            child: pw.Text(
                              "N° TABLE : ${result.student.tableNumber.isNotEmpty ? result.student.tableNumber : '-'}",
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            "N° Mtle : ${result.student.matricule.isNotEmpty ? result.student.matricule : '-'}",
                            style: const pw.TextStyle(fontSize: 6.8, color: darkColor),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Date et Lieu de Naissance : ${result.student.birthDate.isNotEmpty ? result.student.birthDate : '-'} à ${result.student.birthPlace.isNotEmpty ? result.student.birthPlace : '-'}",
                            style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey800),
                          ),
                          pw.Text(
                            "Sexe : ${result.student.gender == 'M' ? 'Masculin' : 'Féminin'}    |    Doublant : ${result.student.isRepeater ? 'OUI' : 'NON'}",
                            style: pw.TextStyle(fontSize: 6.4, fontWeight: pw.FontWeight.bold, color: darkColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 4),

                // D. TABLEAU OFFICIEL DES NOTES
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.5),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.8), // N°
                    1: pw.FlexColumnWidth(4.6), // Matières
                    2: pw.FlexColumnWidth(1.8), // Note /20
                    3: pw.FlexColumnWidth(1.2), // Coef
                    4: pw.FlexColumnWidth(1.8), // Produit (Points)
                    5: pw.FlexColumnWidth(1.5), // Rang
                    6: pw.FlexColumnWidth(2.5), // Appréciation
                    7: pw.FlexColumnWidth(3.0), // Nom des Professeurs
                  },
                  children: [
                    // Ligne d'en-tête du tableau
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: primaryColor),
                      children: [
                        _buildTableHeader("N°"),
                        _buildTableHeader("Matières", align: pw.TextAlign.left),
                        _buildTableHeader("Note /20"),
                        _buildTableHeader("Coef."),
                        _buildTableHeader("Produit"),
                        _buildTableHeader("Rang"),
                        _buildTableHeader("Appréciation"),
                        _buildTableHeader("Nom des Professeurs"),
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
                            padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
                            child: pw.Text("${idx + 1}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.3),
                            child: pw.Text(
                              sanitizeText(g.subject.name),
                              style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: darkColor),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
                            child: pw.Text(
                              g.scoreFormatted,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 6.8,
                                fontWeight: pw.FontWeight.bold,
                                color: g.isAbsent ? errorColor : ((g.score ?? 0) < 10 ? errorColor : darkColor),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
                            child: pw.Text(
                              g.coefficient.toStringAsFixed(0),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 6.8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
                            child: pw.Text(
                              g.pointsFormatted,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
                            child: pw.Text(
                              g.rankFormatted,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 6.5),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2.3),
                            child: pw.Text(
                              sanitizeText(g.appreciation),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 6.5, color: g.isAbsent ? errorColor : darkColor),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2.3),
                            child: pw.Text(
                              sanitizeText(g.subject.teacherName.isNotEmpty ? g.subject.teacherName : "-"),
                              textAlign: pw.TextAlign.left,
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          ),
                        ],
                      );
                    }),
                    // Ligne TOTAL DU RELEVÉ
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: headerBg),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text("")),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.3),
                          child: pw.Text(
                            "TOTAL GÉNÉRAL",
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.3),
                          child: pw.Text("-", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.3),
                          child: pw.Text(
                            result.totalCoefficientFormatted,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.3),
                          child: pw.Text(
                            result.totalPointsFormatted,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.3),
                          child: pw.Text("-", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(2.3), child: pw.Text("")),
                        pw.Padding(padding: const pw.EdgeInsets.all(2.3), child: pw.Text("")),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 3),

                // E. GRILLE OFFICIELLE DU BARÈME DES MENTIONS
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.35),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        "GRILLE OFFICIELLE DES MENTIONS :   [ 16 - 20 : Très Bien ]   •   [ 14 - 15.99 : Bien ]   •   [ 12 - 13.99 : Assez Bien ]   •   [ 10 - 11.99 : Passable ]   •   [ < 10 : Ajourné ]",
                        style: const pw.TextStyle(fontSize: 5.3, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 4),

                // F. BILAN DE DÉLIBÉRATION OFFICIEL & CLASSEMENT
                pw.Container(
                  padding: const pw.EdgeInsets.all(4.5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryColor, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    color: lightBg,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Bloc 1 : Moyenne Générale & En Lettres
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
                                    fontSize: 14.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: result.isAdmitted ? primaryColor : errorColor,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 1.5, left: 2),
                                  child: pw.Text("/ 20", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                                ),
                              ],
                            ),
                            pw.Text(
                              "En Lettres : ${sanitizeText(result.averageInWords)}",
                              style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic, color: darkColor),
                            ),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              "RANG : ${result.rankFormatted} / ${result.totalCandidates} élèves",
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkColor),
                            ),
                          ],
                        ),
                      ),

                      pw.Container(width: 0.5, height: 38, color: borderColor, margin: const pw.EdgeInsets.symmetric(horizontal: 5)),

                      // Bloc 2 : Décision du Jury & Mentions
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              "DÉCISION DU JURY",
                              style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: pw.BoxDecoration(
                                color: result.isAdmitted ? const PdfColor(0.85, 0.98, 0.90) : const PdfColor(0.99, 0.88, 0.88),
                                border: pw.Border.all(
                                  color: result.isAdmitted ? successColor : errorColor,
                                  width: 0.8,
                                ),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                              ),
                              child: pw.Text(
                                result.decision,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: result.isAdmitted ? successColor : errorColor,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              "Mention : ${result.mention}",
                              style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: darkColor),
                            ),
                            if (result.specialDistinction != "-")
                              pw.Container(
                                margin: const pw.EdgeInsets.only(top: 2),
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: pw.BoxDecoration(
                                  color: const PdfColor(0.93, 0.97, 1.0),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                ),
                                child: pw.Text(
                                  result.specialDistinction,
                                  style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: primaryColor),
                                ),
                              ),
                          ],
                        ),
                      ),

                      pw.Container(width: 0.5, height: 38, color: borderColor, margin: const pw.EdgeInsets.symmetric(horizontal: 5)),

                      // Bloc 3 : Profil de la Promotion
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
                            _buildStatLine("Plus forte moyenne :", "${result.classMaxAverage.toStringAsFixed(2)} / 20"),
                            _buildStatLine("Moyenne de classe :", "${result.classAverage.toStringAsFixed(2)} / 20"),
                            _buildStatLine("Plus faible moyenne :", "${result.classMinAverage.toStringAsFixed(2)} / 20"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 5),

                // G. SIGNATURES & VALIDATION OFFICIELLE (Avec deux vrais cadres réservés aux cachets)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Cadre Signature Gauche : Président du Jury
                    pw.Container(
                      width: 175,
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2.5)),
                        color: lightBg,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            sanitizeText(settings.juryPresidentTitle),
                            style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: darkColor),
                          ),
                          if (applySignatures && jurySigBytes != null) ...[
                            pw.SizedBox(height: 1),
                            pw.Container(
                              height: 22,
                              child: pw.Image(pw.MemoryImage(jurySigBytes), fit: pw.BoxFit.contain),
                            ),
                          ] else ...[
                            pw.SizedBox(height: 22),
                          ],
                          pw.Text(
                            "(Visa, Observations & Signature)",
                            style: const pw.TextStyle(fontSize: 5.2, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),

                    // Cadre Signature Droit : Chef d'Établissement
                    pw.Container(
                      width: 175,
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2.5)),
                        color: lightBg,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            "Lomé, le $today",
                            style: const pw.TextStyle(fontSize: 6.2, fontStyle: pw.FontStyle.italic),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            sanitizeText(settings.directorTitle),
                            style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: darkColor),
                          ),
                          if (applySignatures && (directorSigBytes != null || stampBytes != null)) ...[
                            pw.SizedBox(height: 1),
                            pw.Container(
                              height: 22,
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  if (stampBytes != null)
                                    pw.Container(
                                      width: 28,
                                      height: 22,
                                      margin: const pw.EdgeInsets.only(right: 6),
                                      child: pw.Image(pw.MemoryImage(stampBytes), fit: pw.BoxFit.contain),
                                    ),
                                  if (directorSigBytes != null)
                                    pw.Container(
                                      width: 48,
                                      height: 22,
                                      child: pw.Image(pw.MemoryImage(directorSigBytes), fit: pw.BoxFit.contain),
                                    ),
                                ],
                              ),
                            ),
                          ] else ...[
                            pw.SizedBox(height: 18),
                          ],
                          pw.Text(
                            sanitizeText(settings.directorName),
                            style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 4),

                // H. PIED DE PAGE SÉCURISÉ & RÉFÉRENCE OFFICIELLE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Réf. Archive : EB-${exam.academicYear.replaceAll('/', '-')}-${result.schoolClass.series}-${result.student.tableNumber} • Document certifié conforme",
                      style: const pw.TextStyle(fontSize: 5.2, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      "NB : Il n'est délivré qu'un seul relevé officiel. Toute falsification l'annule.",
                      style: const pw.TextStyle(fontSize: 5.2, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
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
    bool applySignatures = true,
  }) async {
    final theme = await _loadPdfTheme();
    final logoBytes = await _loadSchoolLogo(settings);
    final directorSigBytes = (applySignatures && settings.autoApplyDirectorSignature) ? _decodeBase64(settings.directorSignatureBase64) : null;
    final jurySigBytes = (applySignatures && settings.autoApplyJurySignature) ? _decodeBase64(settings.jurySignatureBase64) : null;
    final stampBytes = (applySignatures && settings.autoApplyStamp) ? _decodeBase64(settings.schoolStampBase64) : null;
    final primaryColor = _getPdfPrimary(settings);
    const darkColor = PdfColor.fromInt(0xFF1E293B);
    const headerBg = PdfColor.fromInt(0xFFF1F5F9);
    const borderColor = PdfColor.fromInt(0xFFCBD5E1);
    const successColor = PdfColor.fromInt(0xFF15803D);
    const errorColor = PdfColor.fromInt(0xFFB91C1C);

    final pdf = pw.Document(
      title: "PV Délibération - ${schoolClass.name} - ${exam.title}",
      author: settings.schoolName,
      theme: theme,
    );

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    int admitted = 0;
    for (final r in results) {
      if (r.isAdmitted) admitted++;
    }
    final rate = results.isNotEmpty ? (admitted / results.length * 100).toStringAsFixed(1) : "0.0";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        build: (context) => [
          // En-tête officiel du PV
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                children: [
                  if (logoBytes != null)
                    pw.Container(
                      width: 38,
                      height: 38,
                      margin: const pw.EdgeInsets.only(right: 10),
                      child: pw.ClipOval(
                        child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        sanitizeText(settings.schoolName),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.Text(
                        sanitizeText(settings.schoolSlogan),
                        style: const pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic),
                      ),
                      pw.Text(
                        sanitizeText("${settings.schoolPoBox} - Tél : ${settings.schoolPhone}"),
                        style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    sanitizeText("PROCÈS-VERBAL DE DÉLIBÉRATION - ${exam.title.toUpperCase()}"),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                  pw.Text(
                    sanitizeText("CLASSE : ${schoolClass.name.toUpperCase()} (${schoolClass.examType} - SÉRIE ${schoolClass.series})"),
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                  ),
                  pw.Text(
                    "Année Scolaire : ${exam.academicYear} | Session : ${exam.sessionDate}",
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "MINISTÈRE DE L'EDUCATION NATIONALE",
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                  ),
                  pw.Text(
                    "RÉPUBLIQUE TOGOLAISE",
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                  ),
                  pw.Text(
                    "Travail - Liberté - Patrie",
                    style: const pw.TextStyle(fontSize: 5, fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          // Tableau récapitulatif des élèves
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            children: [
              // En-tête
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _buildTableHeader("N° Table"),
                  _buildTableHeader("Nom & Prénoms", align: pw.TextAlign.left),
                  _buildTableHeader("Sexe"),
                  ...subjects.map((s) => _buildTableHeader("${s.code}\n(/20)")),
                  _buildTableHeader("Total\nPoints"),
                  _buildTableHeader("Moyenne\n(/20)"),
                  _buildTableHeader("Rang"),
                  _buildTableHeader("Décision"),
                ],
              ),
              // Lignes
              ...results.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final isAlt = idx % 2 == 1;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isAlt ? headerBg : PdfColors.white),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Text(
                        r.student.tableNumber.isNotEmpty ? r.student.tableNumber : "${idx + 1}",
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                      child: pw.Text(
                        sanitizeText(r.student.fullName),
                        style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Text(r.student.gender, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.5)),
                    ),
                    ...r.grades.map(
                      (g) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                        child: pw.Text(
                          g.scoreFormatted,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 6.5,
                            fontWeight: pw.FontWeight.bold,
                            color: g.isAbsent ? errorColor : ((g.score ?? 0) < 10 ? errorColor : darkColor),
                          ),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Text(
                        r.totalPointsFormatted,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Text(
                        r.averageFormatted,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7.2,
                          fontWeight: pw.FontWeight.bold,
                          color: r.isAdmitted ? primaryColor : errorColor,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Text(
                        r.rankFormatted,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Text(
                        r.decision,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          color: r.isAdmitted ? successColor : errorColor,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 10),

          // Résumé statistique et signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  color: headerBg,
                ),
                child: pw.Row(
                  children: [
                    _buildPvStat("Candidats :", "${results.length}"),
                    pw.SizedBox(width: 14),
                    _buildPvStat("Admis :", "$admitted"),
                    pw.SizedBox(width: 14),
                    _buildPvStat("Ajournés :", "${results.length - admitted}"),
                    pw.SizedBox(width: 14),
                    _buildPvStat("Taux de réussite :", "$rate %"),
                  ],
                ),
              ),

              pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        sanitizeText(settings.juryPresidentTitle),
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                      if (applySignatures && jurySigBytes != null) ...[
                        pw.SizedBox(height: 1),
                        pw.Container(
                          height: 24,
                          child: pw.Image(pw.MemoryImage(jurySigBytes), fit: pw.BoxFit.contain),
                        ),
                      ] else ...[
                        pw.SizedBox(height: 24),
                      ],
                      pw.Text("(Visa & Signature)", style: const pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.SizedBox(width: 36),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Lomé, le $today", style: const pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        sanitizeText(settings.directorTitle),
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                      ),
                      if (applySignatures && (directorSigBytes != null || stampBytes != null)) ...[
                        pw.SizedBox(height: 1),
                        pw.Container(
                          height: 24,
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              if (stampBytes != null)
                                pw.Container(
                                  width: 30,
                                  height: 24,
                                  margin: const pw.EdgeInsets.only(right: 6),
                                  child: pw.Image(pw.MemoryImage(stampBytes), fit: pw.BoxFit.contain),
                                ),
                              if (directorSigBytes != null)
                                pw.Container(
                                  width: 50,
                                  height: 24,
                                  child: pw.Image(pw.MemoryImage(directorSigBytes), fit: pw.BoxFit.contain),
                                ),
                            ],
                          ),
                        ),
                      ] else ...[
                        pw.SizedBox(height: 22),
                      ],
                      pw.Text(
                        sanitizeText(settings.directorName),
                        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableHeader(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
      child: pw.Text(
        sanitizeText(text),
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildStatLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
          pw.SizedBox(width: 3),
          pw.Text(value, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildPvStat(String label, String val) {
    return pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
        children: [
          pw.TextSpan(text: "$label "),
          pw.TextSpan(text: val, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ],
      ),
    );
  }
}
