class AppSettings {
  final int id;
  final String schoolName;
  final String schoolSubTitle;
  final String schoolSlogan;
  final String schoolAddress;
  final String schoolPoBox;
  final String schoolCity;
  final String schoolPhone;
  final String schoolEmail;
  final String academicYear;
  final String republicHeader;
  final String directorTitle;
  final String directorName;
  final String juryPresidentTitle;
  final String primaryColorHex;
  final String accentColorHex;
  final String? logoBase64;

  AppSettings({
    this.id = 1,
    required this.schoolName,
    this.schoolSubTitle = "Lycée Privé Laïc — BAC 1 & BAC 2",
    this.schoolSlogan = "Discipline - Travail - Succès",
    this.schoolAddress = "Zopomahé, Sanguéra",
    this.schoolPoBox = "23 BP 124 Lomé-TOGO",
    this.schoolCity = "Lomé - TOGO",
    this.schoolPhone = "+228 90 41 07 07 / 90 12 34 56",
    this.schoolEmail = "contact@lesvictorieux.tg",
    required this.academicYear,
    this.republicHeader = "RÉPUBLIQUE TOGOLAISE\nTravail - Liberté - Patrie\nMINISTÈRE DE L'EDUCATION NATIONALE",
    this.directorTitle = "Le Directeur / Chef d'Établissement",
    this.directorName = "Direction Générale",
    this.juryPresidentTitle = "Le Président du Jury",
    this.primaryColorHex = "#22577A",
    this.accentColorHex = "#3BCC97",
    this.logoBase64,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] ?? 1,
      schoolName: map['school_name'] ?? "COMPLEXE SCOLAIRE LES VICTORIEUX",
      schoolSubTitle: map['school_sub_title'] ?? "Lycée Privé Laïc — BAC 1 & BAC 2",
      schoolSlogan: map['school_slogan'] ?? "Discipline - Travail - Succès",
      schoolAddress: map['school_address'] ?? "Zopomahé, Sanguéra",
      schoolPoBox: map['school_po_box'] ?? "23 BP 124 Lomé-TOGO",
      schoolCity: map['school_city'] ?? "Lomé - TOGO",
      schoolPhone: map['school_phone'] ?? "+228 90 41 07 07 / 90 12 34 56",
      schoolEmail: map['school_email'] ?? "contact@lesvictorieux.tg",
      academicYear: map['academic_year'] ?? "2025-2026",
      republicHeader: map['republic_header'] ?? "RÉPUBLIQUE TOGOLAISE\nTravail - Liberté - Patrie\nMINISTÈRE DE L'EDUCATION NATIONALE",
      directorTitle: map['director_title'] ?? "Le Directeur / Chef d'Établissement",
      directorName: map['director_name'] ?? "Direction Générale",
      juryPresidentTitle: map['jury_president_title'] ?? "Le Président du Jury",
      primaryColorHex: map['primary_color'] ?? "#22577A",
      accentColorHex: map['accent_color'] ?? "#3BCC97",
      logoBase64: map['logo_base64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_name': schoolName,
      'school_sub_title': schoolSubTitle,
      'school_slogan': schoolSlogan,
      'school_address': schoolAddress,
      'school_po_box': schoolPoBox,
      'school_city': schoolCity,
      'school_phone': schoolPhone,
      'school_email': schoolEmail,
      'academic_year': academicYear,
      'republic_header': republicHeader,
      'director_title': directorTitle,
      'director_name': directorName,
      'jury_president_title': juryPresidentTitle,
      'primary_color': primaryColorHex,
      'accent_color': accentColorHex,
      'logo_base64': logoBase64,
    };
  }

  AppSettings copyWith({
    String? schoolName,
    String? schoolSubTitle,
    String? schoolSlogan,
    String? schoolAddress,
    String? schoolPoBox,
    String? schoolCity,
    String? schoolPhone,
    String? schoolEmail,
    String? academicYear,
    String? republicHeader,
    String? directorTitle,
    String? directorName,
    String? juryPresidentTitle,
    String? primaryColorHex,
    String? accentColorHex,
    String? logoBase64,
  }) {
    return AppSettings(
      id: id,
      schoolName: schoolName ?? this.schoolName,
      schoolSubTitle: schoolSubTitle ?? this.schoolSubTitle,
      schoolSlogan: schoolSlogan ?? this.schoolSlogan,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      schoolPoBox: schoolPoBox ?? this.schoolPoBox,
      schoolCity: schoolCity ?? this.schoolCity,
      schoolPhone: schoolPhone ?? this.schoolPhone,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      academicYear: academicYear ?? this.academicYear,
      republicHeader: republicHeader ?? this.republicHeader,
      directorTitle: directorTitle ?? this.directorTitle,
      directorName: directorName ?? this.directorName,
      juryPresidentTitle: juryPresidentTitle ?? this.juryPresidentTitle,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      logoBase64: logoBase64 ?? this.logoBase64,
    );
  }
}
