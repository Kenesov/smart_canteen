import 'package:flutter/material.dart';
import '../../data/models/meal_log.dart';

class MealLogItem extends StatelessWidget {
  final MealLog log;

  const MealLogItem({Key? key, required this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF2A9D8F).withOpacity(0.2),
          backgroundImage: log.studentImage.isNotEmpty
              ? NetworkImage(log.studentImage)
              : null,
          child: log.studentImage.isEmpty
              ? const Icon(
            Icons.person,
            size: 30,
            color: Color(0xFF2A9D8F),
          )
              : null,
        ),
        title: Text(
          log.studentName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${log.course}-kurs',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}