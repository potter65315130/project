import 'package:flutter/material.dart';
import 'package:health_mate/screens/onboarding_flow_screen.dart';
import 'package:health_mate/screens/login_screen.dart'; // จำเป็นสำหรับปุ่ม "กลับ"
import 'package:health_mate/widgets/login_button.dart'; // สมมติว่า widget นี้มีอยู่
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:health_mate/models/user_model.dart'; // ตรวจสอบว่านำเข้า UserModel ที่ถูกต้อง

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;

  // ฟังก์ชันตรวจสอบความถูกต้องของอีเมล
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("รูปแบบอีเมลไม่ถูกต้อง")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        email,
      );
      if (methods.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("อีเมลนี้ถูกใช้งานไปแล้ว")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // สร้าง UserModel ด้วยข้อมูลพื้นฐาน (OnboardingFlowScreen จะกรอกส่วนที่เหลือ)
      final newUser = UserModel(
        uid: uid, // กำหนด uid ที่ได้จากการสมัคร
        name: '', // จะกรอกใน OnboardingFlow
        email: email,
        weight: 0.0, // จะกรอกใน OnboardingFlow
        targetWeight: 0.0, // จะกรอกใน OnboardingFlow
        height: 0.0, // จะกรอกใน OnboardingFlow
        age: 0, // จะกรอกใน OnboardingFlow
        gender: '', // จะกรอกใน OnboardingFlow
        bmi: 0.0, // จะคำนวณใน OnboardingFlow
        bmr: 0.0, // จะคำนวณใน OnboardingFlow
        activityFactor: 1.2, // จะเลือกใน OnboardingFlow
        plan: '', // จะกำหนดใน OnboardingFlow
        planWeeklyTarget: 0.0, // จะกำหนดใน OnboardingFlow
        planStartDate: null, // จะกำหนดใน OnboardingFlow
        planDurationDays: 0, // จะกำหนดใน OnboardingFlow
        dailyCalorieTarget: 0.0, // จะคำนวณใน OnboardingFlow
      );

      // ใช้ FirestoreService สร้างข้อมูลผู้ใช้พื้นฐาน
      await FirestoreService().createUser(uid, newUser);

      if (!mounted) return;
      // นำทางไปยังหน้า OnboardingFlowScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingFlowScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "เกิดข้อผิดพลาดในการลงทะเบียน";
      if (e.code == 'weak-password') {
        errorMessage =
            'รหัสผ่านไม่ปลอดภัย กรุณาตั้งรหัสผ่านที่คาดเดายากกว่านี้';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'อีเมลนี้ถูกใช้งานไปแล้ว';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ: ${e.toString()}"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
            child: Column(
              children: [
                // ตรวจสอบว่า path ถูกต้องและมีไฟล์ใน assets
                Image.asset(
                  "assets/login01.png",
                  width: 200,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const Text(
                  "สมัครสมาชิก",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _emailController,
                  cursorColor: Colors.green,
                  style: const TextStyle(color: Colors.green),
                  decoration: InputDecoration(
                    labelText: "อีเมล",
                    labelStyle: const TextStyle(color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordHidden,
                  cursorColor: Colors.green,
                  style: const TextStyle(color: Colors.green),
                  decoration: InputDecoration(
                    labelText: "รหัสผ่าน",
                    labelStyle: const TextStyle(color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.green,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordHidden,
                  cursorColor: Colors.green,
                  style: const TextStyle(color: Colors.green),
                  decoration: InputDecoration(
                    labelText: "ยืนยันรหัสผ่าน",
                    labelStyle: const TextStyle(color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                        });
                      },
                      icon: Icon(
                        _isConfirmPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.green,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: LoginButton(
                      onTap: _signUp,
                      buttontext: "ลงทะเบียน",
                      borderRadius: 25.0,
                      color: const Color.fromARGB(255, 96, 154, 254),
                    ),
                  ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: LoginButton(
                    onTap: () {
                      if (_isLoading) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    buttontext: "กลับไปหน้าเข้าสู่ระบบ",
                    borderRadius: 25.0,
                    color: const Color.fromARGB(255, 254, 110, 110),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
