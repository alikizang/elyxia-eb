import '../services/french_number_words.dart';
import 'school_class.dart';
import 'student.dart';
import 'subject.dart';

class SubjectGrade {
  final Subject subject;
  final double? score; // Note sur 20
  final bool isAbsent;
  final double coefficient;
  final double points; // score * coefficient (Produit)
  final String appreciation;
  int rank; // Rang dans la matière
  bool isExAequo;

  SubjectGrade({
    required this.subject,
    this.score,
    this.isAbsent = false,
    required this.coefficient,
    required this.points,
    required this.appreciation,
    this.rank = 1,
    this.isExAequo = false,
  });

  String get scoreFormatted {
    if (isAbsent) return "ABS";
    if (score == null) return "-";
    return score!.toStringAsFixed(2);
  }

  String get pointsFormatted {
    if (isAbsent || score == null) return "-";
    return points.toStringAsFixed(2);
  }

  String get rankFormatted {
    if (score == null || isAbsent) return "-";
    final suffix = rank == 1 ? "er" : "e";
    return "$rank$suffix${isExAequo ? ' ex' : ''}";
  }
}

class StudentResult {
  final Student student;
  final SchoolClass schoolClass;
  final List<SubjectGrade> grades;
  final double totalPoints; // Somme des points (Produit)
  final double totalCoefficient; // Somme des coefficients
  final double average; // Note moyenne sur 20
  int rank;
  bool isExAequo;
  final int totalCandidates;
  final double classAverage;
  final double classMaxAverage;
  final double classMinAverage;

  StudentResult({
    required this.student,
    required this.schoolClass,
    required this.grades,
    required this.totalPoints,
    required this.totalCoefficient,
    required this.average,
    this.rank = 1,
    this.isExAequo = false,
    this.totalCandidates = 1,
    this.classAverage = 10.0,
    this.classMaxAverage = 10.0,
    this.classMinAverage = 10.0,
  });

  bool get isAdmitted => average >= 10.00;

  String get decision => isAdmitted ? "ADMIS(E)" : "AJOURNÉ(E)";

  String get mention {
    if (average >= 16.0) return "Très Bien";
    if (average >= 14.0) return "Bien";
    if (average >= 12.0) return "Assez Bien";
    if (average >= 10.0) return "Passable";
    if (average >= 8.0) return "Insuffisant";
    return "Médiocre";
  }

  /// Distinctions Spéciales de l'Élève (comme sur le bulletin test.pdf)
  String get specialDistinction {
    if (average >= 16.0) return "Félicitations du Jury";
    if (average >= 14.0) return "Encouragements du Jury";
    if (average >= 12.0) return "Tableau d'Honneur";
    return "-";
  }

  bool get hasTableauHonneur => average >= 12.0;
  bool get hasEncouragement => average >= 14.0;
  bool get hasFelicitation => average >= 16.0;

  String get rankFormatted {
    final suffix = rank == 1 ? "er" : "e";
    return "$rank$suffix${isExAequo ? ' ex' : ''}";
  }

  String get averageFormatted => average.toStringAsFixed(2);
  String get totalPointsFormatted => totalPoints.toStringAsFixed(2);
  String get totalCoefficientFormatted => totalCoefficient.toStringAsFixed(1);

  /// Moyenne écrite en lettres (ex: 12.6 -> "douze virgule six")
  String get averageInWords => FrenchNumberWords.convertAverage(average);
}
