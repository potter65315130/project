import 'package:flutter/material.dart';
import 'package:health_mate/models/food_entry_model.dart';
import 'package:health_mate/models/food_item_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:provider/provider.dart';

// ฟังก์ชันสำหรับแสดง Dialog บันทึกอาหาร
Future<void> showFoodLogDialog({
  required BuildContext context,
  required FoodItem item,
}) {
  final TextEditingController quantityController = TextEditingController(
    text: '1.0',
  );
  final ValueNotifier<double> quantityNotifier = ValueNotifier<double>(1.0);

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return ValueListenableBuilder<double>(
        valueListenable: quantityNotifier,
        builder: (context, quantity, child) {
          final calculatedCalories = item.calories * quantity;
          final calculatedProtein = item.protein * quantity;
          final calculatedCarbs = item.carbs * quantity;
          final calculatedFat = item.fat * quantity;

          return AlertDialog(
            title: Text(item.name),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'จำนวน (เช่น 1, 1.5)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      quantityNotifier.value = double.tryParse(value) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ข้อมูลโภชนาการ (โดยประมาณ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'แคลอรี่: ${calculatedCalories.toStringAsFixed(2)} kcal',
                  ),
                  Text('โปรตีน: ${calculatedProtein.toStringAsFixed(2)} g'),
                  Text('คาร์โบไฮเดรต: ${calculatedCarbs.toStringAsFixed(2)} g'),
                  Text('ไขมัน: ${calculatedFat.toStringAsFixed(2)} g'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('ยกเลิก'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  quantityNotifier.dispose();
                },
              ),
              ElevatedButton(
                child: const Text('บันทึก'),
                onPressed:
                    quantity <= 0
                        ? null
                        : () {
                          final entry = FoodEntryModel(
                            name: item.name,
                            calories: calculatedCalories,
                            protein: calculatedProtein,
                            carbs: calculatedCarbs,
                            fat: calculatedFat,
                            timestamp: DateTime.now(),
                          );

                          // เรียก Provider เพื่อบันทึกข้อมูล
                          context.read<HomeProvider>().logFood(entry).then((_) {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('บันทึกข้อมูลเรียบร้อย!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            quantityNotifier.dispose();
                          });
                        },
              ),
            ],
          );
        },
      );
    },
  );
}
