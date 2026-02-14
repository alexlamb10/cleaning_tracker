import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Room {
  final String id;
  final String name;
  final String icon;
  final String color;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        color: json['color'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Task {
  final String id;
  final String name;
  final String roomId;
  final int frequencyDays;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final double cleanlinessLevel; // 0.0 = dirty, 1.0 = perfectly clean

  Task({
    required this.id,
    required this.name,
    required this.roomId,
    required this.frequencyDays,
    this.lastCompletedDate,
    required this.createdAt,
    this.cleanlinessLevel = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roomId': roomId,
        'frequencyDays': frequencyDays,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'cleanlinessLevel': cleanlinessLevel,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        name: json['name'],
        roomId: json['roomId'],
        frequencyDays: json['frequencyDays'],
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        cleanlinessLevel: json['cleanlinessLevel'] ?? 1.0,
      );
}
