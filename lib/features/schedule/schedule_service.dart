import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'class_schedule.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Service - Manage class schedules
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleService extends ChangeNotifier {
  static const _storageKey = 'class_schedules_v1';
  final List<ClassSchedule> _schedules = [];
  final _uuid = const Uuid();

  List<ClassSchedule> get schedules => List.unmodifiable(_schedules);

  ScheduleService() {
    _load();
  }

  // Get schedules for a specific day
  List<ClassSchedule> getSchedulesForDay(DayOfWeek day) {
    return _schedules
        .where((s) => s.dayOfWeek == day)
        .toList()
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  // Get today's schedules
  List<ClassSchedule> getTodaySchedules() {
    final today = DayOfWeek.fromDateTime(DateTime.now());
    return getSchedulesForDay(today);
  }

  // Get upcoming classes for today
  List<ClassSchedule> getUpcomingClasses() {
    final now = DateTime.now();
    final today = DayOfWeek.fromDateTime(now);
    final currentMinutes = now.hour * 60 + now.minute;
    
    return _schedules
        .where((s) {
          if (s.dayOfWeek != today) return false;
          final startMinutes = s.startTime.hour * 60 + s.startTime.minute;
          return startMinutes > currentMinutes;
        })
        .toList()
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  // Add new class schedule
  Future<void> addSchedule({
    required String courseName,
    String? courseCode,
    required DayOfWeek dayOfWeek,
    required DateTime startTime,
    required DateTime endTime,
    String? room,
    String? building,
    String? professor,
    required int colorValue,
  }) async {
    final now = DateTime.now();
    final schedule = ClassSchedule(
      id: _uuid.v4(),
      courseName: courseName,
      courseCode: courseCode,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
      building: building,
      professor: professor,
      colorValue: colorValue,
      createdAt: now,
      updatedAt: now,
    );

    _schedules.add(schedule);
    await _save();
    notifyListeners();
  }

  // Update existing schedule
  Future<void> update(ClassSchedule updated) async {
    final index = _schedules.indexWhere((s) => s.id == updated.id);
    if (index == -1) return;

    _schedules[index] = updated.copyWith(updatedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  // Delete schedule
  Future<void> delete(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    await _save();
    notifyListeners();
  }

  // Check for time conflicts
  List<ClassSchedule> findConflicts(ClassSchedule newSchedule, {String? excludeId}) {
    return _schedules.where((s) {
      if (excludeId != null && s.id == excludeId) return false;
      return s.conflictsWith(newSchedule);
    }).toList();
  }

  // Load from storage
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _schedules.clear();
      _schedules.addAll(
        jsonList.map((json) => ClassSchedule.fromJson(json as Map<String, dynamic>)),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }
  }

  // Save to storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _schedules.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Get schedule statistics
  Map<String, dynamic> getStatistics() {
    if (_schedules.isEmpty) {
      return {
        'totalClasses': 0,
        'classesPerDay': <String, int>{},
        'totalHours': 0.0,
      };
    }

    final classesPerDay = <String, int>{};
    for (final day in DayOfWeek.values) {
      classesPerDay[day.displayName] = getSchedulesForDay(day).length;
    }

    final totalMinutes = _schedules.fold<int>(
      0,
      (sum, s) => sum + s.duration.inMinutes,
    );

    return {
      'totalClasses': _schedules.length,
      'classesPerDay': classesPerDay,
      'totalHours': totalMinutes / 60.0,
    };
  }
}
