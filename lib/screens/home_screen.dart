// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_mate/screens/activity_tracking_screen.dart';
import 'package:health_mate/screens/food_category/food_logging_screen.dart';
import 'package:health_mate/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:health_mate/models/user_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:health_mate/screens/history/history_screen.dart';
import 'package:health_mate/services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
    }
  }

  void _navigateToHistoryScreen(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen(user: user)),
    );
  }

  void _navigateToAddCalories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodLoggingScreen()),
    );
  }

  void _navigateToBurnCalories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivityTrackingScreen()),
    );
  }

  Future<void> _showUpdateWeightDialog(BuildContext context) async {
    final homeProvider = context.read<HomeProvider>();
    final user = homeProvider.user;
    if (user == null) return;

    final TextEditingController weightController = TextEditingController(
      text: user.weight.toString(),
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('บันทึกน้ำหนัก'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('กรุณาใส่น้ำหนักปัจจุบันของคุณ (กก.)'),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'น้ำหนัก (กก.)',
                    suffixText: 'กก.',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('บันทึก'),
              onPressed: () async {
                final newWeight = double.tryParse(weightController.text);
                if (newWeight != null && newWeight > 0) {
                  await homeProvider.updateWeight(user.uid!, newWeight);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('บันทึกน้ำหนักเรียบร้อยแล้ว'),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณาใส่น้ำหนักที่ถูกต้อง'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'ผอมเกินไป';
    if (bmi < 25) return 'สมสวน';
    if (bmi < 30) return 'น้ำหนักเกิน';
    if (bmi < 35) return 'อ้วน';
    return 'อ้วนมาก';
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final user = homeProvider.user;
    final quest = homeProvider.quest;

    if (homeProvider.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null || quest == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ไม่สามารถโหลดข้อมูลได้'),
              ElevatedButton(
                onPressed: () => context.read<HomeProvider>().loadData(),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    final remainingCal = quest.netCalorie;
    final intake = quest.calorieIntake;
    final burned = quest.calorieBurned;
    final weight = quest.weight;
    final targetWeight = user.targetWeight;
    final bmi = user.calculateBMI();
    final bmr = user.calculateBMR();
    final daysLeft = FirestoreService().calculateDaysLeft(user);
    final calorieProgress =
        quest.calorieTarget > 0
            ? (quest.calorieTarget - remainingCal) / quest.calorieTarget
            : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Diary'),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติ',
            onPressed: () => _navigateToHistoryScreen(context, user),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body:
          homeProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.lightGreen, Colors.white, Colors.white],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Section - User Info
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Weight Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'น้ำหนักปัจจุบัน',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      '${weight.toStringAsFixed(1)} กก.',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'น้ำหนักเป้าหมาย',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      '${targetWeight.toStringAsFixed(1)} กก.',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed:
                                      () => _showUpdateWeightDialog(context),
                                  child: const Text('อัปเดต'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // BMI and BMR Info
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'BMI',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          bmi.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _getBMIStatus(bmi),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'BMR',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          bmr.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'kcal/วัน',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'เหลือ',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          daysLeft.toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'วัน',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Calorie Progress
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'แคลอรี่ที่เหลือ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${remainingCal.toInt()}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          remainingCal >= 0
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                  const Text(
                                    'kcal',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: calorieProgress.clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      calorieProgress > 1.0
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Food and Exercise Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => _navigateToAddCalories(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'แคลอรี่ได้รับจากอาหาร',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Icon(
                                            Icons.restaurant,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${intake.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const Text(
                                            'kcal',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => _navigateToBurnCalories(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'เผาผลาญจากการออกกำลังกาย',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Icon(
                                            Icons.fitness_center,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${burned.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const Text(
                                            'kcal',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              ),
    );
  }
}
