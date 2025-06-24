import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String buttontext;
  final Color? color;
  final double borderRadius;

  const LoginButton({
    super.key,
    required this.onTap,
    required this.buttontext,
    this.color = const Color.fromARGB(255, 3, 228, 119),
    this.borderRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = buttontext.contains("กำลังเข้าสู่ระบบ");

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onTap,
      child:
          isLoading
              ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
              : Text(
                buttontext,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
    );
  }
}
