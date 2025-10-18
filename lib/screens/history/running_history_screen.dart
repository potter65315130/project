import 'package:flutter/material.dart';
import 'package:health_mate/models/running_session_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RunningHistoryScreen extends StatelessWidget {
  const RunningHistoryScreen({super.key});

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatPace(double distance, int seconds) {
    if (distance <= 0 || seconds <= 0) return 'N/A';
    final pace = (seconds / 60) / (distance / 1000);
    return '${pace.toStringAsFixed(1)} นาที/กม.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'ประวัติการวิ่ง',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFCDFF00),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<RunningSessionModel>>(
        stream: context.watch<HomeProvider>().runningHistoryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCDFF00)),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint("Error loading running history: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูล\n'
                  '${snapshot.error.toString().contains("firestore/failed-precondition") ? "หมายเหตุ: คุณอาจจะต้องสร้าง Index ใน Firestore (ดูวิธีใน Console)" : snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sessions = snapshot.data;

          if (sessions == null || sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 60, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'ไม่พบประวัติการวิ่ง',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  Text(
                    'เริ่มออกไปวิ่งเพื่อบันทึกสถิติของคุณ!',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildHistoryCard(context, session);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, RunningSessionModel session) {
    final distanceKm = (session.distance / 1000).toStringAsFixed(2);
    final durationStr = _formatDuration(session.durationSeconds);
    final paceStr = _formatPace(session.distance, session.durationSeconds);
    final dateStr = DateFormat.yMd('th').add_Hm().format(session.timestamp);

    return Card(
      color: const Color(0xFF262626),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                color: Color(0xFFCDFF00),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.straighten, 'ระยะทาง', '$distanceKm กม.'),
                _buildStatItem(Icons.timer, 'เวลา', durationStr),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.trending_up, 'Pace', paceStr),
                _buildStatItem(
                  Icons.local_fire_department,
                  'เผาผลาญ',
                  '${session.caloriesBurned.toInt()} kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
