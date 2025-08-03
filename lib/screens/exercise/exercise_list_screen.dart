// screens/exercise/exercise_list_screen.dart

import 'package:flutter/material.dart';
import 'package:health_mate/models/exercise_model.dart';
import 'package:health_mate/providers/exercise_provider.dart';
import 'package:health_mate/screens/exercise/exercise_detail_screen.dart';
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
  @override
  void initState() {
    super.initState();
    // โหลดรายการเมื่อหน้าจอถูกสร้าง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(
        context,
        listen: false,
      ).filterExercises(widget.category, query: '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 tabs: ค้นหา, รายการของฉัน
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
            tabs: [Tab(text: 'ค้นหา'), Tab(text: 'รายการของฉัน (วันนี้)')],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab: ค้นหา
            _buildSearchTab(),
            // Tab: รายการของฉัน (วันนี้)
            _buildMyItemsTab(),
          ],
        ),
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
    return const Center(
      child: Text(
        'ส่วนนี้จะแสดงรายการที่บันทึกไว้ของวันนี้\n(ดูโค้ดเพิ่มเติมใน FirestoreService)',
        style: TextStyle(color: Colors.white54, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}
