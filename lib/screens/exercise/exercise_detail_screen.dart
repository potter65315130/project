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
    // ... (ส่วนนี้เหมือนเดิม ไม่ต้องแก้ไข)
    final user = Provider.of<HomeProvider>(context, listen: false).user;
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (user == null || uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')));
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
            ),
          );
          Navigator.pop(context); // Go back to the list
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $error')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Lottie Animation และปุ่มควบคุมเหมือนเดิม)
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _lottieController.repeat(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('เริ่ม'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _lottieController.stop(),
                  icon: const Icon(Icons.stop),
                  label: const Text('หยุด'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- ส่วนที่ปรับปรุง ---
            // ใช้ฟังก์ชันใหม่ในการสร้างฟอร์มตาม Strategy
            _buildInputFields(),

            const SizedBox(height: 32),
            // Log Button
            ElevatedButton(
              onPressed: _logExercise,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('บันทึกการออกกำลังกาย'),
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
      return const Center(child: Text('ไม่รองรับการบันทึกสำหรับท่านี้'));
    }
  }

  // ฟอร์มสำหรับ Weight Training (ใช้น้ำหนัก)
  List<Widget> _buildWeightTrainingFields() {
    return [
      Text('กรอกข้อมูล:', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextField(
        controller: _weightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'น้ำหนักที่ยก (kg)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _setsController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'จำนวนเซ็ต',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _repsController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'จำนวนครั้ง / เซ็ต',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  /// **ฟอร์มใหม่:** สำหรับ Bodyweight (ไม่มีช่องกรอกน้ำหนัก)
  List<Widget> _buildBodyweightFields() {
    return [
      Text('กรอกข้อมูล:', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      // --- ไม่มีช่องกรอกน้ำหนัก ---
      TextField(
        controller: _setsController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'จำนวนเซ็ต',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _repsController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'จำนวนครั้ง / เซ็ต',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  // ฟอร์มสำหรับ Cardio
  List<Widget> _buildCardioFields() {
    return [
      Text('กรอกข้อมูล:', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextField(
        controller: _durationController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'ระยะเวลา (นาที)',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }
}
