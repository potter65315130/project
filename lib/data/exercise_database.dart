// data/exercise_database.dart

import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/services/calorie_calculation_strategy.dart';

class ExerciseDatabase {
  static final List<Exercise> allExercises = [
    // --- Weight Training ---
    const Exercise(
      id: 'Squat_kicks',
      name: 'Squat kicks',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/Squat_kicks.json',
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
      id: 'Pull_ups',
      name: 'Pull ups',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/Pull_ups.json',
      calculationStrategy: RepBasedBodyweightStrategy(),
      bodyweightFactor: 0.65,
    ),
    const Exercise(
      id: 'sit_ups',
      name: 'Sit-ups',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath:
          'assets/lottie/sit_ups.json', // ต้องมีไฟล์ Lottie ที่ตรงกัน
      calculationStrategy: RepBasedBodyweightStrategy(),
      // ซิทอัพจะยกแค่ลำตัวส่วนบนขึ้นมา ซึ่งมีน้ำหนักน้อยกว่ามาก
      // คิดเป็นประมาณ 20% ของน้ำหนักตัว
      bodyweightFactor: 0.20,
    ),
    const Exercise(
      id: 'Lunge',
      name: 'Lunge',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/Lunge.json',
      calculationStrategy: RepBasedWeightedStrategy(),
    ),
    const Exercise(
      id: 'shoulder_press',
      name: 'Dumbbell Shoulder Press',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/shoulder_press.json',
      calculationStrategy: RepBasedWeightedStrategy(),
    ),
    const Exercise(
      id: 'deadlift',
      name: 'Deadlift',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/deadlift.json',
      calculationStrategy: RepBasedWeightedStrategy(),
    ),
    const Exercise(
      id: 'tricep_dips',
      name: 'Tricep Dips',
      category: ExerciseCategory.weightTraining,
      lottieAssetPath: 'assets/lottie/tricep_dips.json',
      calculationStrategy: RepBasedBodyweightStrategy(),
      bodyweightFactor: 0.65,
    ),

    // --- Cardio ---
    const Exercise(
      id: 'Split_Jump',
      name: 'Split Jump',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/Split_Jump.json',
      calculationStrategy: MetBasedStrategy(),
      metValue: 8.0,
    ),
    const Exercise(
      id: 'jumping_jacks',
      name: 'Jumping Jacks',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/Jumping_jacks.json',
      calculationStrategy: MetBasedStrategy(),
      metValue: 8.0,
    ),
    const Exercise(
      id: 'Jumping_squat',
      name: 'Jumping squat',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/Jumping_squat.json',
      calculationStrategy: MetBasedStrategy(),
      metValue: 9.0,
    ),
    const Exercise(
      id: 'jump_rope',
      name: 'Jump Rope',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/jump_rope.json',
      calculationStrategy: MetBasedStrategy(),
      metValue: 11.0,
    ),

    const Exercise(
      id: 'burpees',
      name: 'Burpees',
      category: ExerciseCategory.cardio,
      lottieAssetPath: 'assets/lottie/Burpees.json',
      calculationStrategy: MetBasedStrategy(), // ใช้ค่า MET
      metValue: 9.0, // Burpees มีความเข้มข้นสูงกว่า
    ),
  ];
}
