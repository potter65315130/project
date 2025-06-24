import 'package:cloud_firestore/cloud_firestore.dart';

class RunningSessionModel {
  final double distance; // ระยะทาง (เมตร)
  final int durationSeconds; // ระยะเวลา (วินาที)
  final double caloriesBurned;
  final DateTime timestamp;

  RunningSessionModel({
    required this.distance,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.timestamp,
  });

  // แปลง Object เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'distance': distance,
      'durationSeconds': durationSeconds,
      'caloriesBurned': caloriesBurned,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // สร้าง Object จาก DocumentSnapshot ที่ดึงมาจาก Firestore
  factory RunningSessionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return RunningSessionModel(
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
