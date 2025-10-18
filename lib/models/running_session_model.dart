import 'package:cloud_firestore/cloud_firestore.dart';

class RunningSessionModel {
  final String? id; // <-- เพิ่ม
  final String? uid; // <-- เพิ่ม
  final double distance; // ระยะทาง (เมตร)
  final int durationSeconds; // ระยะเวลา (วินาที)
  final double caloriesBurned;
  final DateTime timestamp;

  RunningSessionModel({
    this.id, // <-- เพิ่ม
    this.uid, // <-- เพิ่ม
    required this.distance,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.timestamp,
  });

  // แปลง Object เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid, // <-- เพิ่ม
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
      id: doc.id, // <-- เพิ่ม
      uid: data['uid'] as String?, // <-- เพิ่ม
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
