/// Domain model representing an authenticated user synchronized with the backend.
class AuthUser {
  final String id;
  final String firebaseUid;
  final String? email;
  final String? displayName;
  final String timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AuthUser({
    required this.id,
    required this.firebaseUid,
    this.email,
    this.displayName,
    this.timezone = 'UTC',
    required this.createdAt,
    this.updatedAt,
  });

  String get effectiveDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.contains('@')) {
      return email!.split('@').first;
    }
    return 'Emma';
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      firebaseUid: (json['firebaseUid'] ?? json['firebase_uid']) as String? ?? '',
      email: json['email'] as String?,
      displayName: (json['displayName'] ?? json['display_name']) as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'displayName': displayName,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  AuthUser copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? displayName,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'AuthUser(id: $id, firebaseUid: $firebaseUid, email: $email, name: $displayName)';
}
