// lib/services/calorie_calculation_strategy.dart

import 'package:health_mate/models/exercise_model.dart';

/// คลาสสำหรับรวบรวมพารามิเตอร์ที่จำเป็นในการคำนวณ
class CalculationParams {
  final Exercise exercise;
  final double userWeightKg;
  final int durationMinutes;
  final int sets;
  final int reps;
  final double weightLifted;

  CalculationParams({
    required this.exercise,
    required this.userWeightKg,
    this.durationMinutes = 0,
    this.sets = 0,
    this.reps = 0,
    this.weightLifted = 0,
  });
}

/// Abstract class (ต้นแบบ) สำหรับทุก Strategy การคำนวณแคลอรี่
abstract class CalorieCalculationStrategy {
  const CalorieCalculationStrategy();
  double calculate(CalculationParams params);
}

/// Strategy สำหรับการคำนวณแบบ MET (Cardio)
class MetBasedStrategy extends CalorieCalculationStrategy {
  const MetBasedStrategy();

  @override
  double calculate(CalculationParams params) {
    // สูตรมาตรฐาน: (MET * น้ำหนักตัว (kg) * 3.5) / 200 * เวลา (นาที)
    return (params.exercise.metValue * params.userWeightKg * 3.5) /
        200 *
        params.durationMinutes;
  }
}

/// Strategy สำหรับ Weight Training แบบใช้น้ำหนัก
class RepBasedWeightedStrategy extends CalorieCalculationStrategy {
  const RepBasedWeightedStrategy();

  @override
  double calculate(CalculationParams params) {
    // สูตรพื้นฐาน: Sets * Reps * Weight (kg) * Factor
    // Factor 0.035 เป็นค่าประมาณ อาจปรับเปลี่ยนได้ตามงานวิจัย
    if (params.weightLifted <= 0) return 0; // ป้องกันการคำนวณที่ผิดพลาด
    return params.sets * params.reps * params.weightLifted * 0.035;
  }
}

/// Strategy สำหรับ Weight Training แบบ Bodyweight
class RepBasedBodyweightStrategy extends CalorieCalculationStrategy {
  const RepBasedBodyweightStrategy();

  @override
  double calculate(CalculationParams params) {
    // ใช้ bodyweightFactor ที่กำหนดไว้ในแต่ละท่า เพื่อความแม่นยำ
    // เช่น Squat อาจใช้ 45% ของน้ำหนักตัว, Push-up อาจใช้ 60%
    final effectiveWeight =
        params.userWeightKg * params.exercise.bodyweightFactor;
    return params.sets * params.reps * effectiveWeight * 0.035;
  }
}
