import 'package:flutter/material.dart';
import 'package:health_mate/screens/exercise/exercise_main_screen.dart';
import 'package:health_mate/screens/home_screen.dart';
import 'package:health_mate/screens/activity_tracking_screen.dart';
import 'package:health_mate/screens/food_category/food_logging_screen.dart';
import 'package:health_mate/screens/weather_screen.dart';

const Color _darkBgColor = Color(0xFF121212);
const Color _accentColor = Color(0xFFB4F82B);
const Color _mediumTextColor = Color(0xFFB0B0B0);

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  AnimationController? _animationController;
  Animation<double>? _animation;

  final List<Widget> _screens = [
    HomeScreen(),
    ExerciseMainScreen(),
    FoodLoggingScreen(),
    WeatherScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    if (_animationController != null) {
      _animationController!.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _darkBgColor,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: _accentColor,
        unselectedItemColor: _mediumTextColor,
        enableFeedback: false,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          _buildBottomNavigationBarItem(
            icon: Icons.home,
            label: 'หน้าหลัก',
            index: 0,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.fitness_center,
            label: 'การออกกำลังกาย',
            index: 1,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.restaurant,
            label: 'อาหาร',
            index: 2,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.cloud,
            label: 'สภาพอากาศ',
            index: 3,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final currentAnimation =
        (_currentIndex == index && _animation != null)
            ? _animation!
            : Tween<double>(
              begin: 1.0,
              end: 1.0,
            ).animate(_animationController!);

    return BottomNavigationBarItem(
      icon: ScaleTransition(scale: currentAnimation, child: Icon(icon)),
      label: label,
    );
  }
}
