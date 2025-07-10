import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntryModel {
  final String? id; // MODIFIED: เพิ่ม property 'id' สำหรับเก็บ Document ID
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;

  FoodEntryModel({
    this.id, // MODIFIED: เพิ่ม 'id' เข้าไปใน constructor
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
  });

  // toFirestore ไม่ต้องแก้ไข เพราะเราไม่ต้องการบันทึก id ลงในข้อมูลของ document
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

  // MODIFIED: แก้ไข factory ให้ดึง ID จาก DocumentSnapshot
  factory FoodEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FoodEntryModel(
      id: doc.id, // <-- จุดสำคัญ: ดึง ID ของเอกสารมาใช้งาน
      name: data['name'] ?? '',
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
