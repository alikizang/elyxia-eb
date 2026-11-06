class AppSettings {
  final int id;
  final String schoolName;
  final String schoolSubTitle;
  final String schoolAddress;
  final String schoolPhone;
  final String schoolEmail;
  final String academicYear;
  final String republicHeader;
  final String directorTitle;
  final String directorName;
  final String juryPresidentTitle;

  AppSettings({
    this.id = 1,
    required this.schoolName,
    this.schoolSubTitle = "Enseignement Secondaire Général - Séries Littéraires et Scientifiques",
    this.schoolAddress = "Lomé - TOGO",
    this.schoolPhone = "+228 90 00 00 00 / 99 00 00 00",
    this.schoolEmail = "contact@lesvictorieux.tg",
    required this.academicYear,
    this.republicHeader = "RÉPUBLIQUE TOGOLAISE\nTravail - Liberté - Patrie\nMINISTÈRE DES ENSEIGNEMENTS PRIMAIRE, SECONDAIRE ET TECHNIQUE",
    this.directorTitle = "Le Chef d'Établissement",
    this.directorName = "Direction Générale",
    this.juryPresidentTitle = "Le Président du Jury",
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] ?? 1,
      schoolName: map['school_name'] ?? "COMPLEXE SCOLAIRE LES VICTORIEUX",
      schoolSubTitle: map['school_sub_title'] ?? "Enseignement Secondaire Général - Séries Littéraires et Scientifiques",
      schoolAddress: map['school_address'] ?? "Lomé - TOGO",
      schoolPhone: map['school_phone'] ?? "+228 90 00 00 00 / 99 00 00 00",
      schoolEmail: map['school_email'] ?? "contact@lesvictorieux.tg",
      academicYear: map['academic_year'] ?? "2025-2026",
      republicHeader: map['republic_header'] ?? "RÉPUBLIQUE TOGOLAISE\nTravail - Liberté - Patrie\nMINISTÈRE DES ENSEIGNEMENTS PRIMAIRE, SECONDAIRE ET TECHNIQUE",
      directorTitle: map['director_title'] ?? "Le Chef d'Établissement",
      directorName: map['director_name'] ?? "Direction Générale",
      juryPresidentTitle: map['jury_president_title'] ?? "Le Président du Jury",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_name': schoolName,
      'school_sub_title': schoolSubTitle,
      'school_address': schoolAddress,
      'school_phone': schoolPhone,
      'school_email': schoolEmail,
      'academic_year': academicYear,
      'republic_header': republicHeader,
      'director_title': directorTitle,
      'director_name': directorName,
      'jury_president_title': juryPresidentTitle,
    };
  }

  AppSettings copyWith({
    String? schoolName,
    String? schoolSubTitle,
    String? schoolAddress,
    String? schoolPhone,
    String? schoolEmail,
    String? academicYear,
    String? republicHeader,
    String? directorTitle,
    String? directorName,
    String? juryPresidentTitle,
  }) {
    return AppSettings(
      id: id,
      schoolName: schoolName ?? this.schoolName,
      schoolSubTitle: schoolSubTitle ?? this.schoolSubTitle,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      schoolPhone: schoolPhone ?? this.schoolPhone,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      academicYear: academicYear ?? this.academicYear,
      republicHeader: republicHeader ?? this.republicHeader,
      directorTitle: directorTitle ?? this.directorTitle,
      directorName: directorName ?? this.directorName,
      juryPresidentTitle: juryPresidentTitle ?? this.juryPresidentTitle,
    );
  }
}
