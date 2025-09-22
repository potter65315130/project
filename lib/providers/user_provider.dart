import 'package:flutter/material.dart';
import 'package:health_mate/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // ฟังก์ชันตรวจสอบว่าเป็น user คนเดิมหรือไม่
  bool isSameUser(String? uid) {
    return _user?.uid == uid;
  }
}
