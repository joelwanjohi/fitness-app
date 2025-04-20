enum UserStatus { active, inactive, blocked }

class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserStatus status;
  final bool isAdmin;
  final Map<String, int> activityCounts;
  
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.lastLoginAt,
    required this.status,
    required this.isAdmin,
    required this.activityCounts,
  });
  
  int get totalActivity => 
      (activityCounts['meals'] ?? 0) + 
      (activityCounts['workouts'] ?? 0) + 
      (activityCounts['progress'] ?? 0);
  
  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['lastLoginAt']) 
          : null,
      status: _parseStatus(data['status']),
      isAdmin: data['isAdmin'] == true,
      activityCounts: {
        'meals': data['mealCount'] ?? 0,
        'workouts': data['workoutCount'] ?? 0,
        'progress': data['progressCount'] ?? 0,
      },
    );
  }
  
  static UserStatus _parseStatus(String? status) {
    if (status == 'blocked') return UserStatus.blocked;
    if (status == 'inactive') return UserStatus.inactive;
    return UserStatus.active;
  }
  
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status.toString().split('.').last,
      'isAdmin': isAdmin,
    };
  }
}