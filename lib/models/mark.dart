class Mark {
  final int? id;
  final int examId;
  final int studentId;
  final int subjectId;
  final double? score; // Note sur 20, ou null si pas encore saisie
  final bool isAbsent; // Absent à l'épreuve

  Mark({
    this.id,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    this.score,
    this.isAbsent = false,
  });

  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      id: map['id'],
      examId: map['exam_id'],
      studentId: map['student_id'],
      subjectId: map['subject_id'],
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      isAbsent: (map['is_absent'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'exam_id': examId,
      'student_id': studentId,
      'subject_id': subjectId,
      'score': score,
      'is_absent': isAbsent ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
