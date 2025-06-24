import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:health_mate/models/food_entry_model.dart';
import 'package:health_mate/models/food_item_model.dart';
import 'package:health_mate/models/running_session_model.dart';
import 'package:intl/intl.dart';

import 'package:health_mate/models/user_model.dart';
import 'package:health_mate/models/daily_quest_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -------------------- ผู้ใช้ --------------------
  Future<void> createUser(String userId, UserModel user) async {
    await _firestore.collection('users').doc(userId).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> updateWeight(String uid, double newWeight) async {
    await _firestore.collection('users').doc(uid).update({'weight': newWeight});
  }

  double calculateWeightProgress(double current, double target) {
    if (current == target) return 100.0;
    final totalDiff = (current - target).abs();
    final lost = (current > target) ? (current - target) : 0;
    return (lost / totalDiff) * 100;
  }

  /// -------------------- เควสรายวัน --------------------

  Future<DailyQuestModel> fetchOrCreateTodayQuest(
    String uid,
    double calorieTarget,
    double currentWeight,
  ) async {
    // 1. ตรวจสอบและสร้างเควสย้อนหลังสำหรับวันที่ขาดหายไปก่อนเสมอ
    await fillMissingQuests(uid);

    // 2. ดำเนินการสร้างหรือดึงข้อมูลเควสของวันนี้ตามปกติ
    final today = DateTime.now();
    final todayId = DateFormat('yyyy-MM-dd').format(today);
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyQuests')
        .doc(todayId);

    final doc = await docRef.get();

    if (doc.exists) {
      if (kDebugMode) {
        print('[FirestoreService] พบเควสของวันนี้แล้ว ($todayId)');
      }
      return DailyQuestModel.fromFirestore(doc);
    } else {
      if (kDebugMode) {
        print(
          '[FirestoreService] ไม่พบเควสของวันนี้, กำลังสร้างใหม่สำหรับ $todayId...',
        );
      }
      final newQuest = DailyQuestModel(
        id: todayId,
        date: DateTime(today.year, today.month, today.day),
        calorieTarget: calorieTarget,
        calorieIntake: 0,
        calorieBurned: 0,
        weight: currentWeight,
      );
      await docRef.set(newQuest.toFirestore());
      if (kDebugMode) {
        print('[FirestoreService] สร้างเควสสำหรับวันนี้สำเร็จ');
      }
      return newQuest;
    }
  }

  int calculateDaysLeft(UserModel user) {
    final start = user.planStartDate?.toDate();
    if (start == null) return 0;

    final today = DateTime.now();
    final end = start.add(Duration(days: user.planDurationDays));
    final daysLeft = end.difference(today).inDays;
    return daysLeft > 0 ? daysLeft : 0;
  }

  /// -------------------- เควสย้อนหลังสำหรับวันที่ไม่ได้ใช้งาน  --------------------

  Future<void> fillMissingQuests(String uid) async {
    if (kDebugMode) {
      print(
        '[fillMissingQuests] เริ่มต้นกระบวนการตรวจสอบและสร้างเควสย้อนหลัง...',
      );
    }
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final user = await getUser(uid);
      if (user == null) {
        if (kDebugMode) {
          print(
            '[fillMissingQuests] ไม่พบข้อมูลผู้ใช้ UID: $uid, สิ้นสุดการทำงาน',
          );
        }
        return;
      }

      final questCollection = _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyQuests');

      final lastQuestSnapshot =
          await questCollection
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (lastQuestSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print(
            '[fillMissingQuests] ไม่พบเควสใดๆ ในระบบเลย จะสร้างเควสแรกให้เป็นของวันนี้',
          );
        }
        return;
      }

      final lastQuest = DailyQuestModel.fromFirestore(
        lastQuestSnapshot.docs.first,
      );
      final lastQuestDate = DateTime(
        lastQuest.date.year,
        lastQuest.date.month,
        lastQuest.date.day,
      );

      final differenceInDays = today.difference(lastQuestDate).inDays;

      if (kDebugMode) {
        print(
          '[fillMissingQuests] วันที่เควสล่าสุด: ${DateFormat('yyyy-MM-dd').format(lastQuestDate)}',
        );
        print(
          '[fillMissingQuests] วันที่ปัจจุบัน: ${DateFormat('yyyy-MM-dd').format(today)}',
        );
        print('[fillMissingQuests] จำนวนวันที่ห่างกัน: $differenceInDays วัน');
      }

      if (differenceInDays < 2) {
        if (kDebugMode) {
          print(
            '[fillMissingQuests] ไม่มีความจำเป็นต้องสร้างเควสย้อนหลัง (ห่างกันน้อยกว่า 2 วัน)',
          );
        }
        return;
      }

      if (kDebugMode) {
        print(
          '[fillMissingQuests] พบว่ามีวันที่ต้องสร้างเควสย้อนหลัง กำลังเริ่มสร้าง...',
        );
      }

      final batch = _firestore.batch();
      int questsCreated = 0;

      for (int i = 1; i < differenceInDays; i++) {
        final missingDate = lastQuestDate.add(Duration(days: i));
        final questId = DateFormat('yyyy-MM-dd').format(missingDate);
        final newQuest = DailyQuestModel(
          id: questId,
          date: missingDate,
          calorieTarget: lastQuest.calorieTarget,
          weight: lastQuest.weight,
          calorieIntake: 0,
          calorieBurned: 0,
        );

        final docRef = questCollection.doc(questId);
        batch.set(docRef, newQuest.toFirestore());
        questsCreated++;
        if (kDebugMode) {
          print(
            '[fillMissingQuests]   -> เตรียมสร้างเควสสำหรับวันที่: $questId',
          );
        }
      }

      if (questsCreated > 0) {
        await batch.commit();
        if (kDebugMode) {
          print(
            '[fillMissingQuests] สร้างเควสย้อนหลังสำเร็จ จำนวน $questsCreated เควส',
          );
        }
      } else {
        if (kDebugMode) {
          print('[fillMissingQuests] ไม่มีเควสใหม่ที่ต้องสร้าง');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(' เกิดข้อผิดพลาดใน fillMissingQuests ');
        print('Error: $e');
        print(
          'สาเหตุที่เป็นไปได้มากที่สุดคือคุณยังไม่ได้สร้าง Index ใน Firestore',
        );
      }
    }
  }

  /// -------------------- เพิ่ม/ลบแคลอรี่ --------------------

  Future<void> addCalories(String uid, double calories) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyQuests')
        .doc(todayId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({'calorieIntake': FieldValue.increment(calories)});
    }
  }

  Future<void> burnCalories(String uid, double burned) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyQuests')
        .doc(todayId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({'calorieBurned': FieldValue.increment(burned)});
    }
  }

  /// -------------------- ดึงข้อมูลย้อนหลัง --------------------

  Future<List<DailyQuestModel>> getQuestHistory(String uid) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyQuests')
            .orderBy('date')
            .get();

    return snapshot.docs
        .map((doc) => DailyQuestModel.fromFirestore(doc))
        .toList();
  }

  /// -------------------- บันทึกอาหาร (FoodEntry) --------------------

  Future<void> logFoodEntry(String uid, FoodEntryModel entry) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final foodRef =
        _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyQuests')
            .doc(todayId)
            .collection('foodEntries')
            .doc(); // Auto ID

    await _firestore.runTransaction((transaction) async {
      final questDocRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyQuests')
          .doc(todayId);

      transaction.set(foodRef, entry.toFirestore());
      transaction.update(questDocRef, {
        'calorieIntake': FieldValue.increment(entry.calories),
      });
    });
  }

  // --- Stream สำหรับรายการอาหารของวันนี้ ---
  Stream<List<FoodEntryModel>> getFoodEntriesStream(String uid, String date) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyQuests')
        .doc(date)
        .collection('foodEntries')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FoodEntryModel.fromFirestore(doc))
                  .toList(),
        );
  }

  /// -------------------- บันทึกการวิ่ง (RunningSession) --------------------

  Future<void> logRunningSession(
    String uid,
    RunningSessionModel session,
  ) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final runRef =
        _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyQuests')
            .doc(todayId)
            .collection('runningSessions')
            .doc(); // Auto ID

    await runRef.set(session.toFirestore());
    await burnCalories(uid, session.caloriesBurned); // อัปเดตแคลอรี่ด้วย
  }

  /// -------------------- ดึงข้อมูลการกินและวิ่งย้อนหลัง --------------------

  Future<List<FoodEntryModel>> getFoodEntries(String uid, String date) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyQuests')
            .doc(date)
            .collection('foodEntries')
            .orderBy('timestamp', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => FoodEntryModel.fromFirestore(doc))
        .toList();
  }

  // ... โค้ดส่วนที่เหลือ ...
  Future<List<RunningSessionModel>> getRunningSessions(
    String uid,
    String date,
  ) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyQuests')
            .doc(date)
            .collection('runningSessions')
            .get();

    return snapshot.docs
        .map((doc) => RunningSessionModel.fromFirestore(doc))
        .toList();
  }

  Future<List<DailyQuestModel>> getLast30DaysQuests(String uid) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));
    return getQuestHistoryForDateRange(uid, startDate, endDate);
  }

  Future<List<DailyQuestModel>> getQuestHistoryForDateRange(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyQuests')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .orderBy('date', descending: true)
            .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map((doc) => DailyQuestModel.fromFirestore(doc))
        .toList();
  }

  // --- ฟังก์ชันสำหรับจัดการรายการโปรด ---
  CollectionReference _favoritesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('favoriteFoods');
  }

  Future<void> addFavorite(String uid, FoodItem item) async {
    await _favoritesCollection(uid).doc(item.name).set(item.toJson());
  }

  Future<void> removeFavorite(String uid, FoodItem item) async {
    await _favoritesCollection(uid).doc(item.name).delete();
  }

  Stream<List<FoodItem>> getFavoritesStream(String uid) {
    return _favoritesCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();
    });
  }
}
