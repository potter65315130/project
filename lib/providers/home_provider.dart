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
  String? _currentUserId; // เก็บ ID ของ user ปัจจุบัน

  UserModel? get user => _user;
  DailyQuestModel? get quest => _quest;
  bool get isLoading => _isLoading;

  HomeProvider() {
    loadData();
    // ฟัง auth state changes
    _auth.authStateChanges().listen((User? user) {
      final newUserId = user?.uid;
      if (_currentUserId != newUserId) {
        _currentUserId = newUserId;
        _clearData(); // ล้างข้อมูลเก่า
        loadData(); // โหลดข้อมูลใหม่
      }
    });
  }

  // ฟังก์ชันล้างข้อมูล
  void _clearData() {
    _user = null;
    _quest = null;
    _isLoading = true;
    notifyListeners();
  }

  // เพิ่มฟังก์ชันสำหรับ refresh ข้อมูลจากภายนอก
  Future<void> refreshData() async {
    _clearData();
    await loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _clearData();
      _isLoading = false;
      notifyListeners();
      return;
    }

    // ตรวจสอบว่า user เปลี่ยนแล้วหรือไม่
    if (_currentUserId != uid) {
      _currentUserId = uid;
      _clearData();
      _isLoading = true;
      notifyListeners();
    }

    try {
      final user = await _firestoreService.getUser(uid);
      if (user == null) {
        _clearData();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ตรวจสอบให้แน่ใจว่ามีการสร้าง quest ด้วยข้อมูลล่าสุด
      final quest = await _firestoreService.fetchOrCreateTodayQuest(
        uid,
        user.dailyCalorieTarget,
        user.weight,
      );

      // ถ้า quest ไม่มีข้อมูล หรือข้อมูลไม่ตรงกับ user ให้อัปเดต
      if ((quest.weight != user.weight ||
          quest.calorieTarget != user.dailyCalorieTarget)) {
        try {
          final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dailyQuests')
              .doc(todayId)
              .update({
                'weight': user.weight,
                'calorieTarget': user.dailyCalorieTarget,
              });
          // โหลด quest ใหม่หลังจาก update
          final updatedQuest = await _firestoreService.fetchOrCreateTodayQuest(
            uid,
            user.dailyCalorieTarget,
            user.weight,
          );
          _quest = updatedQuest;
        } catch (e) {
          if (kDebugMode) print('Error updating quest data: $e');
          _quest = quest;
        }
      } else {
        _quest = quest;
      }

      _user = user;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data in Provider: $e');
      }
      // ในกรณีเกิด error ให้ล้างข้อมูลด้วย
      _clearData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWeight(String uid, double newWeight) async {
    // ตรวจสอบว่า uid ตรงกับ current user หรือไม่
    if (_auth.currentUser?.uid != uid) {
      if (kDebugMode) print('UID mismatch in updateWeight');
      return;
    }

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
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating weight in Provider: $e');
      }
      await loadData();
    }
  }

  Future<void> logFood(FoodEntryModel entry) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != _currentUserId) return;

    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.logFoodEntry(uid, entry);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error logging food in Provider: $e');
      await loadData();
    }
  }

  Future<void> deleteFoodLog(FoodEntryModel entryToDelete) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != _currentUserId) return;

    if (entryToDelete.id == null) {
      if (kDebugMode) print('Cannot delete food log without an ID.');
      return;
    }

    try {
      final dateString = DateFormat(
        'yyyy-MM-dd',
      ).format(entryToDelete.timestamp);

      await _firestoreService.deleteFoodEntry(uid, dateString, entryToDelete);
      await loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting food log in Provider: $e');
      }
    }
  }

  Future<void> logActivity(RunningSessionModel session) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != _currentUserId) return;

    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.logRunningSession(uid, session);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error logging activity in Provider: $e');
      await loadData();
    }
  }

  Future<void> addCalories(String uid, double calories) async {
    if (_auth.currentUser?.uid != uid || uid != _currentUserId) return;

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
    if (_auth.currentUser?.uid != uid || uid != _currentUserId) return;

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

  @override
  void dispose() {
    // ล้างข้อมูลเมื่อ dispose
    _clearData();
    super.dispose();
  }
}
