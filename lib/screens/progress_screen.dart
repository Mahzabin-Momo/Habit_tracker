import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_progress_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Overview'),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (habitProvider.habits.isEmpty) {
            return const Center(
              child: Text('No habits to show progress'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Habit Streaks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: HabitProgressChart(
                          habits: habitProvider.habits,
                          completions: habitProvider.completions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...habitProvider.habits.map((habit) {
                final streak = habitProvider.streaks[habit.id] ?? 0;
                return Card(
                  child: ListTile(
                    title: Text(habit.title),
                    subtitle: Text('Current Streak: $streak days'),
                    trailing: Icon(
                      Icons.local_fire_department,
                      color: streak > 0 ? Colors.orange : Colors.grey,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
