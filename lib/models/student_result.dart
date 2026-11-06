import 'school_class.dart';
import 'student.dart';
import 'subject.dart';

class SubjectGrade {
  final Subject subject;
  final double? score; // Note sur 20
  final bool isAbsent;
  final double coefficient;
  final double points; // score * coefficient
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
    final suffix = rank == 1 ? "er" : "ème";
    return "$rank$suffix${isExAequo ? ' ex' : ''}";
  }
}

class StudentResult {
  final Student student;
  final SchoolClass schoolClass;
  final List<SubjectGrade> grades;
  final double totalPoints;
  final double totalCoefficient;
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
    return "Insuffisant";
  }

  String get rankFormatted {
    final suffix = rank == 1 ? "er" : "ème";
    return "$rank$suffix${isExAequo ? ' ex' : ''}";
  }

  String get averageFormatted => average.toStringAsFixed(2);
  String get totalPointsFormatted => totalPoints.toStringAsFixed(2);
  String get totalCoefficientFormatted => totalCoefficient.toStringAsFixed(1);
}
