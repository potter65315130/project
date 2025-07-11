// models/exercise_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseLogModel {
  final String? id;
  final String exerciseId;
  final String exerciseName;
  final DateTime timestamp;
  final double caloriesBurned;
  final int sets;
  final int reps;
  final double weight; // น้ำหนักที่ใช้ (kg)

  ExerciseLogModel({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.timestamp,
    required this.caloriesBurned,
    this.sets = 0,
    this.reps = 0,
    this.weight = 0,
  });

  factory ExerciseLogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ExerciseLogModel(
      id: doc.id,
      exerciseId: data['exerciseId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      caloriesBurned: (data['caloriesBurned'] as num).toDouble(),
      sets: data['sets'] ?? 0,
      reps: data['reps'] ?? 0,
      weight: (data['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'timestamp': Timestamp.fromDate(timestamp),
      'caloriesBurned': caloriesBurned,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }
}
