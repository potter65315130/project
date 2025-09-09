// lib/widgets/calorie_chart_widget.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_mate/models/daily_quest_model.dart';
import 'package:intl/intl.dart';

class CalorieChartWidget extends StatelessWidget {
  final List<DailyQuestModel> quests;

  const CalorieChartWidget({super.key, required this.quests});

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: const Text(
          'ไม่มีข้อมูลแคลอรี่',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // เรียงลำดับข้อมูลตามวันที่จากอดีตไปปัจจุบัน (ไม่ reverse)
    final sortedQuests = quests.toList();
    final List<FlSpot> spots = [];
    final Map<int, String> dayLabels = {};

    for (int i = 0; i < sortedQuests.length; i++) {
      final quest = sortedQuests[i];
      spots.add(FlSpot(i.toDouble(), quest.calorieIntake));
      dayLabels[i] = DateFormat('d MMM', 'th').format(quest.date);
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xff37434d),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(
                  color: Color(0xff37434d),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    return index < dayLabels.length
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayLabels[index]!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          )
                        : const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: spots.length > 0 ? spots.length - 1.toDouble() : 0,
            minY: 0,
            maxY: quests.isNotEmpty
                ? quests.map((q) => q.calorieIntake).reduce(max) * 1.2
                : 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF8BC34A),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF8BC34A).withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}