import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the customisable Student ID card data locally.
class StudentIdService extends ChangeNotifier {
  static const _key = 'student_id_v1';

  String _name = 'YOUR NAME';
  String _birthday = '01-01-2000';
  String _school = 'YOUR SCHOOL';
  String _yearLevel = '1';
  /// Base-64 encoded JPEG/PNG bytes, or null if no photo uploaded.
  String? _photoBase64;
  /// Background mode: 'color' or 'image'
  String _bgMode = 'color';
  /// Background color value (ARGB int)
  int _bgColorValue = 0xFFFFFFFF;
  /// Base-64 encoded background image bytes, or null
  String? _bgImageBase64;
  /// Logo mode: 'text', 'asset', or 'custom'
  String _logoMode = 'text';
  /// Path to premade logo asset (e.g., 'assets/logos/logo1.png')
  String? _logoAssetPath;
  /// Base-64 encoded custom logo image bytes, or null
  String? _logoBase64;

  bool _loaded = false;

  bool get loaded => _loaded;
  String get name => _name;
  String get birthday => _birthday;
  String get school => _school;
  String get yearLevel => _yearLevel;
  String? get photoBase64 => _photoBase64;
  String get bgMode => _bgMode;
  Color get bgColor => Color(_bgColorValue);
  String? get bgImageBase64 => _bgImageBase64;
  String get logoMode => _logoMode;
  String? get logoAssetPath => _logoAssetPath;
  String? get logoBase64 => _logoBase64;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _name = (map['name'] as String?) ?? _name;
        _birthday = (map['birthday'] as String?) ?? _birthday;
        _school = (map['school'] as String?) ?? _school;
        _yearLevel = (map['yearLevel'] as String?) ?? _yearLevel;
        _photoBase64 = map['photoBase64'] as String?;
        _bgMode = (map['bgMode'] as String?) ?? _bgMode;
        _bgColorValue = (map['bgColorValue'] as int?) ?? _bgColorValue;
        _bgImageBase64 = map['bgImageBase64'] as String?;
        _logoMode = (map['logoMode'] as String?) ?? _logoMode;
        _logoAssetPath = map['logoAssetPath'] as String?;
        _logoBase64 = map['logoBase64'] as String?;
      }
    } catch (e) {
      debugPrint('StudentIdService.load error: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> update({
    String? name,
    String? birthday,
    String? school,
    String? yearLevel,
    String? photoBase64,
    bool clearPhoto = false,
    String? bgMode,
    Color? bgColor,
    String? bgImageBase64,
    bool clearBgImage = false,
    String? logoMode,
    String? logoAssetPath,
    String? logoBase64,
    bool clearLogo = false,
  }) async {
    if (name != null) _name = name.trim().isEmpty ? _name : name.trim();
    if (birthday != null) _birthday = birthday.trim().isEmpty ? _birthday : birthday.trim();
    if (school != null) _school = school.trim().isEmpty ? _school : school.trim();
    if (yearLevel != null) _yearLevel = yearLevel.trim().isEmpty ? _yearLevel : yearLevel.trim();
    if (clearPhoto) {
      _photoBase64 = null;
    } else if (photoBase64 != null) {
      _photoBase64 = photoBase64;
    }
    if (bgMode != null) _bgMode = bgMode;
    if (bgColor != null) _bgColorValue = bgColor.value;
    if (clearBgImage) {
      _bgImageBase64 = null;
    } else if (bgImageBase64 != null) {
      _bgImageBase64 = bgImageBase64;
    }
    if (logoMode != null) _logoMode = logoMode;
    if (logoAssetPath != null) _logoAssetPath = logoAssetPath;
    if (clearLogo) {
      _logoBase64 = null;
      _logoAssetPath = null;
      _logoMode = 'text';
    } else if (logoBase64 != null) {
      _logoBase64 = logoBase64;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'name': _name,
          'birthday': _birthday,
          'school': _school,
          'yearLevel': _yearLevel,
          'photoBase64': _photoBase64,
          'bgMode': _bgMode,
          'bgColorValue': _bgColorValue,
          'bgImageBase64': _bgImageBase64,
          'logoMode': _logoMode,
          'logoAssetPath': _logoAssetPath,
          'logoBase64': _logoBase64,
        }),
      );
    } catch (e) {
      debugPrint('StudentIdService._persist error: $e');
    }
  }
}