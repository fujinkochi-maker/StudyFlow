import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    this.folderColorValue,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? folderColorValue;

  Color? get folderColor => folderColorValue == null ? null : Color(folderColorValue!);
  
  Course copyWith({String? name, int? iconCodePoint, int? folderColorValue, bool clearColor = false, DateTime? updatedAt}) {
    return Course(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      folderColorValue: clearColor ? null : (folderColorValue ?? this.folderColorValue),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      if (folderColorValue != null) 'folderColorValue': folderColorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Course? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final name = json['name'];
      final icon = json['iconCodePoint'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];
      if (id is! String || name is! String || icon is! int || createdAt is! String || updatedAt is! String) return null;
      return Course(
        id: id,
        name: name,
        iconCodePoint: icon,
        folderColorValue: json['folderColorValue'] as int?,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
    } catch (_) {
      return null;
    }
  }
}