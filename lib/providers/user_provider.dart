import 'package:flutter/material.dart';
import 'package:health_mate/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  // Getter เพื่อให้ widgets ที่เรียกใช้สามารถเข้าถึงข้อมูล user ได้
  UserModel? get user => _user;

  // Setter เพื่ออัปเดต user และแจ้งให้ widget อื่นรู้ว่าข้อมูลเปลี่ยนแล้ว
  void setUser(UserModel newUser) {
    _user = newUser;
    notifyListeners(); // แจ้งให้ widget ที่ฟัง provider นี้ทำการ rebuild
  }

  // ใช้สำหรับ logout หรือเคลียร์ข้อมูลผู้ใช้
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
