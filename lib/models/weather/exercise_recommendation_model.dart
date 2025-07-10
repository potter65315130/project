import 'dart:ui';

class ExerciseRecommendation {
  final String title;
  final String description;
  final Color color;
  final String rainWarning;

  ExerciseRecommendation({
    required this.title,
    required this.description,
    required this.color,
    this.rainWarning = '',
  });
}
