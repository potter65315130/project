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
        appBar: AppBar(
          title: Text(widget.title),
          bottom: const TabBar(
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
                decoration: InputDecoration(
                  labelText: 'ค้นหาจากชื่อ..',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = provider.filteredExercises[index];
                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(exercise.name),
                    trailing: const Icon(Icons.chevron_right),
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
    // TODO: Implement this tab to show ExerciseLogModel for today
    // You would use the getExerciseLogsStream from FirestoreService here
    // and listen to it with a StreamBuilder.
    return const Center(
      child: Text(
        'ส่วนนี้จะแสดงรายการที่บันทึกไว้ของวันนี้\n(ดูโค้ดเพิ่มเติมใน FirestoreService)',
      ),
    );
  }
}
