class Subject {
  final int? id;
  final int classId;
  final String name; // ex: "Français", "Philosophie", "Mathématiques"
  final String code; // ex: "FRA", "PHILO", "MATH"
  final double coefficient;
  final int orderIndex;

  Subject({
    this.id,
    required this.classId,
    required this.name,
    required this.code,
    required this.coefficient,
    required this.orderIndex,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      classId: map['class_id'],
      name: map['name'],
      code: map['code'] ?? '',
      coefficient: (map['coefficient'] as num).toDouble(),
      orderIndex: map['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'class_id': classId,
      'name': name,
      'code': code,
      'coefficient': coefficient,
      'order_index': orderIndex,
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
  }) {
    return Subject(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      code: code ?? this.code,
      coefficient: coefficient ?? this.coefficient,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
