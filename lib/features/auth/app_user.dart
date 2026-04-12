import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({required this.id, required this.displayName, required this.email, required this.createdAt, required this.updatedAt, this.level = 1, this.streakDays = 0});

  final String id;
  final String displayName;
  final String email;
  final int level;
  final int streakDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({String? displayName, String? email, int? level, int? streakDays, DateTime? updatedAt}) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'level': level,
      'streakDays': streakDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static AppUser? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final displayName = json['displayName'];
      final email = json['email'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];
      if (id is! String || displayName is! String || email is! String || createdAt is! String || updatedAt is! String) return null;
      return AppUser(
        id: id,
        displayName: displayName,
        email: email,
        level: (json['level'] is int) ? json['level'] as int : 1,
        streakDays: (json['streakDays'] is int) ? json['streakDays'] as int : 0,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
    } catch (_) {
      return null;
    }
  }
}
