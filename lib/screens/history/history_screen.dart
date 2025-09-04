import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:health_mate/models/daily_quest_model.dart';
import 'package:health_mate/models/user_model.dart';
import 'package:health_mate/services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  final UserModel user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;

  List<DailyQuestModel> _historyData = [];
  bool _isLoading = true;
  String _headerText = 'ข้อมูล 30 วันล่าสุด';

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  // เพื่อให้แน่ใจว่าการตั้งค่าภาษาไทยเสร็จสิ้นก่อนเรียกใช้ DateFormat
  Future<void> _initializeAndLoadData() async {
    // รอการตั้งค่าข้อมูลสำหรับภาษาไทยให้เสร็จ
    await initializeDateFormatting('th', null);
    // จากนั้นจึงโหลดข้อมูล 30 วันล่าสุดเป็นค่าเริ่มต้น
    await _loadLast30Days();
  }

  Future<void> _loadLast30Days() async {
    setState(() {
      _isLoading = true;
      _headerText = 'ข้อมูล 30 วันล่าสุด';
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _firestoreService.getLast30DaysQuests(uid);
      setState(() {
        _historyData = data;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading last 30 days: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
          backgroundColor: Colors.grey[800],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectSingleDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9CCC65),
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      await _loadDataForSingleDate(selectedDate);
    }
  }

  Future<void> _loadDataForSingleDate(DateTime selectedDate) async {
    setState(() {
      _isLoading = true;
      final formatter = DateFormat('EEEE, d MMMM y', 'th');
      _headerText = 'ข้อมูลวันที่ ${formatter.format(selectedDate)}';
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // โหลดข้อมูลเฉพาะวันที่เลือก
      final data = await _firestoreService.getQuestHistoryForDateRange(
        uid,
        selectedDate,
        selectedDate,
      );
      setState(() {
        _historyData = data;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading single date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('เกิดข้อผิดพลาดในการโหลดข้อมูลวันที่เลือก'),
          backgroundColor: Colors.grey[800],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // เพิ่มฟังก์ชันสำหรับกลับไปดูข้อมูล 30 วันล่าสุด
  void _resetToLast30Days() {
    _loadLast30Days();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('ประวัติ'),
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        actions: [
          // ปุ่มเลือกวันที่
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'เลือกวันที่',
            onPressed: _selectSingleDate,
          ),
          // ปุ่มกลับไปดูข้อมูล 30 วันล่าสุด
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'ดูข้อมูล 30 วันล่าสุด',
            onPressed: _resetToLast30Days,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _headerText,
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CCC65)),
                        ),
                      )
                    : _historyData.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่พบข้อมูลในช่วงเวลานี้',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                      itemCount: _historyData.length,
                      itemBuilder: (context, index) {
                        final quest = _historyData[index];
                        final netColor =
                            quest.netCalorie > 0 ? const Color(0xFF9CCC65) : Colors.red;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          color: const Color(0xFF2A2A2A),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: netColor.withOpacity(0.1),
                              child: Text(
                                DateFormat('d').format(quest.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: netColor,
                                ),
                              ),
                            ),
                            title: Text(
                              DateFormat(
                                'EEEE, d MMMM y',
                                'th',
                              ).format(quest.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'ได้รับ: ${quest.calorieIntake.toInt()} kcal | เผาผลาญ: ${quest.calorieBurned.toInt()} kcal',
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                            trailing: Text(
                              '${quest.netCalorie.toInt()}',
                              style: TextStyle(
                                color: netColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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