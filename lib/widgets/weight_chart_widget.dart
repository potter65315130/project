import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_mate/models/daily_quest_model.dart';
import 'package:intl/intl.dart';

class WeightChartWidget extends StatelessWidget {
  final List<DailyQuestModel> quests;

  const WeightChartWidget({super.key, required this.quests});

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูลน้ำหนักย้อนหลัง'));
    }

    final List<FlSpot> spots =
        quests.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.weight);
        }).toList();

    final List<String> dates =
        quests.map((e) => DateFormat('d MMM', 'th').format(e.date)).toList();

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < dates.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dates[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: const Color(0xFF8BC34A),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter:
                      (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF8BC34A),
                        strokeColor: Colors.transparent,
                      ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
