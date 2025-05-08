class Report {
  final String id;
  final String title;
  final String description;
  final DateTime generatedAt;
  final ReportType type;
  final Map<String, dynamic> data;
  final String? filePath;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.generatedAt,
    required this.type,
    required this.data,
    this.filePath,
  });

  // Create from map
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      generatedAt: map['generatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['generatedAt'])
          : DateTime.now(),
      type: ReportType.values.firstWhere(
        (e) => e.toString() == 'ReportType.${map['type']}',
        orElse: () => ReportType.other,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      filePath: map['filePath'],
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'data': data,
      'filePath': filePath,
    };
  }
}

enum ReportType {
  user,
  meal,
  workout,
  progress,
  summary,
  other,
}

class UserReport extends Report {
  UserReport({
    required String id,
    required String title,
    required String description,
    required DateTime generatedAt,
    required Map<String, dynamic> data,
    String? filePath,
  }) : super(
          id: id,
          title: title,
          description: description,
          generatedAt: generatedAt,
          type: ReportType.user,
          data: data,
          filePath: filePath,
        );

  int get totalUsers => data['totalUsers'] ?? 0;
  List<Map<String, dynamic>> get userData => List<Map<String, dynamic>>.from(data['userData'] ?? []);
  Map<String, int> get usersByMonth => Map<String, int>.from(data['usersByMonth'] ?? {});
}

class MealReport extends Report {
  MealReport({
    required String id,
    required String title,
    required String description,
    required DateTime generatedAt,
    required Map<String, dynamic> data,
    String? filePath,
  }) : super(
          id: id,
          title: title,
          description: description,
          generatedAt: generatedAt,
          type: ReportType.meal,
          data: data,
          filePath: filePath,
        );

  int get totalMeals => data['totalMeals'] ?? 0;
  double get avgCaloriesPerMeal => (data['avgCaloriesPerMeal'] ?? 0).toDouble();
  double get avgProteinPerMeal => (data['avgProteinPerMeal'] ?? 0).toDouble();
  Map<String, int> get mealsByType => Map<String, int>.from(data['mealsByType'] ?? {});
  List<Map<String, dynamic>> get topMeals => List<Map<String, dynamic>>.from(data['topMeals'] ?? []);
}

class WorkoutReport extends Report {
  WorkoutReport({
    required String id,
    required String title,
    required String description,
    required DateTime generatedAt,
    required Map<String, dynamic> data,
    String? filePath,
  }) : super(
          id: id,
          title: title,
          description: description,
          generatedAt: generatedAt,
          type: ReportType.workout,
          data: data,
          filePath: filePath,
        );

  int get totalWorkouts => data['totalWorkouts'] ?? 0;
  double get avgWorkoutDuration => (data['avgWorkoutDuration'] ?? 0).toDouble();
  Map<String, int> get workoutsByType => Map<String, int>.from(data['workoutsByType'] ?? {});
  Map<String, int> get workoutsByDay => Map<String, int>.from(data['workoutsByDay'] ?? {});
  List<Map<String, dynamic>> get topWorkouts => List<Map<String, dynamic>>.from(data['topWorkouts'] ?? []);
}

class ProgressReport extends Report {
  ProgressReport({
    required String id,
    required String title,
    required String description,
    required DateTime generatedAt,
    required Map<String, dynamic> data,
    String? filePath,
  }) : super(
          id: id,
          title: title,
          description: description,
          generatedAt: generatedAt,
          type: ReportType.progress,
          data: data,
          filePath: filePath,
        );

  int get totalProgressEntries => data['totalProgressEntries'] ?? 0;
  double get avgProgressScore => (data['avgProgressScore'] ?? 0).toDouble();
  Map<String, double> get progressByMonth => Map<String, double>.from(data['progressByMonth'] ?? {});
  List<Map<String, dynamic>> get userProgress => List<Map<String, dynamic>>.from(data['userProgress'] ?? []);
}

class SummaryReport extends Report {
  SummaryReport({
    required String id,
    required String title,
    required String description,
    required DateTime generatedAt,
    required Map<String, dynamic> data,
    String? filePath,
  }) : super(
          id: id,
          title: title,
          description: description,
          generatedAt: generatedAt,
          type: ReportType.summary,
          data: data,
          filePath: filePath,
        );

  int get totalUsers => data['totalUsers'] ?? 0;
  int get totalMeals => data['totalMeals'] ?? 0;
  int get totalWorkouts => data['totalWorkouts'] ?? 0;
  int get totalProgressEntries => data['totalProgressEntries'] ?? 0;
  int get activeUsersLast7Days => data['activeUsersLast7Days'] ?? 0;
  Map<String, dynamic> get summaryByMonth => Map<String, dynamic>.from(data['summaryByMonth'] ?? {});
}