import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

class HabitProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Habit> _habits = [];
  final Map<String, List<HabitCompletion>> _completions = {};
  final Map<String, int> _streaks = {};
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => _habits;
  Map<String, List<HabitCompletion>> get completions => _completions;
  Map<String, int> get streaks => _streaks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHabits(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get();

      _habits = snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
      
      await Future.wait(_habits.map((habit) => loadCompletions(userId, habit.id)));
      
      for (var habit in _habits) {
        _streaks[habit.id] = habit.currentStreak;
      }
    } catch (e) {
      _error = 'Failed to load habits: ${e.toString()}';
      _habits = [];
      _completions.clear();
      _streaks.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCompletions(String userId, String habitId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .collection('completions')
          .orderBy('date', descending: true)
          .get();

      _completions[habitId] = snapshot.docs
          .map((doc) => HabitCompletion.fromFirestore(doc))
          .toList();
    } catch (e) {
      _completions[habitId] = [];
    }
  }

  Future<void> toggleCompletion(Habit habit, DateTime date) async {
    if (habit.userId.isEmpty || habit.id.isEmpty) {
      _error = 'Invalid habit data';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      if (!canCompleteForDate(habit, date)) {
        throw Exception('Cannot complete habit for this date');
      }

      final habitRef = _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc(habit.id);

      final existingCompletion = _completions[habit.id]?.firstWhere(
        (c) => isSameDay(c.date, date),
        orElse: () => HabitCompletion(
          id: '',
          habitId: habit.id,
          date: date,
          completed: false,
        ),
      );

      final existingId = existingCompletion?.id ?? '';
      final isCurrentlyCompleted = existingCompletion?.completed ?? false;

      if (existingId.isEmpty) {
        // Create new completion
        final completionRef = habitRef.collection('completions').doc();
        
        final completion = HabitCompletion(
          id: completionRef.id,
          habitId: habit.id,
          date: date,
          completed: true,
        );

        await completionRef.set({
          'date': Timestamp.fromDate(date),
          'completed': true,
          'habitId': habit.id,
        });

        _completions[habit.id] = [...(_completions[habit.id] ?? []), completion];
      } else {
        // Toggle existing completion
        final newCompletedStatus = !isCurrentlyCompleted;
        await habitRef
            .collection('completions')
            .doc(existingId)
            .update({
          'completed': newCompletedStatus,
        });

        final habitId = habit.id;
        final completions = _completions[habitId];
        if (completions != null) {
          _completions[habitId] = completions.map((c) {
            if (c.id == existingCompletion?.id) {
              return c.copyWith(completed: newCompletedStatus);
            }
            return c;
          }).toList();
        }
      }

      // Calculate and save new streak
      final newStreak = calculateStreak(habit);
      _streaks[habit.id] = newStreak;

      // Update streak in the habit document
      await habitRef.update({
        'currentStreak': newStreak,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update the habit object in memory
      final habitIndex = _habits.indexWhere((h) => h.id == habit.id);
      if (habitIndex != -1) {
        _habits[habitIndex] = _habits[habitIndex].copyWith(currentStreak: newStreak);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool canCompleteForDate(Habit habit, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (habit.frequency == HabitFrequency.daily) {
      // For daily habits, only allow completing today
      return targetDate.isAtSameMomentAs(today);
    } else {
      // For weekly habits, allow completing any day in the current week
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return targetDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          targetDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }
  }

  int calculateStreak(Habit habit) {
    final completions = _completions[habit.id] ?? [];
    if (completions.isEmpty) return 0;

    // Sort completions by date
    completions.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (habit.frequency == HabitFrequency.daily) {
      var lastCompletedDate = today.subtract(const Duration(days: 1));
      
      // Check if completed today
      final todayCompletion = completions.firstWhere(
        (c) => isSameDay(c.date, today) && c.completed,
        orElse: () => HabitCompletion(
          id: '',
          habitId: habit.id,
          date: today,
          completed: false,
        ),
      );
      
      if (todayCompletion.completed) {
        streak = 1;
        lastCompletedDate = today;
      }
      
      // Check previous days
      for (var completion in completions) {
        if (!completion.completed) continue;
        
        final completionDate = DateTime(
          completion.date.year,
          completion.date.month,
          completion.date.day,
        );
        
        // If there's a gap of more than one day, break the streak
        if (lastCompletedDate.difference(completionDate).inDays > 1) {
          break;
        }
        
        // If this is a day before the last completed date, increment streak
        if (completionDate.isBefore(lastCompletedDate)) {
          streak++;
          lastCompletedDate = completionDate;
        }
      }
    } else {
      // Weekly streak calculation
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      var weekStart = currentWeekStart;
      
      for (var week = 0; week < completions.length; week++) {
        final weekCompletions = completions.where(
          (c) => isInSameWeek(c.date, weekStart) && c.completed,
        );
        
        if (weekCompletions.isEmpty) {
          break;
        }
        
        streak++;
        weekStart = weekStart.subtract(const Duration(days: 7));
      }
    }

    return streak;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isInSameWeek(DateTime a, DateTime b) {
    final aWeekStart = a.subtract(Duration(days: a.weekday - 1));
    final bWeekStart = b.subtract(Duration(days: b.weekday - 1));
    return isSameDay(aWeekStart, bWeekStart);
  }

  Future<void> addHabit(Habit habit) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final habitRef = _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc();

      final newHabit = Habit(
        id: habitRef.id,
        title: habit.title,
        categoryId: habit.categoryId,
        frequency: habit.frequency,
        startDate: habit.startDate,
        notes: habit.notes,
        userId: habit.userId,
        createdAt: DateTime.now(),
        currentStreak: 0,
      );

      await habitRef.set(newHabit.toFirestore());
      await loadHabits(habit.userId);
    } catch (e) {
      _error = 'Failed to add habit';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update habit document with current streak
      final habitData = {
        ...habit.toFirestore(),
        'currentStreak': _streaks[habit.id] ?? 0,
      };

      await _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc(habit.id)
          .update(habitData);
      await loadHabits(habit.userId);
    } catch (e) {
      _error = 'Failed to update habit';
      notifyListeners();
    }
  }

  Future<void> deleteHabit(Habit habit) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Delete the habit and all its completions
      final habitRef = _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc(habit.id);

      // Get all completions
      final completionsSnapshot = await habitRef
          .collection('completions')
          .get();

      // Delete all completions in a batch
      final batch = _firestore.batch();
      for (var doc in completionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the habit document
      batch.delete(habitRef);

      // Commit the batch
      await batch.commit();
      await loadHabits(habit.userId);
    } catch (e) {
      _error = 'Failed to delete habit';
      notifyListeners();
    }
  }
}
