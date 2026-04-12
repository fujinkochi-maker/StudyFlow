import 'package:flutter/foundation.dart';

@immutable
class Flashcard {
  const Flashcard({required this.id, required this.courseId, required this.front, required this.back, required this.createdAt, required this.updatedAt});

  final String id;
  final String courseId;
  final String front;
  final String back;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard copyWith({String? courseId, String? front, String? back, DateTime? updatedAt}) {
    return Flashcard(
      id: id,
      courseId: courseId ?? this.courseId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'front': front,
      'back': back,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Flashcard? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final courseId = json['courseId'];
      final front = json['front'];
      final back = json['back'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];
      if (id is! String || courseId is! String || front is! String || back is! String || createdAt is! String || updatedAt is! String) return null;
      return Flashcard(id: id, courseId: courseId, front: front, back: back, createdAt: DateTime.parse(createdAt), updatedAt: DateTime.parse(updatedAt));
    } catch (_) {
      return null;
    }
  }
}
