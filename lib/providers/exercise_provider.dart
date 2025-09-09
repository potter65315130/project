import 'package:flutter/material.dart';
import 'package:health_mate/data/exercise_database.dart';
import 'package:health_mate/models/exercise_log_model.dart';
import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/services/calorie_calculation_strategy.dart';
import 'package:health_mate/services/firestore_service.dart';

class ExerciseProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  final List<Exercise> _allExercises = ExerciseDatabase.allExercises;
  List<Exercise> _filteredExercises = [];
  String _searchQuery = '';

  List<Exercise> get filteredExercises => _filteredExercises;

  void filterExercises(ExerciseCategory category, {String? query}) {
    _searchQuery = query ?? _searchQuery;
    _filteredExercises =
        _allExercises.where((ex) {
          final categoryMatch = ex.category == category;
          final queryMatch =
              _searchQuery.isEmpty ||
              ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return categoryMatch && queryMatch;
        }).toList();
    notifyListeners();
  }

  /// ค้นหาท่าออกกำลังกายจากชื่อที่ระบุ
  /// ใช้ในหน้า 'รายการของฉัน' เพื่อดึงข้อมูลสำหรับหน้า Detail
  Exercise? findExerciseByName(String name) {
    try {
      // ค้นหาท่าออกกำลังกายตัวแรกใน List _allExercises ที่มีชื่อตรงกัน
      return _allExercises.firstWhere((exercise) => exercise.name == name);
    } catch (e) {
      // ถ้าใช้ firstWhere แล้วหาไม่เจอ จะเกิด Error,
      // เราใช้ try-catch ดักไว้ และ return null แทนเพื่อไม่ให้แอปพัง
      return null;
    }
  }

  /// ฟังก์ชันคำนวณแคลอรี่ที่เรียกใช้ Strategy ที่เหมาะสม
  double calculateCalories({
    required Exercise exercise,
    required double userWeightKg,
    int durationMinutes = 0,
    int sets = 0,
    int reps = 0,
    double weightLifted = 0,
  }) {
    // 1. สร้าง object เพื่อรวบรวมพารามิเตอร์
    final params = CalculationParams(
      exercise: exercise,
      userWeightKg: userWeightKg,
      durationMinutes: durationMinutes,
      sets: sets,
      reps: reps,
      weightLifted: weightLifted,
    );

    // 2. เรียกใช้ strategy ที่ผูกอยู่กับ Exercise object เพื่อคำนวณ
    return exercise.calculationStrategy.calculate(params);
  }

  Future<void> logExercise({
    required String uid,
    required Exercise exercise,
    required double caloriesBurned,
    int sets = 0,
    int reps = 0,
    double weight = 0,
  }) async {
    final log = ExerciseLogModel(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      timestamp: DateTime.now(),
      caloriesBurned: caloriesBurned,
      sets: sets,
      reps: reps,
      weight: weight,
    );
    await _firestoreService.logExercise(uid, log);
  }
}
