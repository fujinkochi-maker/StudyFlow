import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/theme.dart';

class AppThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_v1';

  ThemeMode _themeMode = ThemeMode.system;
  String _presetId = AppThemePresets.jadePebble.id;
  Color? _customSeed;

  ThemeMode get themeMode => _themeMode;
  String get presetId => _presetId;
  Color get seedColor => _customSeed ?? AppThemePresets.byId(_presetId).seed;
  bool get isUsingCustom => _customSeed != null;

  ThemeData get lightTheme => buildAppTheme(brightness: Brightness.light, seedColor: seedColor);
  ThemeData get darkTheme => buildAppTheme(brightness: Brightness.dark, seedColor: seedColor);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) {
        notifyListeners();
        return;
      }
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return;
      _presetId = (map['presetId'] as String?) ?? _presetId;
      _themeMode = ThemeMode.values[(map['themeMode'] as int?) ?? _themeMode.index];
      final customSeed = map['customSeed'] as int?;
      _customSeed = customSeed == null ? null : Color(customSeed);
    } catch (e) {
      debugPrint('Failed to load theme: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'presetId': _presetId,
        'themeMode': _themeMode.index,
        'customSeed': _customSeed?.value,
      };
      await prefs.setString(_prefsKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('Failed to persist theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setPreset(String presetId) async {
    _presetId = presetId;
    _customSeed = null;
    notifyListeners();
    await _persist();
  }

  Future<void> setCustomSeed(Color color) async {
    _customSeed = color;
    notifyListeners();
    await _persist();
  }

  Future<void> clearCustomSeed() async {
    _customSeed = null;
    notifyListeners();
    await _persist();
  }
}
