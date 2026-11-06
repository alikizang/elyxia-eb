class AppUser {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String role; // "admin", "teacher", "secretary"
  final String createdAt;

  AppUser({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.role = 'admin',
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrateur / Direction';
      case 'teacher':
        return 'Enseignant / Saisie';
      case 'secretary':
        return 'Secrétariat';
      default:
        return 'Utilisateur';
    }
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      fullName: map['full_name'] ?? '',
      role: map['role'] ?? 'admin',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
