import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? uid;
  final String name;
  final String email;

  final double weight;
  final double targetWeight;
  final double height;
  final int age;
  final String gender;

  final double bmi;
  final double bmr;
  final double activityFactor;

  final String plan;
  final double planWeeklyTarget;
  final Timestamp? planStartDate;
  final int planDurationDays;
  final Timestamp? planEndDate;
  final double dailyCalorieTarget;
  final Timestamp? lastQuestResetTimestamp;

  UserModel({
    this.uid,
    required this.name,
    required this.email,
    required this.weight,
    required this.targetWeight,
    required this.height,
    required this.age,
    required this.gender,
    required this.bmi,
    required this.bmr,
    required this.activityFactor,
    required this.plan,
    required this.planWeeklyTarget,
    this.planStartDate,
    required this.planDurationDays,
    this.planEndDate,
    required this.dailyCalorieTarget,
    this.lastQuestResetTimestamp,
  });

  // Method สำหรับคำนวณ BMI แบบเรียลไทม์
  double calculateBMI() {
    if (height <= 0 || weight <= 0) {
      return 0.0;
    }
    double heightInM = height / 100; // แปลง cm เป็น m
    return weight / (heightInM * heightInM);
  }

  // Method สำหรับคำนวณ BMR แบบเรียลไทม์
  double calculateBMR() {
    if (weight <= 0 || height <= 0 || age <= 0) {
      return 0.0;
    }

    // สูตร Mifflin-St Jeor Equation
    if (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'ชาย') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Method สำหรับคำนวณ TDEE (Total Daily Energy Expenditure)
  double calculateTDEE() {
    return calculateBMR() * activityFactor;
  }

  // Method สำหรับแปลง UserModel เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toFirestore([SetOptions? options]) {
    return {
      'name': name,
      'email': email,
      'weight': weight,
      'targetWeight': targetWeight,
      'height': height,
      'age': age,
      'gender': gender,
      'bmi': bmi,
      'bmr': bmr,
      'activityFactor': activityFactor,
      'plan': plan,
      'planWeeklyTarget': planWeeklyTarget,
      'planStartDate': planStartDate,
      'planDurationDays': planDurationDays,
      'planEndDate': planEndDate,
      'dailyCalorieTarget': dailyCalorieTarget,
      'lastQuestResetTimestamp': lastQuestResetTimestamp,
    };
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for UserModel ID: ${snapshot.id}');
    }
    return UserModel(
      uid: snapshot.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
      targetWeight: (data['targetWeight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      age: (data['age'] ?? 0).toInt(),
      gender: data['gender'] ?? '',
      bmi: (data['bmi'] ?? 0.0).toDouble(),
      bmr: (data['bmr'] ?? 0.0).toDouble(),
      activityFactor: (data['activityFactor'] ?? 1.2).toDouble(),
      plan: data['plan'] ?? '',
      planWeeklyTarget: (data['planWeeklyTarget'] ?? 0.0).toDouble(),
      planStartDate: data['planStartDate'] as Timestamp?,
      planDurationDays: (data['planDurationDays'] ?? 0).toInt(),
      planEndDate: data['planEndDate'] as Timestamp?,
      dailyCalorieTarget: (data['dailyCalorieTarget'] ?? 0.0).toDouble(),
      lastQuestResetTimestamp: data['lastQuestResetTimestamp'] as Timestamp?,
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    double? weight,
    double? targetWeight,
    double? height,
    int? age,
    String? gender,
    double? bmi,
    double? bmr,
    double? activityFactor,
    String? plan,
    double? planWeeklyTarget,
    Timestamp? planStartDate,
    int? planDurationDays,
    Timestamp? planEndDate,
    double? dailyCalorieTarget,
    Timestamp? lastQuestResetTimestamp,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      activityFactor: activityFactor ?? this.activityFactor,
      plan: plan ?? this.plan,
      planWeeklyTarget: planWeeklyTarget ?? this.planWeeklyTarget,
      planStartDate: planStartDate ?? this.planStartDate,
      planDurationDays: planDurationDays ?? this.planDurationDays,
      planEndDate: planEndDate ?? this.planEndDate,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      lastQuestResetTimestamp:
          lastQuestResetTimestamp ?? this.lastQuestResetTimestamp,
    );
  }

  static Timestamp? calculatePlanEndDate(
    Timestamp? startDate,
    int? durationDays,
  ) {
    if (startDate != null && durationDays != null && durationDays > 0) {
      return Timestamp.fromDate(
        startDate.toDate().add(Duration(days: durationDays - 1)),
      );
    }
    return null;
  }
}
