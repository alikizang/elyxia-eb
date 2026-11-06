class Subject {
  final int? id;
  final int classId;
  final String name; // ex: "Français", "Philosophie", "Mathématiques"
  final String code; // ex: "FRA", "PHILO", "MATH"
  final double coefficient;
  final int orderIndex;
  final String teacherName; // Nom du professeur (comme sur test.pdf)
  final bool isOptional; // Matière facultative (MF) ou obligatoire (MO)

  Subject({
    this.id,
    required this.classId,
    required this.name,
    required this.code,
    required this.coefficient,
    required this.orderIndex,
    this.teacherName = '',
    this.isOptional = false,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      classId: map['class_id'],
      name: map['name'],
      code: map['code'] ?? '',
      coefficient: (map['coefficient'] as num).toDouble(),
      orderIndex: map['order_index'] ?? 0,
      teacherName: map['teacher_name'] ?? '',
      isOptional: (map['is_optional'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'class_id': classId,
      'name': name,
      'code': code,
      'coefficient': coefficient,
      'order_index': orderIndex,
      'teacher_name': teacherName,
      'is_optional': isOptional ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Subject copyWith({
    int? id,
    int? classId,
    String? name,
    String? code,
    double? coefficient,
    int? orderIndex,
    String? teacherName,
    bool? isOptional,
  }) {
    return Subject(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      code: code ?? this.code,
      coefficient: coefficient ?? this.coefficient,
      orderIndex: orderIndex ?? this.orderIndex,
      teacherName: teacherName ?? this.teacherName,
      isOptional: isOptional ?? this.isOptional,
    );
  }
}
