import 'package:flutter/foundation.dart';

@immutable
class QuizAttempt {
  const QuizAttempt({required this.id, required this.courseId, required this.total, required this.correct, required this.createdAt});
  final String id;
  final String courseId;
  final int total;
  final int correct;
  final DateTime createdAt;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'total': total,
      'correct': correct,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static QuizAttempt? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final courseId = json['courseId'];
      final total = json['total'];
      final correct = json['correct'];
      final createdAt = json['createdAt'];
      if (id is! String || courseId is! String || total is! int || correct is! int || createdAt is! String) return null;
      return QuizAttempt(id: id, courseId: courseId, total: total, correct: correct, createdAt: DateTime.parse(createdAt));
    } catch (_) {
      return null;
    }
  }
}
