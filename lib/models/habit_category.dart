import 'package:flutter/material.dart';

class HabitCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const HabitCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<HabitCategory> predefinedCategories = [
    HabitCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.favorite,
      color: Colors.red,
    ),
    HabitCategory(
      id: 'study',
      name: 'Study',
      icon: Icons.school,
      color: Colors.blue,
    ),
    HabitCategory(
      id: 'fitness',
      name: 'Fitness',
      icon: Icons.fitness_center,
      color: Colors.green,
    ),
    HabitCategory(
      id: 'productivity',
      name: 'Productivity',
      icon: Icons.check_circle,
      color: Colors.orange,
    ),
    HabitCategory(
      id: 'mental_health',
      name: 'Mental Health',
      icon: Icons.psychology,
      color: Colors.purple,
    ),
    HabitCategory(
      id: 'others',
      name: 'Others',
      icon: Icons.more_horiz,
      color: Colors.grey,
    ),
  ];

  static HabitCategory getById(String id) {
    return predefinedCategories.firstWhere(
      (category) => category.id == id,
      orElse: () => predefinedCategories.last,
    );
  }
}
