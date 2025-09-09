import 'package:health_mate/services/calorie_calculation_strategy.dart';

enum ExerciseCategory { weightTraining, cardio }

class Exercise {
  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final String lottieAssetPath;

  /// Strategy ที่จะใช้ในการคำนวณแคลอรี่สำหรับท่านี้
  final CalorieCalculationStrategy calculationStrategy;

  // --- ค่าเฉพาะสำหรับบางสูตร ---

  /// ค่า MET (สำหรับ MetBasedStrategy)
  final double metValue;

  /// สัดส่วนน้ำหนักตัวที่ใช้ในท่า Bodyweight (สำหรับ RepBasedBodyweightStrategy)
  /// เช่น 0.5 หมายถึงใช้ 50% ของน้ำหนักตัวในการคำนวณ
  final double bodyweightFactor;

  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.lottieAssetPath,
    required this.calculationStrategy,
    this.metValue = 0.0,
    this.bodyweightFactor = 0.5, // ค่าเริ่มต้นสำหรับท่า Bodyweight ทั่วไป
  });
}
