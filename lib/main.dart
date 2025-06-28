import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// นำเข้าหน้าจอ
import 'package:health_mate/screens/login_screen.dart';
import 'package:health_mate/widgets/bottom_bar.dart';
// นำเข้า Provider และ Model
import 'package:health_mate/providers/user_provider.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:health_mate/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // รอให้ระบบพร้อม
  await Firebase.initializeApp(); // เริ่มต้น Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
      ],
      child: MaterialApp(
        title: 'Health Mate',
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(), // ตรวจสอบสถานะผู้ใช้
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (authSnapshot.hasData) {
          final uid = authSnapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get()
                .catchError((error) {
                  // จับ error ตรงนี้ด้วย เผื่อ permission denied
                  if (error is FirebaseException &&
                      error.code == 'permission-denied') {
                    // Return null เพื่อให้ไปทำ signOut
                    // ignore: invalid_return_type_for_catch_error
                    return null;
                  }
                  throw error; // Re-throw error อื่นๆ
                }),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // ตรวจสอบ error หรือ ไม่มีข้อมูล หรือ data เป็น null (จาก catchError)
              if (userDocSnapshot.hasError ||
                  !userDocSnapshot.hasData ||
                  userDocSnapshot.data == null ||
                  !userDocSnapshot.data!.exists) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (context.mounted) {
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).clearUser();

                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error during signOut: $e');
                      }
                    }

                    if (context.mounted) {
                      // แสดงข้อความแจ้งเตือน
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ข้อมูลผู้ใช้ไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่',
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                });

                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("กำลังตรวจสอบข้อมูล..."),
                      ],
                    ),
                  ),
                );
              }

              // แปลงข้อมูลเป็น UserModel
              final data = userDocSnapshot.data!.data();
              if (data is Map<String, dynamic>) {
                final userModel = UserModel.fromFirestore(
                  userDocSnapshot.data!
                      as DocumentSnapshot<Map<String, dynamic>>,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).setUser(userModel);
                  }
                });

                return const BottomBar();
              } else {
                // กรณี data structure ไม่ถูกต้อง
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (context.mounted) {
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).clearUser();
                    await FirebaseAuth.instance.signOut();
                  }
                });

                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("กำลังตรวจสอบข้อมูล..."),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        } else {
          // ไม่มี user login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Provider.of<UserProvider>(context, listen: false).clearUser();
            }
          });
          return LoginScreen();
        }
      },
    );
  }
}
