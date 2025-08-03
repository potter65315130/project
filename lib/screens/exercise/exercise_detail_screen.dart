// screens/exercise/exercise_detail_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/providers/exercise_provider.dart';
import 'package:health_mate/providers/home_provider.dart';
// เพิ่ม import สำหรับ Strategy
import 'package:health_mate/services/calorie_calculation_strategy.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;

  // Form controllers
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '12');
  final _weightController = TextEditingController(text: '10');
  final _durationController = TextEditingController(text: '15');

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // สำหรับท่า Bodyweight ไม่จำเป็นต้องมีค่าน้ำหนักเริ่มต้น
    if (widget.exercise.calculationStrategy is RepBasedBodyweightStrategy) {
      _weightController.text = '0';
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _logExercise() {
    final user = Provider.of<HomeProvider>(context, listen: false).user;
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (user == null || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse values from controllers
    final sets = int.tryParse(_setsController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final duration = int.tryParse(_durationController.text) ?? 0;

    // Calculate calories
    final caloriesBurned = exerciseProvider.calculateCalories(
      exercise: widget.exercise,
      userWeightKg: user.weight,
      durationMinutes: duration,
      sets: sets,
      reps: reps,
      weightLifted: weight,
    );

    // Log the exercise
    exerciseProvider
        .logExercise(
          uid: uid,
          exercise: widget.exercise,
          caloriesBurned: caloriesBurned,
          sets: sets,
          reps: reps,
          weight: weight,
        )
        .then((_) {
          // Refresh home screen data
          Provider.of<HomeProvider>(context, listen: false).loadData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'บันทึกสำเร็จ! เผาผลาญไป ${caloriesBurned.toStringAsFixed(1)} แคลอรี่',
              ),
              backgroundColor: const Color(0xFF9ACD32),
            ),
          );
          Navigator.pop(context); // Go back to the list
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lottie Animation
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
              ),
              child: Lottie.asset(
                widget.exercise.lottieAssetPath,
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _lottieController.repeat(),
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text(
                    'เริ่ม',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9ACD32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _lottieController.stop(),
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: const Text(
                    'หยุด',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    side: const BorderSide(color: Color(0xFF3A3A3A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Divider
            Container(height: 1, color: const Color(0xFF3A3A3A)),
            const SizedBox(height: 24),

            // Input fields
            _buildInputFields(),

            const SizedBox(height: 32),

            // Log Button
            ElevatedButton(
              onPressed: _logExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9ACD32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'บันทึกการออกกำลังกาย',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **ฟังก์ชันใหม่:** ตรวจสอบ Strategy และเลือกแสดงฟอร์มที่ถูกต้อง
  Widget _buildInputFields() {
    final strategy = widget.exercise.calculationStrategy;

    // 1. ถ้าเป็นท่าที่ใช้น้ำหนักยก (เช่น Dumbbell Press)
    if (strategy is RepBasedWeightedStrategy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildWeightTrainingFields(),
      );
    }
    // 2. ถ้าเป็นท่า Bodyweight (เช่น Sit-ups, Push-ups)
    else if (strategy is RepBasedBodyweightStrategy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildBodyweightFields(),
      );
    }
    // 3. ถ้าเป็น Cardio
    else if (strategy is MetBasedStrategy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildCardioFields(),
      );
    }
    // กรณีอื่นๆ (ถ้ามี)
    else {
      return const Center(
        child: Text(
          'ไม่รองรับการบันทึกสำหรับท่านี้',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
  }

  // ฟอร์มสำหรับ Weight Training (ใช้น้ำหนัก)
  List<Widget> _buildWeightTrainingFields() {
    return [
      Text(
        'กรอกข้อมูล:',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _weightController,
        label: 'น้ำหนักที่ยก (kg)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _setsController,
        label: 'จำนวนเซ็ต',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _repsController,
        label: 'จำนวนครั้ง / เซ็ต',
        keyboardType: TextInputType.number,
      ),
    ];
  }

  /// **ฟอร์มใหม่:** สำหรับ Bodyweight (ไม่มีช่องกรอกน้ำหนัก)
  List<Widget> _buildBodyweightFields() {
    return [
      Text(
        'กรอกข้อมูล:',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _setsController,
        label: 'จำนวนเซ็ต',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _repsController,
        label: 'จำนวนครั้ง / เซ็ต',
        keyboardType: TextInputType.number,
      ),
    ];
  }

  // ฟอร์มสำหรับ Cardio
  List<Widget> _buildCardioFields() {
    return [
      Text(
        'กรอกข้อมูล:',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _durationController,
        label: 'ระยะเวลา (นาที)',
        keyboardType: TextInputType.number,
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9ACD32)),
        ),
      ),
    );
  }
}
