import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_mate/models/food/food_entry_model.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

const Color _darkBgColor = Color(0xFF1A1A1A);
const Color _darkElementColor = Color(0xFF2A2A2A);
const Color _accentColor = Color(0xFFB4F82B);
const Color _lightTextColor = Colors.white;
const Color _mediumTextColor = Color(0xFFB0B0B0);

class FoodLogHistoryScreen extends StatefulWidget {
  const FoodLogHistoryScreen({super.key});

  @override
  State<FoodLogHistoryScreen> createState() => _FoodLogHistoryScreenState();
}

class _FoodLogHistoryScreenState extends State<FoodLogHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late DateTime _selectedDate;
  late Future<List<FoodEntryModel>> _foodEntriesFuture;
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeLocaleAndLoadData();
  }

  Future<void> _initializeLocaleAndLoadData() async {
    await initializeDateFormatting('th', null);
    setState(() {
      _isLocaleInitialized = true;
    });
    _loadEntriesForSelectedDate();
  }

  void _loadEntriesForSelectedDate() {
    if (_uid != null) {
      setState(() {
        final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
        _foodEntriesFuture = _firestoreService.getFoodEntries(_uid, dateString);
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentColor,
              onPrimary: _darkBgColor,
              surface: _darkElementColor,
              onSurface: _lightTextColor,
              background: _darkBgColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadEntriesForSelectedDate();
      });
    }
  }

  Map<String, double> _calculateTotalNutrition(List<FoodEntryModel> entries) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var entry in entries) {
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Map<String, List<FoodEntryModel>> _groupEntriesByMeal(
    List<FoodEntryModel> entries,
  ) {
    Map<String, List<FoodEntryModel>> grouped = {
      'เช้า': [],
      'กลางวัน': [],
      'เย็น': [],
      'ว่าง': [],
    };

    for (var entry in entries) {
      final hour = entry.timestamp.hour;
      if (hour >= 5 && hour < 11) {
        grouped['เช้า']!.add(entry);
      } else if (hour >= 11 && hour < 16) {
        grouped['กลางวัน']!.add(entry);
      } else if (hour >= 16 && hour < 21) {
        grouped['เย็น']!.add(entry);
      } else {
        grouped['ว่าง']!.add(entry);
      }
    }

    return grouped;
  }

  Widget _buildNutritionSummaryCard(Map<String, double> nutrition) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _darkElementColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: _accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'สรุปโภชนาการประจำวัน',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _lightTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNutritionItem(
                  'แคลอรี่',
                  nutrition['calories']!.toStringAsFixed(0),
                  'kcal',
                  Icons.local_fire_department_outlined,
                ),
                _buildNutritionItem(
                  'โปรตีน',
                  nutrition['protein']!.toStringAsFixed(1),
                  'g',
                  Icons.fitness_center_outlined,
                ),
                _buildNutritionItem(
                  'คาร์บ',
                  nutrition['carbs']!.toStringAsFixed(1),
                  'g',
                  Icons.grain_outlined,
                ),
                _buildNutritionItem(
                  'ไขมัน',
                  nutrition['fat']!.toStringAsFixed(1),
                  'g',
                  Icons.opacity_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionItem(
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accentColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: _mediumTextColor, fontSize: 11),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _lightTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(color: _mediumTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealName, List<FoodEntryModel> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final mealTotals = _calculateTotalNutrition(entries);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _darkElementColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getMealIcon(mealName),
                        color: _accentColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'มื้อ$mealName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _lightTextColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${mealTotals['calories']!.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
          ...entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final isLast = index == entries.length - 1;
            return _buildFoodEntryTile(entry, isLast);
          }),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealName) {
    switch (mealName) {
      case 'เช้า':
        return Icons.wb_sunny_outlined;
      case 'กลางวัน':
        return Icons.wb_sunny;
      case 'เย็น':
        return Icons.nights_stay_outlined;
      case 'ว่าง':
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  Widget _buildFoodEntryTile(FoodEntryModel entry, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border:
            !isLast
                ? const Border(
                  bottom: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                )
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: _accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _lightTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'P:${entry.protein.toStringAsFixed(1)} C:${entry.carbs.toStringAsFixed(1)} F:${entry.fat.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11, color: _mediumTextColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _lightTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('HH:mm').format(entry.timestamp),
                style: const TextStyle(fontSize: 12, color: _mediumTextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBgColor,
      appBar: AppBar(
        title: const Text(
          'บันทึกย้อนหลัง',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _lightTextColor,
            fontSize: 17,
          ),
        ),
        backgroundColor: _darkBgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _lightTextColor),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: _accentColor,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          !_isLocaleInitialized
              ? const Center(
                child: CircularProgressIndicator(
                  color: _accentColor,
                  strokeWidth: 2,
                ),
              )
              : Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: _darkBgColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('d MMMM yyyy', 'th').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _lightTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedDate.day == DateTime.now().day &&
                                  _selectedDate.month == DateTime.now().month &&
                                  _selectedDate.year == DateTime.now().year
                              ? 'วันนี้'
                              : DateFormat('EEEE', 'th').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<FoodEntryModel>>(
                      future: _foodEntriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: _accentColor,
                              strokeWidth: 2,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 56,
                                  color: Colors.white38,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'เกิดข้อผิดพลาด',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white60,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.restaurant_menu_outlined,
                                  size: 56,
                                  color: Colors.white38,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'ไม่พบรายการอาหาร',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'ยังไม่มีการบันทึกอาหารในวันที่เลือก',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final entries = snapshot.data!;
                        final totalNutrition = _calculateTotalNutrition(
                          entries,
                        );
                        final groupedEntries = _groupEntriesByMeal(entries);

                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildNutritionSummaryCard(totalNutrition),
                              ...groupedEntries.entries.map(
                                (entry) =>
                                    _buildMealSection(entry.key, entry.value),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
