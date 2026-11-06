class Exam {
  final int? id;
  final String title; // "Examen Blanc N°1", "Examen Blanc N°2"
  final String sessionDate; // "Mars 2026", "Mai 2026"
  final String academicYear; // "2025-2026"
  final bool isActive;

  Exam({
    this.id,
    required this.title,
    required this.sessionDate,
    required this.academicYear,
    this.isActive = true,
  });

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      title: map['title'],
      sessionDate: map['session_date'] ?? '',
      academicYear: map['academic_year'] ?? '',
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'session_date': sessionDate,
      'academic_year': academicYear,
      'is_active': isActive ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Exam copyWith({
    int? id,
    String? title,
    String? sessionDate,
    String? academicYear,
    bool? isActive,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      sessionDate: sessionDate ?? this.sessionDate,
      academicYear: academicYear ?? this.academicYear,
      isActive: isActive ?? this.isActive,
    );
  }
}
