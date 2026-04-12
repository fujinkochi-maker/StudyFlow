import 'package:flutter/foundation.dart';

@immutable
class Note {
  const Note({required this.id, required this.courseId, required this.title, required this.body, required this.createdAt, required this.updatedAt, this.attachedFilePath});

  final String id;
  final String courseId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attachedFilePath;

  bool get hasAttachedFile => attachedFilePath != null && attachedFilePath!.isNotEmpty;

  Note copyWith({String? courseId, String? title, String? body, DateTime? updatedAt, String? attachedFilePath, bool clearAttachedFile = false}) {
    return Note(
      id: id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachedFilePath: clearAttachedFile ? null : (attachedFilePath ?? this.attachedFilePath),
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
      if (attachedFilePath != null) 'attachedFilePath': attachedFilePath,
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
      final attachedFilePath = json['attachedFilePath'];
      if (id is! String || courseId is! String || title is! String || body is! String || createdAt is! String || updatedAt is! String) return null;
      return Note(
        id: id,
        courseId: courseId,
        title: title,
        body: body,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        attachedFilePath: attachedFilePath is String ? attachedFilePath : null,
      );
    } catch (_) {
      return null;
    }
  }
}
