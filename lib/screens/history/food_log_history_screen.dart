import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_mate/models/food/food_entry_model.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // เพิ่มบรรทัดนี้

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

  // เพิ่ม method นี้
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadEntriesForSelectedDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกย้อนหลัง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body:
          !_isLocaleInitialized
              ? const Center(
                child: CircularProgressIndicator(),
              ) // แสดง loading ขณะ initialize
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'รายการวันที่: ${DateFormat('d MMMM yyyy', 'th').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<FoodEntryModel>>(
                      future: _foodEntriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('ไม่พบรายการอาหารในวันที่เลือก'),
                          );
                        }

                        final entries = snapshot.data!;
                        return ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return ListTile(
                              title: Text(entry.name),
                              subtitle: Text(
                                'Cal: ${entry.calories.toStringAsFixed(0)}, P: ${entry.protein.toStringAsFixed(1)}g, C: ${entry.carbs.toStringAsFixed(1)}g, F: ${entry.fat.toStringAsFixed(1)}g',
                              ),
                              trailing: Text(
                                DateFormat('HH:mm').format(entry.timestamp),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
