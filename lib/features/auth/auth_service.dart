import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/features/auth/app_user.dart';

/// Local-only authentication.
///
/// This is NOT secure (credentials live in SharedPreferences) and is meant only
/// for prototypes until Firebase/Supabase is connected via Dreamflow panels.
class AuthService extends ChangeNotifier {
  static const _usersKey = 'auth_users_v1';
  static const _credsKey = 'auth_creds_v1';
  static const _currentUserKey = 'auth_current_user_v1';

  final List<AppUser> _users = [];
  final Map<String, String> _emailToPassword = {};
  bool _loaded = false;
  String? _currentUserId;

  bool get loaded => _loaded;
  bool get isAuthed => _currentUserId != null;
  AppUser? get currentUser => _users.cast<AppUser?>().firstWhere((u) => u?.id == _currentUserId, orElse: () => null);
  List<AppUser> get users => List.unmodifiable(_users);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString(_currentUserKey);

      _users.clear();
      final rawUsers = prefs.getString(_usersKey);
      if (rawUsers == null) {
        final now = DateTime.now();
        final seed = AppUser(id: 'local-${now.microsecondsSinceEpoch}', displayName: 'Student', email: 'student@example.com', createdAt: now, updatedAt: now, level: 2, streakDays: 4);
        _users.add(seed);
        _emailToPassword[seed.email.toLowerCase()] = 'password';
        _currentUserId = seed.id;
        await _persist();
      } else {
        final decoded = jsonDecode(rawUsers);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final u = AppUser.fromJson(item);
              if (u != null) _users.add(u);
            }
          }
        }

        final rawCreds = prefs.getString(_credsKey);
        _emailToPassword.clear();
        if (rawCreds != null) {
          final c = jsonDecode(rawCreds);
          if (c is Map) {
            for (final entry in c.entries) {
              if (entry.key is String && entry.value is String) {
                _emailToPassword[(entry.key as String).toLowerCase()] = entry.value as String;
              }
            }
          }
        }

        if (_currentUserId != null && currentUser == null) {
          _currentUserId = _users.isEmpty ? null : _users.first.id;
          await _persist();
        }
      }
    } catch (e) {
      debugPrint('Failed to load auth: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<String?> login({required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    final stored = _emailToPassword[normalized];
    if (stored == null) return 'Account not found';
    if (stored != password) return 'Incorrect password';

    final user = _users.cast<AppUser?>().firstWhere((u) => u?.email.toLowerCase() == normalized, orElse: () => null);
    if (user == null) return 'Account data is missing';
    _currentUserId = user.id;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> signUp({required String displayName, required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) return 'Enter a valid email';
    if (password.trim().length < 4) return 'Password must be at least 4 characters';
    if (displayName.trim().isEmpty) return 'Enter your name';
    if (_emailToPassword.containsKey(normalized)) return 'Email already in use';

    final now = DateTime.now();
    final user = AppUser(id: 'local-${now.microsecondsSinceEpoch}', displayName: displayName.trim(), email: normalized, createdAt: now, updatedAt: now, level: 1, streakDays: 0);
    _users.insert(0, user);
    _emailToPassword[normalized] = password;
    _currentUserId = user.id;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUserId = null;
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName}) async {
    final u = currentUser;
    if (u == null) return;
    final next = u.copyWith(displayName: displayName?.trim().isEmpty == true ? u.displayName : displayName?.trim(), updatedAt: DateTime.now());
    final i = _users.indexWhere((x) => x.id == u.id);
    if (i == -1) return;
    _users[i] = next;
    await _persist();
    notifyListeners();
  }

  Future<void> setLevelAndStreak({int? level, int? streakDays}) async {
    final u = currentUser;
    if (u == null) return;
    final next = u.copyWith(level: level ?? u.level, streakDays: streakDays ?? u.streakDays, updatedAt: DateTime.now());
    final i = _users.indexWhere((x) => x.id == u.id);
    if (i == -1) return;
    _users[i] = next;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usersKey, jsonEncode(_users.map((u) => u.toJson()).toList()));
      await prefs.setString(_credsKey, jsonEncode(_emailToPassword));
      if (_currentUserId == null) {
        await prefs.remove(_currentUserKey);
      } else {
        await prefs.setString(_currentUserKey, _currentUserId!);
      }
    } catch (e) {
      debugPrint('Failed to persist auth: $e');
    }
  }
}
