class MealLog {
  final int id;
  final String studentId;
  final String studentName;
  final String studentImage;
  final String mealType;
  final String mealDate;
  final int course;

  MealLog({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentImage,
    required this.mealType,
    required this.mealDate,
    required this.course,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    final student = json['student_details'] ?? {};
    return MealLog(
      id: json['id'] ?? 0,
      studentId: student['student_id'] ?? '',
      studentName: '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim(),
      studentImage: student['image'] ?? '',
      mealType: json['meal_type'] ?? '',
      mealDate: json['meal_date'] ?? '',
      course: student['course'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_image': studentImage,
      'meal_type': mealType,
      'meal_date': mealDate,
      'course': course,
    };
  }
}