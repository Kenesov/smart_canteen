import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'menu_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;
  const HomeScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? MenuScreen(camera: widget.camera)
          : HistoryScreen(camera: widget.camera),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF2A9D8F),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Tarix',
          ),
        ],
      ),
    );
  }
}