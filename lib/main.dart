import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_mate/providers/exercise_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
// นำเข้าหน้าจอ
import 'package:health_mate/screens/login_screen.dart';
import 'package:health_mate/widgets/bottom_bar.dart';
// นำเข้า Provider และ Model
import 'package:health_mate/providers/user_provider.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:health_mate/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('th', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => ExerciseProvider()),
      ],
      child: MaterialApp(
        title: 'Health Mate',
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
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
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF8BC34A)),
            ),
          );
        } else if (authSnapshot.hasData) {
          final uid = authSnapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get()
                .catchError((error) {
                  if (error is FirebaseException &&
                      error.code == 'permission-denied') {
                    // ignore: invalid_return_type_for_catch_error
                    return null;
                  }
                  throw error;
                }),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF1A1A1A),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF8BC34A)),
                  ),
                );
              }

              if (userDocSnapshot.hasError ||
                  !userDocSnapshot.hasData ||
                  userDocSnapshot.data == null ||
                  !userDocSnapshot.data!.exists) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (context.mounted) {
                    // ล้างข้อมูลใน UserProvider
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).clearUser();

                    // ล้างข้อมูลใน HomeProvider
                    Provider.of<HomeProvider>(
                      context,
                      listen: false,
                    ).refreshData();

                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error during signOut: $e');
                      }
                    }

                    if (context.mounted) {
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
                  backgroundColor: Color(0xFF1A1A1A),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF8BC34A)),
                        SizedBox(height: 16),
                        Text(
                          "กำลังตรวจสอบข้อมูล...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = userDocSnapshot.data!.data();
              if (data is Map<String, dynamic>) {
                final userModel = UserModel.fromFirestore(
                  userDocSnapshot.data!
                      as DocumentSnapshot<Map<String, dynamic>>,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    final userProvider = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );

                    // ตรวจสอบว่าเป็น user คนเดิมหรือไม่
                    if (userProvider.user?.uid != userModel.uid) {
                      // เป็น user ใหม่ ให้ล้างข้อมูลเก่าก่อน
                      userProvider.clearUser();
                      Provider.of<HomeProvider>(
                        context,
                        listen: false,
                      ).refreshData();
                    }

                    userProvider.setUser(userModel);
                  }
                });

                return const BottomBar();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (context.mounted) {
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).clearUser();

                    Provider.of<HomeProvider>(
                      context,
                      listen: false,
                    ).refreshData();

                    await FirebaseAuth.instance.signOut();
                  }
                });

                return const Scaffold(
                  backgroundColor: Color(0xFF1A1A1A),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF8BC34A)),
                        SizedBox(height: 16),
                        Text(
                          "กำลังตรวจสอบข้อมูล...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        } else {
          // ไม่มี user login - ล้างข้อมูลทั้งหมด
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Provider.of<UserProvider>(context, listen: false).clearUser();
              Provider.of<HomeProvider>(context, listen: false).refreshData();
            }
          });
          return LoginScreen();
        }
      },
    );
  }
}
