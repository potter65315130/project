import 'package:flutter/material.dart';
import 'package:health_mate/models/exercise_log_model.dart';
import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/providers/exercise_provider.dart';
import 'package:health_mate/providers/user_provider.dart';
import 'package:health_mate/screens/exercise/exercise_detail_screen.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExerciseListScreen extends StatefulWidget {
  final ExerciseCategory category;
  final String title;

  const ExerciseListScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(
        context,
        listen: false,
      ).filterExercises(widget.category, query: '');
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9ACD32),
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF2A2A2A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Color(0xFF9ACD32),
            labelColor: Color(0xFF9ACD32),
            unselectedLabelColor: Colors.white54,
            tabs: [Tab(text: 'ค้นหา'), Tab(text: 'รายการของฉัน')],
          ),
        ),
        body: TabBarView(children: [_buildSearchTab(), _buildMyItemsTab()]),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  provider.filterExercises(widget.category, query: value);
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ค้นหาจากชื่อ..',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9ACD32),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF9ACD32)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = provider.filteredExercises[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3A3A3A),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9ACD32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ExerciseDetailScreen(exercise: exercise),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyItemsTab() {
    final uid = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (uid == null) {
      return const Center(
        child: Text(
          'ไม่พบข้อมูลผู้ใช้',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.yMMMMd('th').format(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF9ACD32),
                ),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF3A3A3A), height: 1),
        Expanded(
          child: StreamBuilder<List<ExerciseLogModel>>(
            stream: _firestoreService.getExerciseLogsStream(uid, formattedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'ไม่พบรายการออกกำลังกายที่บันทึกไว้\nสำหรับวันที่เลือก',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final logs = snapshot.data!;
              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Dismissible(
                    key: ValueKey(log.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red[800],
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF2A2A2A),
                            title: const Text(
                              "ยืนยันการลบ",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              "คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text(
                                  "ยกเลิก",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  "ลบ",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        await _firestoreService.deleteExerciseLog(
                          uid,
                          formattedDate,
                          log,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("'${log.exerciseName}' ถูกลบแล้ว"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("เกิดข้อผิดพลาดในการลบ: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9ACD32).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Color(0xFF9ACD32),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          log.exerciseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'เผาผลาญ: ${log.caloriesBurned.toStringAsFixed(0)} kcal',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          DateFormat.Hm().format(log.timestamp),
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          final exerciseProvider =
                              Provider.of<ExerciseProvider>(
                                context,
                                listen: false,
                              );
                          final exercise = exerciseProvider.findExerciseByName(
                            log.exerciseName,
                          );

                          if (exercise != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ExerciseDetailScreen(
                                      exercise: exercise,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'ไม่พบรายละเอียดของท่าออกกำลังกายนี้',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
