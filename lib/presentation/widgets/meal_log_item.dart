import 'package:flutter/material.dart';
import '../../data/models/meal_log.dart';

class MealLogItem extends StatelessWidget {
  final MealLog log;
  final bool showTime;

  const MealLogItem({
    Key? key,
    required this.log,
    this.showTime = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.school,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${log.course}-kurs',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),

              ],
            ),
          ],
        ),
        trailing: showTime
            ? Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2A9D8F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.formattedTime,
            style: const TextStyle(
              color: Color(0xFF2A9D8F),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        )
            : null,
      ),
    );
  }
}