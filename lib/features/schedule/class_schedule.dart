// ─────────────────────────────────────────────────────────────────────────────
// Class Schedule Model
// ─────────────────────────────────────────────────────────────────────────────

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  String get fullName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  static DayOfWeek fromDateTime(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return DayOfWeek.monday;
      case DateTime.tuesday:
        return DayOfWeek.tuesday;
      case DateTime.wednesday:
        return DayOfWeek.wednesday;
      case DateTime.thursday:
        return DayOfWeek.thursday;
      case DateTime.friday:
        return DayOfWeek.friday;
      case DateTime.saturday:
        return DayOfWeek.saturday;
      case DateTime.sunday:
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }
}

class ClassSchedule {
  final String id;
  final String courseName;
  final String? courseCode;
  final DayOfWeek dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;
  final String? room;
  final String? building;
  final String? professor;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassSchedule({
    required this.id,
    required this.courseName,
    this.courseCode,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.building,
    this.professor,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  ClassSchedule copyWith({
    String? id,
    String? courseName,
    String? courseCode,
    DayOfWeek? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
    String? room,
    String? building,
    String? professor,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      building: building ?? this.building,
      professor: professor ?? this.professor,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'courseCode': courseCode,
      'dayOfWeek': dayOfWeek.index,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'room': room,
      'building': building,
      'professor': professor,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String?,
      dayOfWeek: DayOfWeek.values[json['dayOfWeek'] as int],
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      room: json['room'] as String?,
      building: json['building'] as String?,
      professor: json['professor'] as String?,
      colorValue: json['colorValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String get timeRange {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool conflictsWith(ClassSchedule other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    
    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = endTime.hour * 60 + endTime.minute;
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = other.endTime.hour * 60 + other.endTime.minute;
    
    return (thisStart < otherEnd && thisEnd > otherStart);
  }

  Duration get duration {
    final start = Duration(hours: startTime.hour, minutes: startTime.minute);
    final end = Duration(hours: endTime.hour, minutes: endTime.minute);
    return end - start;
  }
}
