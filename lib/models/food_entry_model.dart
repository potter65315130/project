import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntryModel {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;

  FoodEntryModel({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
  });

  // แปลง Object เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // สร้าง Object จาก DocumentSnapshot ที่ดึงมาจาก Firestore
  factory FoodEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FoodEntryModel(
      name: data['name'] ?? '',
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
