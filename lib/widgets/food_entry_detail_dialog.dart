import 'package:flutter/material.dart';
import 'package:health_mate/models/food_entry_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Dialog สำหรับแสดงรายละเอียดและลบรายการอาหารที่บันทึกไว้
Future<void> showFoodEntryDetailDialog({
  required BuildContext context,
  required FoodEntryModel entry,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(entry.name),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'บันทึกเมื่อ: ${DateFormat.yMd().add_Hm().format(entry.timestamp)}',
              ),
              const SizedBox(height: 16),
              const Text(
                'ข้อมูลโภชนาการ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('แคลอรี่: ${entry.calories.toStringAsFixed(2)} kcal'),
              Text('โปรตีน: ${entry.protein.toStringAsFixed(2)} g'),
              Text('คาร์โบไฮเดรต: ${entry.carbs.toStringAsFixed(2)} g'),
              Text('ไขมัน: ${entry.fat.toStringAsFixed(2)} g'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('ปิด'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ลบรายการ',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              // Note: ต้องมีเมธอด deleteFoodLog
              // และ entry.id ต้องมีค่า (มาจาก Firestore Document ID)
              if (entry.id != null) {
                context.read<HomeProvider>().deleteFoodLog(entry);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบรายการแล้ว'),
                    backgroundColor: Colors.red,
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
