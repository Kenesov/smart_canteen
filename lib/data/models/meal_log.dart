import '../../core/utils/logger.dart';

class MealLog {
  final int id;
  final String studentId;
  final String studentName;
  final String studentImage;
  final String mealType;
  final DateTime mealDate;
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
    try {
      // Validation
      if (!json.containsKey('id') || json['id'] == null) {
        throw FormatException('Missing required field: id');
      }

      // Student details validation - ikkala formatni qo'llab-quvvatlash
      final student = json['student'] ?? json['student_details'];
      if (student == null || student is! Map<String, dynamic>) {
        throw FormatException('Missing or invalid student data');
      }

      // Parse meal date
      DateTime parsedDate;
      try {
        final mealDateStr = json['meal_date'];
        if (mealDateStr == null) {
          throw FormatException('Missing meal_date');
        }
        parsedDate = DateTime.parse(mealDateStr.toString());
      } catch (e) {
        Logger.warning('Failed to parse meal_date, using current time');
        parsedDate = DateTime.now();
      }

      // Safe parsing with defaults
      return MealLog(
        id: json['id'] as int,
        studentId: student['student_id']?.toString() ?? student['pinfl']?.toString() ?? '',
        studentName: _buildFullName(student),
        studentImage: student['image_url']?.toString() ?? student['image']?.toString() ?? '',
        mealType: json['meal_type']?.toString() ?? 'LUNCH',
        mealDate: parsedDate,
        course: _parseInt(student['course']) ?? 1,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to parse MealLog: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Full name qurish
  static String _buildFullName(Map<String, dynamic> student) {
    // Agar full_name bo'lsa, uni ishlatamiz
    if (student.containsKey('full_name') && student['full_name'] != null) {
      final fullName = student['full_name'].toString().trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }

    // Aks holda first_name va last_name dan quramiz
    final firstName = student['first_name']?.toString().trim() ?? '';
    final lastName = student['last_name']?.toString().trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return 'Noma\'lum';
    }

    return '$firstName $lastName'.trim();
  }

  /// Int parse qilish helper
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_image': studentImage,
      'meal_type': mealType,
      'meal_date': mealDate.toIso8601String(),
      'course': course,
    };
  }

  /// Display uchun vaqt formati
  String get formattedTime {
    final hour = mealDate.hour.toString().padLeft(2, '0');
    final minute = mealDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Display uchun kun formati
  String get formattedDate {
    final day = mealDate.day.toString().padLeft(2, '0');
    final month = mealDate.month.toString().padLeft(2, '0');
    final year = mealDate.year;
    return '$day.$month.$year';
  }

  @override
  String toString() {
    return 'MealLog(id: $id, student: $studentName, meal: $mealType, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}