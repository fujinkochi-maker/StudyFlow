import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/features/tasks/task.dart';

class TaskService extends ChangeNotifier {
  static const _prefsKey = 'tasks_v1';

  final List<Task> _tasks = [];
  bool _loaded = false;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get loaded => _loaded;

  int get completedCount => _tasks.where((t) => t.status == TaskStatus.done).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  int get dueTodayCount {
    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    return _tasks.where((t) => t.dueAt != null && t.status != TaskStatus.done && isSameDay(t.dueAt!, now)).length;
  }

  double get completionRatio {
    if (_tasks.isEmpty) return 0;
    return completedCount / _tasks.length;
  }

  List<Task> upcoming({int limit = 10}) {
    final now = DateTime.now();
    final upcoming = _tasks.where((t) => t.status != TaskStatus.done && t.dueAt != null).toList();
    upcoming.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return upcoming.where((t) => t.dueAt!.isAfter(now.subtract(const Duration(days: 3650)))).take(limit).toList();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _tasks.clear();
      if (raw == null) {
        _tasks.addAll(_seedSampleTasks());
        await _persist();
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final task = Task.fromJson(item);
              if (task != null) _tasks.add(task);
            }
          }
        }
        // Sanitize storage if corruption occurred.
        await _persist();
      }
    } catch (e) {
      debugPrint('Failed to load tasks: $e');
      _tasks
        ..clear()
        ..addAll(_seedSampleTasks());
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> add(Task task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _persist();
  }

  Future<void> update(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleStatus(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    final next = switch (task.status) {
      TaskStatus.todo => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };
    _tasks[index] = task.copyWith(status: next, updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to persist tasks: $e');
    }
  }

  List<Task> _seedSampleTasks() {
    final now = DateTime.now();
    String id(int i) => '${now.microsecondsSinceEpoch}-$i';
    return [
      Task(
        id: id(1),
        title: 'Finish calculus problem set',
        subject: 'Math',
        dueAt: now.add(const Duration(hours: 6)),
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        reminderEnabled: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Task(
        id: id(2),
        title: 'Draft history essay outline',
        subject: 'History',
        dueAt: now.add(const Duration(days: 1, hours: 2)),
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        reminderEnabled: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: id(3),
        title: 'Review bio notes (Chapter 4)',
        subject: 'Biology',
        dueAt: now.subtract(const Duration(hours: 3)),
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        reminderEnabled: true,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
