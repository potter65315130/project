// data/exercise_database.dart

import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/services/calorie_calculation_strategy.dart';

class ExerciseDatabase {
  static final List<Exercise> allExercises = [
    // --- Weight Training ---
    const Exercise(
      id: 'dumbbell_press',
      name: 'Dumbbell Bench Press',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/dumbbell_press.json',
      calculationStrategy: RepBasedWeightedStrategy(), // ใช้น้ำหนักที่ยก
    ),
    const Exercise(
      id: 'bicep_curls',
      name: 'Dumbbell Bicep Curls',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/dumbbell_press.json',
      calculationStrategy: RepBasedWeightedStrategy(), // ใช้น้ำหนักที่ยก
    ),
    const Exercise(
      id: 'squats',
      name: 'Bodyweight Squats',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/dumbbell_press.json',
      calculationStrategy: RepBasedBodyweightStrategy(), // ใช้น้ำหนักตัว
      bodyweightFactor: 0.45, // Squat ใช้ประมาณ 45% ของน้ำหนักตัว
    ),
    const Exercise(
      id: 'push_ups',
      name: 'Push-ups',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/Push_ups.json',
      calculationStrategy: RepBasedBodyweightStrategy(),
      // วิดพื้นจะใช้แรงจากแขนและอกในการดันลำตัวส่วนบนขึ้น
      // ซึ่งคิดเป็นประมาณ 65% ของน้ำหนักตัว
      bodyweightFactor: 0.65,
    ),
    const Exercise(
      id: 'sit_ups',
      name: 'Sit-ups',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath:
          'assets/lottie/dumbbell_press.json', // ต้องมีไฟล์ Lottie ที่ตรงกัน
      calculationStrategy: RepBasedBodyweightStrategy(),
      // ซิทอัพจะยกแค่ลำตัวส่วนบนขึ้นมา ซึ่งมีน้ำหนักน้อยกว่ามาก
      // คิดเป็นประมาณ 20% ของน้ำหนักตัว
      bodyweightFactor: 0.20,
    ),

    // --- Cardio ---
    const Exercise(
      id: 'jumping_jacks',
      name: 'Jumping Jacks',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/dumbbell_press.json',
      calculationStrategy: MetBasedStrategy(), // ใช้ค่า MET
      metValue: 8.0, // MET value for moderate intensity jumping jacks
    ),
    const Exercise(
      id: 'high_knees',
      name: 'High Knees',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/dumbbell_press.json',
      calculationStrategy: MetBasedStrategy(), // ใช้ค่า MET
      metValue: 8.0,
    ),
    const Exercise(
      id: 'burpees',
      name: 'Burpees',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/dumbbell_press.json',
      calculationStrategy: MetBasedStrategy(), // ใช้ค่า MET
      metValue: 9.0, // Burpees มีความเข้มข้นสูงกว่า
    ),
  ];
}
