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
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );

    if (dateRange != null) {
      await _loadDataForDateRange(dateRange.start, dateRange.end);
    }
  }

  Future<void> _loadDataForDateRange(DateTime start, DateTime end) async {
    setState(() {
      _isLoading = true;
      final formatter = DateFormat('d MMM y', 'th');
      _headerText =
          'ข้อมูลวันที่ ${formatter.format(start)} - ${formatter.format(end)}';
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _firestoreService.getQuestHistoryForDateRange(
        uid,
        start,
        end,
      );
      setState(() {
        _historyData = data;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading date range: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลตามช่วงเวลา'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติ'),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'เลือกช่วงเวลา',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _headerText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _historyData.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูลในข่วงเวลานี้'))
                    : ListView.builder(
                      itemCount: _historyData.length,
                      itemBuilder: (context, index) {
                        final quest = _historyData[index];
                        final netColor =
                            quest.netCalorie > 0 ? Colors.green : Colors.red;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
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
                              ),
                            ),
                            subtitle: Text(
                              'ได้รับ: ${quest.calorieIntake.toInt()} kcal | เผาผลาญ: ${quest.calorieBurned.toInt()} kcal',
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
