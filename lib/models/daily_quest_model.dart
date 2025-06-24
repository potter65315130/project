import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyQuestModel {
  final String id;
  final DateTime date;
  final double calorieTarget;
  final double calorieIntake;
  final double calorieBurned;
  final double weight;

  DailyQuestModel({
    required this.id,
    required this.date,
    required this.calorieTarget,
    required this.calorieIntake,
    required this.calorieBurned,
    required this.weight,
  });

  /// ค่าแคลอรี่สุทธิที่เหลือ
  double get netCalorie => calorieTarget - calorieIntake + calorieBurned;

  /// ตรวจสอบว่าภารกิจสำเร็จหรือไม่
  bool get isCompleted => netCalorie <= 0;

  /// แปลงเป็น String สำหรับใช้เป็น document ID
  String get dateId => DateFormat('yyyy-MM-dd').format(date);

  /// แปลงเป็น String สำหรับแสดงผล (ภาษาไทย)
  String get displayDate => DateFormat('EEEE, d MMMM y', 'th').format(date);

  /// ตรวจสอบว่าเป็นวันนี้หรือไม่
  bool get isToday {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// ตรวจสอบว่าเป็นเมื่อวานหรือไม่
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  factory DailyQuestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for DailyQuestModel ID: ${snapshot.id}');
    }

    return DailyQuestModel(
      id: snapshot.id,
      date: (data['date'] as Timestamp? ?? Timestamp.now()).toDate(),
      calorieTarget: (data['calorieTarget'] ?? 0.0).toDouble(),
      calorieIntake: (data['calorieIntake'] ?? 0.0).toDouble(),
      calorieBurned: (data['calorieBurned'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'calorieTarget': calorieTarget,
      'calorieIntake': calorieIntake,
      'calorieBurned': calorieBurned,
      'weight': weight,
    };
  }

  DailyQuestModel copyWith({
    String? id,
    DateTime? date,
    double? calorieTarget,
    double? calorieIntake,
    double? calorieBurned,
    double? weight,
  }) {
    return DailyQuestModel(
      id: id ?? this.id,
      date: date ?? this.date,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      calorieIntake: calorieIntake ?? this.calorieIntake,
      calorieBurned: calorieBurned ?? this.calorieBurned,
      weight: weight ?? this.weight,
    );
  }

  @override
  String toString() {
    return 'DailyQuestModel(id: $id, date: $date, calorieTarget: $calorieTarget, calorieIntake: $calorieIntake, calorieBurned: $calorieBurned, weight: $weight)';
  }
}
