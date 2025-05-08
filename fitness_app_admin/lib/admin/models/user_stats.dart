class UserStats {
  final String userId;
  final String? userName;
  final String? email;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final double? bmi;
  final DateTime? registrationDate;
  final DateTime? lastActiveDate;
  final Map<String, dynamic> activityStats;

  UserStats({
    required this.userId,
    this.userName,
    this.email,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.bmi,
    this.registrationDate,
    this.lastActiveDate,
    required this.activityStats,
  });

  // Create from Firestore data
  factory UserStats.fromFirestore(Map<String, dynamic> data, String id) {
    return UserStats(
      userId: id,
      userName: data['name'],
      email: data['email'],
      age: data['age'],
      gender: data['gender'],
      height: data['height'] != null ? double.parse(data['height'].toString()) : null,
      weight: data['weight'] != null ? double.parse(data['weight'].toString()) : null,
      bmi: data['bmi'] != null ? double.parse(data['bmi'].toString()) : null,
      registrationDate: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null,
      lastActiveDate: data['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastActive'])
          : null,
      activityStats: data['activityStats'] ?? {},
    );
  }

  // Calculate membership duration in days
  int get membershipDuration {
    if (registrationDate == null) return 0;
    
    final now = DateTime.now();
    return now.difference(registrationDate!).inDays;
  }

  // Get BMI category based on BMI value
  String get bmiCategory {
    if (bmi == null) return 'Unknown';
    
    if (bmi! < 18.5) {
      return 'Underweight';
    } else if (bmi! < 25) {
      return 'Normal weight';
    } else if (bmi! < 30) {
      return 'Overweight';
    } else {
      return 'Obesity';
    }
  }

  // Get total meal count
  int get totalMealCount => activityStats['mealCount'] ?? 0;

  // Get total workout count
  int get totalWorkoutCount => activityStats['workoutCount'] ?? 0;

  // Get progress entry count
  int get progressEntryCount => activityStats['progressCount'] ?? 0;

  // Get total activity count (meals + workouts + progress)
  int get totalActivityCount => totalMealCount + totalWorkoutCount + progressEntryCount;

  // Check if user is active (had activity in the last 7 days)
  bool get isActive {
    if (lastActiveDate == null) return false;
    
    final now = DateTime.now();
    return now.difference(lastActiveDate!).inDays <= 7;
  }

  // Get activity level
  String get activityLevel {
    final activityCount = totalActivityCount;
    
    if (activityCount == 0) {
      return 'Inactive';
    } else if (activityCount < 10) {
      return 'Low';
    } else if (activityCount < 30) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'registrationDate': registrationDate?.millisecondsSinceEpoch,
      'lastActiveDate': lastActiveDate?.millisecondsSinceEpoch,
      'membershipDuration': membershipDuration,
      'activityStats': activityStats,
      'isActive': isActive,
      'activityLevel': activityLevel,
    };
  }
}