import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_mate/models/food/food_entry_model.dart';
import 'package:health_mate/models/running_session_model.dart';
import 'package:intl/intl.dart';

import 'package:health_mate/models/daily_quest_model.dart';
import 'package:health_mate/models/user_model.dart';
import 'package:health_mate/services/firestore_service.dart';

class HomeProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();

  UserModel? _user;
  DailyQuestModel? _quest;
  bool _isLoading = true;

  UserModel? get user => _user;
  DailyQuestModel? get quest => _quest;
  bool get isLoading => _isLoading;

  HomeProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final user = await _firestoreService.getUser(uid);
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final quest = await _firestoreService.fetchOrCreateTodayQuest(
        uid,
        user.dailyCalorieTarget,
        user.weight,
      );

      _user = user;
      _quest = quest;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data in Provider: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWeight(String uid, double newWeight) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateWeight(uid, newWeight);
      final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dailyQuests')
          .doc(todayId)
          .update({'weight': newWeight});
      // โหลดข้อมูลใหม่ทั้งหมดเพื่อให้ UI อัปเดตสมบูรณ์
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating weight in Provider: $e');
      }
      // โหลดข้อมูลอีกครั้งแม้จะเกิด error เพื่อคืนสถานะเดิม
      await loadData();
    }
  }

  Future<void> logFood(FoodEntryModel entry) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      // ใช้ FirestoreService เพื่อบันทึกข้อมูลอาหารและอัปเดตแคลอรี่รวม
      await _firestoreService.logFoodEntry(uid, entry);
      await loadData(); // โหลดข้อมูลใหม่เพื่อให้หน้า Home อัปเดต
    } catch (e) {
      if (kDebugMode) print('Error logging food in Provider: $e');
      await loadData(); // โหลดข้อมูลใหม่แม้จะเกิดข้อผิดพลาด
    }
  }

  Future<void> deleteFoodLog(FoodEntryModel entryToDelete) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // ตรวจสอบให้แน่ใจว่า entry ที่จะลบมี ID
    if (entryToDelete.id == null) {
      if (kDebugMode) print('Cannot delete food log without an ID.');
      return;
    }

    try {
      // 1. เตรียมข้อมูล date string จาก timestamp ของ entry
      final dateString = DateFormat(
        'yyyy-MM-dd',
      ).format(entryToDelete.timestamp);

      // 2. เรียกใช้ Service ด้วย parameters ที่ถูกต้อง
      await _firestoreService.deleteFoodEntry(uid, dateString, entryToDelete);

      // 3. โหลดข้อมูลใหม่เพื่อให้ UI ทั้งหมดอัปเดต
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting food log in Provider: $e');
      }
      // สามารถแจ้งเตือนผู้ใช้ว่าลบไม่สำเร็จได้ที่นี่
    }
  }

  Future<void> logActivity(RunningSessionModel session) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      // ใช้ FirestoreService เพื่อบันทึกข้อมูลการวิ่งและอัปเดตแคลอรี่รวม
      await _firestoreService.logRunningSession(uid, session);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error logging activity in Provider: $e');
      await loadData();
    }
  }

  Future<void> addCalories(String uid, double calories) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.addCalories(uid, calories);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error adding calories in Provider: $e');
      await loadData();
    }
  }

  Future<void> burnCalories(String uid, double calories) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.burnCalories(uid, calories);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error burning calories in Provider: $e');
      await loadData();
    }
  }
}
