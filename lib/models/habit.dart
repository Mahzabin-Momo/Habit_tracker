import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitFrequency {
  daily,
  weekly,
}

class Habit {
  final String id;
  final String title;
  final String categoryId;
  final HabitFrequency frequency;
  final DateTime? startDate;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  final int currentStreak;

  Habit({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.frequency,
    this.startDate,
    this.notes,
    required this.userId,
    required this.createdAt,
    this.currentStreak = 0,
  });

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      title: data['title'] as String,
      categoryId: data['categoryId'] as String,
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.toString() == data['frequency'],
      ),
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'categoryId': categoryId,
      'frequency': frequency.toString(),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentStreak': currentStreak,
    };
  }

  Habit copyWith({
    String? title,
    String? categoryId,
    HabitFrequency? frequency,
    DateTime? startDate,
    String? notes,
    int? currentStreak,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      userId: userId,
      createdAt: createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}
