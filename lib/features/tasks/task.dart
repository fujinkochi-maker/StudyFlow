import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high }

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueAt,
    required this.status,
    required this.priority,
    required this.reminderEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime? dueAt;
  final TaskStatus status;
  final TaskPriority priority;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue {
    if (dueAt == null) return false;
    if (status == TaskStatus.done) return false;
    return dueAt!.isBefore(DateTime.now());
  }

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueAt,
    bool dueAtToNull = false,
    TaskStatus? status,
    TaskPriority? priority,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueAt: dueAtToNull ? null : (dueAt ?? this.dueAt),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'dueAt': dueAt?.toIso8601String(),
    'status': status.index,
    'priority': priority.index,
    'reminderEnabled': reminderEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Task? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final title = json['title'] as String?;
      final subject = json['subject'] as String?;
      if (id == null || title == null || subject == null) return null;
      final dueAtRaw = json['dueAt'] as String?;
      final createdAtRaw = json['createdAt'] as String?;
      final updatedAtRaw = json['updatedAt'] as String?;
      final statusIndex = json['status'] as int?;
      final priorityIndex = json['priority'] as int?;
      return Task(
        id: id,
        title: title,
        subject: subject,
        dueAt: dueAtRaw == null ? null : DateTime.tryParse(dueAtRaw),
        status: TaskStatus.values[(statusIndex ?? 0).clamp(0, TaskStatus.values.length - 1)],
        priority: TaskPriority.values[(priorityIndex ?? 1).clamp(0, TaskPriority.values.length - 1)],
        reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
        createdAt: DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(updatedAtRaw ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
