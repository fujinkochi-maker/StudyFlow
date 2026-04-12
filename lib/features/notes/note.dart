import 'package:flutter/foundation.dart';

@immutable
class Note {
  const Note({required this.id, required this.courseId, required this.title, required this.body, required this.createdAt, required this.updatedAt});

  final String id;
  final String courseId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({String? courseId, String? title, String? body, DateTime? updatedAt}) {
    return Note(
      id: id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Note? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final courseId = json['courseId'];
      final title = json['title'];
      final body = json['body'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];
      if (id is! String || courseId is! String || title is! String || body is! String || createdAt is! String || updatedAt is! String) return null;
      return Note(id: id, courseId: courseId, title: title, body: body, createdAt: DateTime.parse(createdAt), updatedAt: DateTime.parse(updatedAt));
    } catch (_) {
      return null;
    }
  }
}
