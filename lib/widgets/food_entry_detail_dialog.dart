import 'package:flutter/material.dart';
import 'package:health_mate/models/food/food_entry_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const Color _darkElementColor = Color(0xFF1E1E1E);
const Color _lightTextColor = Colors.white;
const Color _mediumTextColor = Color(0xFFB0B0B0);

// Dialog สำหรับแสดงรายละเอียดและลบรายการอาหารที่บันทึกไว้
Future<void> showFoodEntryDetailDialog({
  required BuildContext context,
  required FoodEntryModel entry,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: _darkElementColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(entry.name, style: const TextStyle(color: _lightTextColor)),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'บันทึกเมื่อ: ${DateFormat.yMd().add_Hm().format(entry.timestamp)}',
                style: const TextStyle(color: _mediumTextColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'ข้อมูลโภชนาการ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _lightTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'แคลอรี่: ${entry.calories.toStringAsFixed(2)} kcal',
                style: const TextStyle(color: _mediumTextColor),
              ),
              Text(
                'โปรตีน: ${entry.protein.toStringAsFixed(2)} g',
                style: const TextStyle(color: _mediumTextColor),
              ),
              Text(
                'คาร์โบไฮเดรต: ${entry.carbs.toStringAsFixed(2)} g',
                style: const TextStyle(color: _mediumTextColor),
              ),
              Text(
                'ไขมัน: ${entry.fat.toStringAsFixed(2)} g',
                style: const TextStyle(color: _mediumTextColor),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('ปิด', style: TextStyle(color: _lightTextColor)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'ลบรายการ',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              if (entry.id != null) {
                context.read<HomeProvider>().deleteFoodLog(entry);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('ลบรายการแล้ว'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(10),
                  ),
                );
              }
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}
