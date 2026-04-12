import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/features/notes/course.dart';
import 'package:study_flow/features/notes/note.dart';

class NotesService extends ChangeNotifier {
  static const _coursesKey = 'courses_v1';
  static const _notesKey = 'notes_v1';

  final List<Course> _courses = [];
  final List<Note> _notes = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<Course> get courses => List.unmodifiable(_courses);
  List<Note> get notes => List.unmodifiable(_notes);

  List<Note> notesForCourse(String courseId) {
    final list = _notes.where((n) => n.courseId == courseId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<Note> search(String query, {String? courseId}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return courseId == null ? notes : notesForCourse(courseId);
    return _notes
        .where((n) {
          if (courseId != null && n.courseId != courseId) return false;
          return n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q);
        })
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Course? courseById(String id) =>
      _courses.cast<Course?>().firstWhere((c) => c?.id == id, orElse: () => null);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _courses.clear();
      _notes.clear();

      final rawCourses = prefs.getString(_coursesKey);
      final rawNotes = prefs.getString(_notesKey);

      if (rawCourses == null || rawNotes == null) {
        _seed();
        await _persist();
      } else {
        final c = jsonDecode(rawCourses);
        if (c is List) {
          for (final item in c) {
            if (item is Map<String, dynamic>) {
              final course = Course.fromJson(item);
              if (course != null) _courses.add(course);
            }
          }
        }
        final n = jsonDecode(rawNotes);
        if (n is List) {
          for (final item in n) {
            if (item is Map<String, dynamic>) {
              final note = Note.fromJson(item);
              if (note != null) _notes.add(note);
            }
          }
        }
        await _persist();
      }
    } catch (e) {
      debugPrint('Failed to load notes: $e');
      _courses.clear();
      _notes.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  // ── Courses ──────────────────────────────────────────────────────────────

  Future<void> addCourse({required String name, required IconData icon}) async {
    await addCourseAndReturn(name: name, icon: icon);
  }

  Future<Course?> addCourseAndReturn({required String name, required IconData icon, Color? folderColor}) async {
    final now = DateTime.now();
    final course = Course(
      id: 'c-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      iconCodePoint: icon.codePoint,
      folderColorValue: folderColor?.value,
      createdAt: now,
      updatedAt: now,
    );
    _courses.insert(0, course);
    notifyListeners();
    await _persist();
    return course;
  }

  Future<void> updateCourse(Course updated) async {
    final idx = _courses.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return;
    _courses[idx] = updated.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCourse(String courseId) async {
    _courses.removeWhere((c) => c.id == courseId);
    _notes.removeWhere((n) => n.courseId == courseId);
    notifyListeners();
    await _persist();
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<Note> addNote({required String courseId, required String title, required String body}) async {
    final now = DateTime.now();
    final note = Note(
      id: 'n-${now.microsecondsSinceEpoch}',
      courseId: courseId,
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    _notes.insert(0, note);
    notifyListeners();
    await _persist();
    return note;
  }

  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx == -1) return;
    _notes[idx] = note.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
    await _persist();
  }

  void _seed() {
    // Start empty
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_coursesKey, jsonEncode(_courses.map((c) => c.toJson()).toList()));
      await prefs.setString(_notesKey, jsonEncode(_notes.map((n) => n.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to persist notes: $e');
    }
  }
}