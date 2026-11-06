import '../models/mark.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../models/student_result.dart';
import '../models/subject.dart';

class ClassStatistics {
  final int totalStudents;
  final int admittedCount;
  final int failedCount;
  final double successRate;
  final double classAverage;
  final double highestAverage;
  final double lowestAverage;

  ClassStatistics({
    required this.totalStudents,
    required this.admittedCount,
    required this.failedCount,
    required this.successRate,
    required this.classAverage,
    required this.highestAverage,
    required this.lowestAverage,
  });
}

class CalculationService {
  static String getAppreciation(double? score, bool isAbsent) {
    if (isAbsent) return "Absent";
    if (score == null) return "Non noté";
    if (score >= 16.0) return "Très Bien";
    if (score >= 14.0) return "Bien";
    if (score >= 12.0) return "Assez Bien";
    if (score >= 10.0) return "Passable";
    if (score >= 8.0) return "Insuffisant";
    return "Médiocre";
  }

  static List<StudentResult> computeClassResults({
    required SchoolClass schoolClass,
    required List<Subject> subjects,
    required List<Student> students,
    required List<Mark> marks,
  }) {
    if (students.isEmpty) return [];

    // Indexation rapide des notes par studentId et subjectId
    final marksMap = <String, Mark>{};
    for (final m in marks) {
      marksMap['${m.studentId}_${m.subjectId}'] = m;
    }

    final rawResults = <StudentResult>[];

    // 1. Calcul individuel des notes et moyennes brutes
    for (final student in students) {
      final grades = <SubjectGrade>[];
      double totalPoints = 0.0;
      double totalCoef = 0.0;

      for (final subject in subjects) {
        final mark = marksMap['${student.id}_${subject.id}'];
        final isAbsent = mark?.isAbsent ?? false;
        final score = isAbsent ? null : mark?.score;

        final coef = subject.coefficient;
        final points = (score != null && !isAbsent) ? (score * coef) : 0.0;

        if (score != null && !isAbsent) {
          totalPoints += points;
          totalCoef += coef;
        }

        grades.add(
          SubjectGrade(
            subject: subject,
            score: score,
            isAbsent: isAbsent,
            coefficient: coef,
            points: points,
            appreciation: getAppreciation(score, isAbsent),
          ),
        );
      }

      final average = totalCoef > 0 ? (totalPoints / totalCoef) : 0.0;
      // Arrondi standard à 2 décimales
      final roundedAverage = (average * 100).round() / 100.0;

      rawResults.add(
        StudentResult(
          student: student,
          schoolClass: schoolClass,
          grades: grades,
          totalPoints: totalPoints,
          totalCoefficient: totalCoef,
          average: roundedAverage,
          totalCandidates: students.length,
        ),
      );
    }

    // 2. Classement général de la classe
    rawResults.sort((a, b) => b.average.compareTo(a.average));

    for (int i = 0; i < rawResults.length; i++) {
      if (i == 0) {
        rawResults[i].rank = 1;
        rawResults[i].isExAequo = false;
      } else {
        if (rawResults[i].average == rawResults[i - 1].average) {
          rawResults[i].rank = rawResults[i - 1].rank;
          rawResults[i].isExAequo = true;
          rawResults[i - 1].isExAequo = true;
        } else {
          rawResults[i].rank = i + 1;
          rawResults[i].isExAequo = false;
        }
      }
    }

    // 3. Calcul du rang par matière
    for (final subject in subjects) {
      // Collecter tous les grades pour cette matière
      final subjectEntries = <_StudentSubjectScore>[];
      for (final res in rawResults) {
        final g = res.grades.firstWhere((element) => element.subject.id == subject.id);
        subjectEntries.add(_StudentSubjectScore(res, g));
      }

      // Trier par note décroissante (les absents ou null à la fin)
      subjectEntries.sort((a, b) {
        final scoreA = a.grade.isAbsent ? -1.0 : (a.grade.score ?? -1.0);
        final scoreB = b.grade.isAbsent ? -1.0 : (b.grade.score ?? -1.0);
        return scoreB.compareTo(scoreA);
      });

      for (int i = 0; i < subjectEntries.length; i++) {
        final current = subjectEntries[i].grade;
        if (current.score == null || current.isAbsent) {
          current.rank = 0;
          current.isExAequo = false;
          continue;
        }

        if (i == 0) {
          current.rank = 1;
          current.isExAequo = false;
        } else {
          final prev = subjectEntries[i - 1].grade;
          if (prev.score != null && prev.score == current.score) {
            current.rank = prev.rank;
            current.isExAequo = true;
            prev.isExAequo = true;
          } else {
            current.rank = i + 1;
            current.isExAequo = false;
          }
        }
      }
    }

    // 4. Statistiques globales de la classe
    final nonZeroAverages = rawResults.map((e) => e.average).toList();
    final highestAvg = nonZeroAverages.isNotEmpty ? nonZeroAverages.first : 0.0;
    final lowestAvg = nonZeroAverages.isNotEmpty ? nonZeroAverages.last : 0.0;
    final sumAvg = nonZeroAverages.fold(0.0, (prev, elem) => prev + elem);
    final classAvg = nonZeroAverages.isNotEmpty ? (sumAvg / nonZeroAverages.length) : 0.0;
    final roundedClassAvg = (classAvg * 100).round() / 100.0;

    // Réassigner les statistiques de classe sur chaque résultat
    final finalResults = rawResults.map((r) {
      return StudentResult(
        student: r.student,
        schoolClass: r.schoolClass,
        grades: r.grades,
        totalPoints: r.totalPoints,
        totalCoefficient: r.totalCoefficient,
        average: r.average,
        rank: r.rank,
        isExAequo: r.isExAequo,
        totalCandidates: students.length,
        classAverage: roundedClassAvg,
        classMaxAverage: highestAvg,
        classMinAverage: lowestAvg,
      );
    }).toList();

    return finalResults;
  }

  static ClassStatistics computeStatistics(List<StudentResult> results) {
    if (results.isEmpty) {
      return ClassStatistics(
        totalStudents: 0,
        admittedCount: 0,
        failedCount: 0,
        successRate: 0.0,
        classAverage: 0.0,
        highestAverage: 0.0,
        lowestAverage: 0.0,
      );
    }

    int admitted = 0;
    for (final r in results) {
      if (r.isAdmitted) admitted++;
    }
    final failed = results.length - admitted;
    final rate = (admitted / results.length) * 100.0;

    return ClassStatistics(
      totalStudents: results.length,
      admittedCount: admitted,
      failedCount: failed,
      successRate: (rate * 10).round() / 10.0,
      classAverage: results.first.classAverage,
      highestAverage: results.first.classMaxAverage,
      lowestAverage: results.first.classMinAverage,
    );
  }
}

class _StudentSubjectScore {
  final StudentResult result;
  final SubjectGrade grade;
  _StudentSubjectScore(this.result, this.grade);
}
