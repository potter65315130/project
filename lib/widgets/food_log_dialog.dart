import 'package:flutter/material.dart';
import 'package:health_mate/models/food/food_entry_model.dart';
import 'package:health_mate/models/food/food_item_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:provider/provider.dart';

// --- UI THEME CONSTANTS ---
const Color _darkElementColor = Color(0xFF1E1E1E);
const Color _accentColor = Color(0xFFB4F82B);
const Color _lightTextColor = Colors.white;
const Color _mediumTextColor = Color(0xFFB0B0B0);
// --- END UI THEME CONSTANTS ---

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
            backgroundColor: _darkElementColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Text(
              item.name,
              style: const TextStyle(color: _lightTextColor),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: _lightTextColor),
                    decoration: InputDecoration(
                      labelText: 'จำนวน (เช่น 1, 1.5)',
                      labelStyle: const TextStyle(color: _mediumTextColor),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: _mediumTextColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: _accentColor),
                      ),
                    ),
                    onChanged: (value) {
                      quantityNotifier.value = double.tryParse(value) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ข้อมูลโภชนาการ (โดยประมาณ)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _lightTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'แคลอรี่: ${calculatedCalories.toStringAsFixed(2)} kcal',
                    style: const TextStyle(color: _mediumTextColor),
                  ),
                  Text(
                    'โปรตีน: ${calculatedProtein.toStringAsFixed(2)} g',
                    style: const TextStyle(color: _mediumTextColor),
                  ),
                  Text(
                    'คาร์โบไฮเดรต: ${calculatedCarbs.toStringAsFixed(2)} g',
                    style: const TextStyle(color: _mediumTextColor),
                  ),
                  Text(
                    'ไขมัน: ${calculatedFat.toStringAsFixed(2)} g',
                    style: const TextStyle(color: _mediumTextColor),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: _lightTextColor),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  quantityNotifier.dispose();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
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
                              SnackBar(
                                content: const Text('บันทึกข้อมูลเรียบร้อย!'),
                                backgroundColor: _accentColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(10),
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
