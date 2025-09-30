import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/services/api_service.dart';
import '../widgets/meal_card.dart';
import 'face_detection_screen.dart';
import 'login_screen.dart';

class MenuScreen extends StatelessWidget {
  final CameraDescription camera;
  const MenuScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ovqat Tanlash',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService().logout();
              Logger.info('User logged out');
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(camera: camera),
                  ),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.primaryColor, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Ovqat vaqtini tanlang',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Studentni identifikatsiya qilish uchun',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                MealCard(
                  icon: Icons.wb_sunny,
                  title: 'Nonushta',
                  subtitle: 'Ertalabki ovqat',
                  color: AppConstants.breakfastColor,
                  onTap: () => _navigateToDetection(context, 'nonushta'),
                ),
                const SizedBox(height: 20),
                MealCard(
                  icon: Icons.restaurant,
                  title: 'Tushlik',
                  subtitle: 'Kunduzi ovqat',
                  color: AppConstants.lunchColor,
                  onTap: () => _navigateToDetection(context, 'tushlik'),
                ),
                const SizedBox(height: 20),
                MealCard(
                  icon: Icons.nights_stay,
                  title: 'Kechki Ovqat',
                  subtitle: 'Kechqurun ovqat',
                  color: AppConstants.dinnerColor,
                  onTap: () => _navigateToDetection(context, 'kechki_ovqat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetection(BuildContext context, String mealType) {
    Logger.info('Navigating to detection: $mealType');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceDetectionScreen(
          camera: camera,
          mealType: mealType,
        ),
      ),
    );
  }
}