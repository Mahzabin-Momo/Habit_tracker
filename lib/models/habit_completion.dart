import 'package:cloud_firestore/cloud_firestore.dart';

class HabitCompletion {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  factory HabitCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitCompletion(
      id: doc.id,
      habitId: data['habitId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      completed: data['completed'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'completed': completed,
    };
  }

  HabitCompletion copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
    );
  }
}
