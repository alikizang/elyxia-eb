class Student {
  final int? id;
  final int classId;
  final String matricule;
  final String tableNumber; // N° de table à l'examen
  final String lastName;
  final String firstName;
  final String gender; // "M" ou "F"
  final String birthDate; // "JJ/MM/AAAA"
  final String birthPlace; // Ville ou lieu
  final bool isRepeater; // Doublant: true/false (comme dans test.pdf)
  final String academicYear; // Année académique rattachée

  Student({
    this.id,
    required this.classId,
    this.matricule = '',
    required this.tableNumber,
    required this.lastName,
    required this.firstName,
    required this.gender,
    this.birthDate = '',
    this.birthPlace = '',
    this.isRepeater = false,
    this.academicYear = '2025-2026',
  });

  String get fullName => '$lastName $firstName'.trim().toUpperCase();

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      classId: map['class_id'],
      matricule: map['matricule'] ?? '',
      tableNumber: map['table_number']?.toString() ?? '',
      lastName: map['last_name'] ?? '',
      firstName: map['first_name'] ?? '',
      gender: map['gender'] ?? 'M',
      birthDate: map['birth_date'] ?? '',
      birthPlace: map['birth_place'] ?? '',
      isRepeater: (map['is_repeater'] ?? 0) == 1,
      academicYear: map['academic_year'] ?? '2025-2026',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'class_id': classId,
      'matricule': matricule,
      'table_number': tableNumber,
      'last_name': lastName,
      'first_name': firstName,
      'gender': gender,
      'birth_date': birthDate,
      'birth_place': birthPlace,
      'is_repeater': isRepeater ? 1 : 0,
      'academic_year': academicYear,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Student copyWith({
    int? id,
    int? classId,
    String? matricule,
    String? tableNumber,
    String? lastName,
    String? firstName,
    String? gender,
    String? birthDate,
    String? birthPlace,
    bool? isRepeater,
    String? academicYear,
  }) {
    return Student(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      matricule: matricule ?? this.matricule,
      tableNumber: tableNumber ?? this.tableNumber,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      isRepeater: isRepeater ?? this.isRepeater,
      academicYear: academicYear ?? this.academicYear,
    );
  }
}
