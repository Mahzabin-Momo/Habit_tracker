import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_category.dart';
import '../providers/habit_provider.dart';
import '../screens/habit_form_screen.dart';
import '../widgets/habit_progress_chart.dart';
import '../widgets/quotes_section.dart';
import '../widgets/expansion_card.dart';

class HomeContent extends StatelessWidget {
  final String userId;
  final VoidCallback refreshQuote;

  const HomeContent({
    super.key,
    required this.userId,
    required this.refreshQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        if (habitProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (habitProvider.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: QuotesSection(),
                ),
                const SizedBox(height: 32),
                const Text(
                  'No habits yet!',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HabitFormScreen(userId: userId),
                      ),
                    );
                  },
                  child: const Text('Create your first habit'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await habitProvider.loadHabits(userId);
            refreshQuote();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habitProvider.habits.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    QuotesSection(),
                    SizedBox(height: 24),
                  ],
                );
              }

              final habit = habitProvider.habits[index - 1];
              final category = HabitCategory.getById(habit.categoryId);
              final completions = habitProvider.completions[habit.id] ?? [];
              final streak = habitProvider.streaks[habit.id] ?? 0;

              return ExpansionCard(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withOpacity(0.2),
                        child: Icon(
                          category.icon,
                          color: category.color,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(habit.title),
                          ),
                          if (streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: category.color,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                habit.frequency.toString().split('.').last,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (habit.notes != null && habit.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                habit.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Completion Checkbox
                          if (habitProvider.canCompleteForDate(habit, DateTime.now()))
                            Checkbox(
                              value: completions.any((c) => 
                                habitProvider.isSameDay(c.date, DateTime.now()) && 
                                c.completed
                              ),
                              onChanged: (_) {
                                habitProvider.toggleCompletion(
                                  habit,
                                  DateTime.now(),
                                );
                              },
                            ),
                          // Menu Button
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HabitFormScreen(
                                      userId: userId,
                                      habit: habit,
                                    ),
                                  ),
                                );
                                habitProvider.loadHabits(userId);
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Habit'),
                                    content: const Text(
                                      'Are you sure you want to delete this habit?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await habitProvider.deleteHabit(habit);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Progress Chart
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: HabitProgressChart(
                        habits: [habit],
                        completions: {habit.id: completions},
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
