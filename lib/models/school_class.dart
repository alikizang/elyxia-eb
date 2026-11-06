class SchoolClass {
  final int? id;
  final String name; // ex: "1ère A4", "1ère D", "Terminale D"
  final String level; // "1ère" ou "Terminale"
  final String series; // "A4", "D", "C", "G1", "G2"
  final String examType; // "BAC 1" ou "BAC 2"

  SchoolClass({
    this.id,
    required this.name,
    required this.level,
    required this.series,
    required this.examType,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      series: map['series'],
      examType: map['exam_type'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'level': level,
      'series': series,
      'exam_type': examType,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
