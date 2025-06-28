import 'package:flutter/material.dart';
import 'package:health_mate/screens/signup_screen.dart';
import 'package:health_mate/widgets/bottom_bar.dart';
import 'package:health_mate/widgets/login_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
            child: Column(
              children: [
                Image.asset(
                  "assets/app1.png",
                  width: 200,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const Text(
                  "Health Mate",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
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
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: LoginButton(
                    onTap:
                        _isLoading
                            ? null
                            : () async {
                              String email = emailController.text.trim();
                              String password = passwordController.text;

                              if (email.isEmpty || password.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("ข้อมูลไม่ครบ"),
                                        content: const Text(
                                          "กรุณากรอกอีเมลและรหัสผ่าน",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text("ตกลง"),
                                          ),
                                        ],
                                      ),
                                );
                                return;
                              }

                              if (!isValidEmail(email)) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("อีเมลไม่ถูกต้อง"),
                                        content: const Text(
                                          "กรุณากรอกอีเมลให้ถูกต้อง เช่น name@email.com",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text("ตกลง"),
                                          ),
                                        ],
                                      ),
                                );
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                      email: email,
                                      password: password,
                                    );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BottomBar(),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                String message = "";
                                if (e.code == 'user-not-found') {
                                  message = "ไม่พบผู้ใช้งานนี้";
                                } else if (e.code == 'wrong-password') {
                                  message = "รหัสผ่านไม่ถูกต้อง";
                                } else {
                                  message = "เกิดข้อผิดพลาด: ${e.message}";
                                }

                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text(
                                          "เข้าสู่ระบบไม่สำเร็จ",
                                        ),
                                        content: Text(message),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text("ตกลง"),
                                          ),
                                        ],
                                      ),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            },
                    buttontext:
                        _isLoading ? "กำลังเข้าสู่ระบบ..." : "เข้าสู่ระบบ",
                    borderRadius: 25.0,
                  ),
                ),
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "หรือ",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: LoginButton(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        buttontext: "สร้างบัญชีผู้ใช้ใหม่",
                        borderRadius: 25.0,
                        color: const Color.fromARGB(255, 254, 110, 110),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
