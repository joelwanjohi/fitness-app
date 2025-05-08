class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final DateTime lastLogin;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.lastLogin,
  });

  // Create from Firestore document
  factory AdminUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'admin',
      lastLogin: data['lastLogin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastLogin'])
          : DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
    };
  }
}