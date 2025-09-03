import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

class HabitProgressChart extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, List<HabitCompletion>> completions;
  final int daysToShow;

  const HabitProgressChart({
    super.key,
    required this.habits,
    required this.completions,
    this.daysToShow = 7,
  });

  List<BarChartGroupData> _getBarGroups(BuildContext context, List<DateTime> dates) {
    return List.generate(
      dates.length,
      (index) {
        final date = dates[index];
        int completedCount = 0;

        for (final habit in habits) {
          final habitCompletions = completions[habit.id] ?? [];
          if (habitCompletions.any(
            (completion) =>
                isSameDay(completion.date, date) && completion.completed,
          )) {
            completedCount++;
          }
        }

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: completedCount.toDouble(),
              color: Theme.of(context).primaryColor,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(
      daysToShow,
      (index) => now.subtract(Duration(days: daysToShow - 1 - index)),
    );

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: habits.length.toDouble(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = dates[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              barGroups: _getBarGroups(context, dates),
            ),
          ),
        ),
      ),
    );
  }
}
