import 'package:flutter/material.dart';
import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/screens/activity_tracking_screen.dart';
import 'package:health_mate/screens/exercise/exercise_list_screen.dart';

class ExerciseMainScreen extends StatelessWidget {
  const ExerciseMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'ออกกำลังกาย',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // คำนวนแคลอรี่
            _buildExerciseCard(
              context,
              icon: Icons.directions_run,
              title: 'คำนวนแคลอรี่จากการวิ่ง / ปั่นจักรยาน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityTrackingScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // เวทเทรนนิ่ง
            _buildExerciseCard(
              context,
              icon: Icons.fitness_center,
              title: 'เวทเทรนนิ่ง / ยิม',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const ExerciseListScreen(
                          category: ExerciseCategory.weightTraining,
                          title: 'เวทเทรนนิ่ง',
                        ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // คาร์ดิโอ
            _buildExerciseCard(
              context,
              icon: Icons.favorite_border,
              title: 'คาร์ดิโอ / กีฬา',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const ExerciseListScreen(
                          category: ExerciseCategory.cardio,
                          title: 'คาร์ดิโอ',
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9ACD32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
