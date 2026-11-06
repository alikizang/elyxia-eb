class AcademicYear {
  final int? id;
  final String name; // ex: "2024-2025", "2025-2026"
  final bool isCurrent;
  final bool isClosed; // Si true, verrouillé en lecture seule (garde-fou)
  final String? closedAt;
  final String? notes;

  AcademicYear({
    this.id,
    required this.name,
    this.isCurrent = false,
    this.isClosed = false,
    this.closedAt,
    this.notes,
  });

  factory AcademicYear.fromMap(Map<String, dynamic> map) {
    return AcademicYear(
      id: map['id'],
      name: map['name'] ?? '',
      isCurrent: (map['is_current'] ?? 0) == 1,
      isClosed: (map['is_closed'] ?? 0) == 1,
      closedAt: map['closed_at'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'is_current': isCurrent ? 1 : 0,
      'is_closed': isClosed ? 1 : 0,
      'closed_at': closedAt,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  AcademicYear copyWith({
    int? id,
    String? name,
    bool? isCurrent,
    bool? isClosed,
    String? closedAt,
    String? notes,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      name: name ?? this.name,
      isCurrent: isCurrent ?? this.isCurrent,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
    );
  }
}
