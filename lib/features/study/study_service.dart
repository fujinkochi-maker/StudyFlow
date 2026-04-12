import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/features/study/flashcard.dart';
import 'package:study_flow/features/study/quiz_attempt.dart';

class StudyService extends ChangeNotifier {
  static const _cardsKey = 'flashcards_v1';
  static const _attemptsKey = 'quiz_attempts_v1';
  static const _studySecondsKey = 'study_seconds_v1';

  final List<Flashcard> _cards = [];
  final List<QuizAttempt> _attempts = [];
  int _studySeconds = 0;
  bool _loaded = false;

  bool get loaded => _loaded;
  List<Flashcard> get cards => List.unmodifiable(_cards);
  List<QuizAttempt> get attempts => List.unmodifiable(_attempts);
  int get studySeconds => _studySeconds;

  List<Flashcard> cardsForCourse(String courseId) {
    final list = _cards.where((c) => c.courseId == courseId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  double overallAccuracy({String? courseId}) {
    final list = courseId == null ? _attempts : _attempts.where((a) => a.courseId == courseId).toList();
    final total = list.fold<int>(0, (sum, a) => sum + a.total);
    final correct = list.fold<int>(0, (sum, a) => sum + a.correct);
    return total == 0 ? 0 : correct / total;
  }

  int quizzesTaken({String? courseId}) => courseId == null ? _attempts.length : _attempts.where((a) => a.courseId == courseId).length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cards.clear();
      _attempts.clear();
      _studySeconds = prefs.getInt(_studySecondsKey) ?? 0;

      final rawCards = prefs.getString(_cardsKey);
      final rawAttempts = prefs.getString(_attemptsKey);

      if (rawCards == null || rawAttempts == null) {
        _seed();
        await _persist();
      } else {
        final c = jsonDecode(rawCards);
        if (c is List) {
          for (final item in c) {
            if (item is Map<String, dynamic>) {
              final card = Flashcard.fromJson(item);
              if (card != null) _cards.add(card);
            }
          }
        }
        final a = jsonDecode(rawAttempts);
        if (a is List) {
          for (final item in a) {
            if (item is Map<String, dynamic>) {
              final attempt = QuizAttempt.fromJson(item);
              if (attempt != null) _attempts.add(attempt);
            }
          }
        }
        await _persist();
      }
    } catch (e) {
      debugPrint('Failed to load study data: $e');
      _seed();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> addFlashcard({required String courseId, required String front, required String back}) async {
    final now = DateTime.now();
    final card = Flashcard(id: 'fc-${now.microsecondsSinceEpoch}', courseId: courseId, front: front.trim(), back: back.trim(), createdAt: now, updatedAt: now);
    _cards.insert(0, card);
    notifyListeners();
    await _persist();
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final idx = _cards.indexWhere((c) => c.id == card.id);
    if (idx == -1) return;
    _cards[idx] = card.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> deleteFlashcard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> addStudySeconds(int seconds) async {
    _studySeconds += seconds;
    notifyListeners();
    await _persist();
  }

  /// Creates a multiple-choice quiz from flashcards.
  /// Returns a list of questions: {question, options, correctIndex}
  List<Map<String, Object>> generateMcqFromCards({required String courseId, int count = 8}) {
    final rnd = Random();
    final pool = cardsForCourse(courseId);
    if (pool.length < 2) return const [];
    pool.shuffle(rnd);

    final questions = <Map<String, Object>>[];
    for (final card in pool.take(count)) {
      final correct = card.back;
      final wrong = pool.where((c) => c.id != card.id).map((c) => c.back).toSet().toList()..shuffle(rnd);
      final options = <String>[correct, ...wrong.take(3)];
      options.shuffle(rnd);
      questions.add({'question': card.front, 'options': options, 'correctIndex': options.indexOf(correct)});
    }
    return questions;
  }

  /// Lightweight "generate from notes": pulls sentence-like lines from notes.
  /// Produces ID-style questions (prompt -> expected phrase).
  List<Map<String, Object>> generateIdFromNotes({required String courseId, required NotesService notes, int count = 6}) {
    final rnd = Random();
    final bodies = notes.notesForCourse(courseId).map((n) => n.body).join('\n');
    final lines = bodies
        .split(RegExp(r'[\n\r]+'))
        .map((s) => s.trim())
        .where((s) => s.length >= 12)
        .toList();
    if (lines.length < 2) return const [];
    lines.shuffle(rnd);
    final picked = lines.take(count).toList();
    return picked.map((l) {
      final parts = l.split(RegExp(r'[:\-–]'));
      if (parts.length >= 2) {
        return {'prompt': parts.first.trim(), 'answer': parts.sublist(1).join('-').trim()};
      }
      final words = l.split(' ');
      final cut = min(max(2, words.length ~/ 2), words.length - 1);
      return {'prompt': '${words.take(cut).join(' ')} …', 'answer': l};
    }).toList();
  }

  Future<void> recordAttempt({required String courseId, required int total, required int correct}) async {
    final now = DateTime.now();
    _attempts.insert(0, QuizAttempt(id: 'qa-${now.microsecondsSinceEpoch}', courseId: courseId, total: total, correct: correct, createdAt: now));
    notifyListeners();
    await _persist();
  }

  void _seed() {
    final now = DateTime.now();
    _cards
      ..clear()
      ..addAll([
        Flashcard(id: 'fc1', courseId: 'c-bio', front: 'What is photosynthesis?', back: 'Conversion of light energy to chemical energy.', createdAt: now, updatedAt: now),
        Flashcard(id: 'fc2', courseId: 'c-math', front: 'Derivative of x²', back: '2x', createdAt: now, updatedAt: now),
        Flashcard(id: 'fc3', courseId: 'c-cs', front: 'HTTP 404 means', back: 'Not Found', createdAt: now, updatedAt: now),
        Flashcard(id: 'fc4', courseId: 'c-cs', front: 'Big-O of binary search', back: 'O(log n)', createdAt: now, updatedAt: now),
      ]);
    _attempts
      ..clear()
      ..addAll([
        QuizAttempt(id: 'qa1', courseId: 'c-math', total: 8, correct: 6, createdAt: now.subtract(const Duration(days: 2))),
        QuizAttempt(id: 'qa2', courseId: 'c-cs', total: 10, correct: 7, createdAt: now.subtract(const Duration(days: 1))),
      ]);
    _studySeconds = 25 * 60;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cardsKey, jsonEncode(_cards.map((c) => c.toJson()).toList()));
      await prefs.setString(_attemptsKey, jsonEncode(_attempts.map((a) => a.toJson()).toList()));
      await prefs.setInt(_studySecondsKey, _studySeconds);
    } catch (e) {
      debugPrint('Failed to persist study data: $e');
    }
  }
}
