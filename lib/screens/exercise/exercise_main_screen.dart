// screens/exercise/exercise_main_screen.dart

import 'package:flutter/material.dart';
import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/screens/exercise/exercise_list_screen.dart';

class ExerciseMainScreen extends StatelessWidget {
  const ExerciseMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ออกกำลังกาย')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ปุ่มที่คุณทำเสร็จแล้ว (คำนวณแคลอรี่จากการวิ่ง/จักรยาน)
            _buildMenuButton(
              context,
              icon: Icons.run_circle_outlined,
              text: 'คำนวนแคลอรี่จากการวิ่ง / ปั่นจักรยาน',
              onTap: () {
                // TODO: ใส่ Navigator ไปยังหน้าของคุณ
              },
            ),
            const SizedBox(height: 16),
            // ปุ่มเวทเทรนนิ่ง
            _buildMenuButton(
              context,
              icon: Icons.fitness_center,
              text: 'เวทเทรนนิ่ง / ยิม',
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
            const SizedBox(height: 16),
            // ปุ่มคาร์ดิโอ
            _buildMenuButton(
              context,
              icon: Icons.favorite_border,
              text: 'คาร์ดิโอ / กีฬา',
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

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(text, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
