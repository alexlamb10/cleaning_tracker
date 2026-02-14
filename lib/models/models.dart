import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskStatus {
  overdue,
  dueSoon,
  upcoming,
}

class Room {
  final String id;
  final String name;
  final String color;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    this.color = 'blue',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'],
        name: json['name'],
        color: json['color'] ?? 'blue',
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum FrequencyUnit {
  days,
  weeks,
}

class Task {
  final String id;
  final String name;
  final String roomId;
  final int frequencyValue;
  final FrequencyUnit frequencyUnit;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final double cleanlinessLevel; // 0.0 = dirty, 1.0 = perfectly clean

  Task({
    required this.id,
    required this.name,
    required this.roomId,
    required this.frequencyValue,
    this.frequencyUnit = FrequencyUnit.weeks,
    this.lastCompletedDate,
    required this.createdAt,
    this.cleanlinessLevel = 1.0,
  });

  int get frequencyDays => frequencyUnit == FrequencyUnit.weeks 
      ? frequencyValue * 7 
      : frequencyValue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roomId': roomId,
        'frequencyValue': frequencyValue,
        'frequencyUnit': frequencyUnit.name,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'cleanlinessLevel': cleanlinessLevel,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        name: json['name'],
        roomId: json['roomId'],
        frequencyValue: json['frequencyValue'] ?? json['frequencyDays'] ?? 1,
        frequencyUnit: json['frequencyUnit'] != null 
            ? FrequencyUnit.values.byName(json['frequencyUnit'])
            : (json['frequencyDays'] != null ? FrequencyUnit.days : FrequencyUnit.weeks),
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        cleanlinessLevel: json['cleanlinessLevel'] ?? 1.0,
      );
}
