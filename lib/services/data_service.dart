import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleaning_tracker/models/models.dart';

enum TaskStatus {
  overdue,
  dueSoon,
  upcoming,
  completed,
}

class DataService extends ChangeNotifier {
  static const _roomsKey = 'rooms';
  static const _tasksKey = 'tasks';

  List<Room> _rooms = [];
  List<Task> _tasks = [];

  List<Room> get rooms => _rooms;
  List<Task> get tasks => _tasks;

  DataService() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load rooms
    final roomsJson = prefs.getString(_roomsKey);
    if (roomsJson != null) {
      final List decoded = jsonDecode(roomsJson);
      _rooms = decoded.map((json) => Room.fromJson(json)).toList();
    }

    // Load tasks
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson != null) {
      final List decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((json) => Task.fromJson(json)).toList();
    }

    notifyListeners();
  }

  Future<void> _saveRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_rooms.map((r) => r.toJson()).toList());
    await prefs.setString(_roomsKey, json);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, json);
  }

  // Room operations
  Future<void> addRoom(String name, {String icon = '🏠', String color = '#2196F3'}) async {
    final room = Room(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    );
    _rooms.add(room);
    await _saveRooms();
    notifyListeners();
  }

  Future<void> deleteRoom(String roomId) async {
    _rooms.removeWhere((r) => r.id == roomId);
    _tasks.removeWhere((t) => t.roomId == roomId);
    await _saveRooms();
    await _saveTasks();
    notifyListeners();
  }

  // Task operations
  Future<void> addTask({
    required String name,
    required String roomId,
    required int frequencyDays,
    required bool justCleaned,
  }) async {
    final lastCompleted = justCleaned
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: frequencyDays));

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      roomId: roomId,
      frequencyDays: frequencyDays,
      lastCompletedDate: lastCompleted,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = Task(
        id: task.id,
        name: task.name,
        roomId: task.roomId,
        frequencyDays: task.frequencyDays,
        lastCompletedDate: DateTime.now(),
        createdAt: task.createdAt,
        cleanlinessLevel: 1.0, // Fully clean
      );
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> updateCleanlinessLevel(String taskId, double level) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = Task(
        id: task.id,
        name: task.name,
        roomId: task.roomId,
        frequencyDays: task.frequencyDays,
        lastCompletedDate: task.lastCompletedDate,
        createdAt: task.createdAt,
        cleanlinessLevel: level.clamp(0.0, 1.0),
      );
      await _saveTasks();
      notifyListeners();
    }
  }

  List<Task> getTasksForRoom(String roomId) {
    return _tasks.where((t) => t.roomId == roomId).toList();
  }

  // Calculate cleanliness decay over time
  double getCalculatedCleanlinessLevel(Task task) {
    if (task.lastCompletedDate == null) {
      return 0.0; // Never cleaned
    }

    final daysSinceClean = DateTime.now().difference(task.lastCompletedDate!).inDays;
    final decayRate = 1.0 / task.frequencyDays; // Decay to 0 over frequency period
    final calculatedLevel = (task.cleanlinessLevel - (daysSinceClean * decayRate)).clamp(0.0, 1.0);
    
    return calculatedLevel;
  }

  // Task status calculation based on cleanliness level
  TaskStatus getTaskStatus(Task task) {
    final level = getCalculatedCleanlinessLevel(task);
    
    if (level <= 0.2) {
      return TaskStatus.overdue;
    } else if (level <= 0.5) {
      return TaskStatus.dueSoon;
    } else {
      return TaskStatus.upcoming;
    }
  }

  DateTime? getNextDueDate(Task task) {
    if (task.lastCompletedDate == null) return null;
    return task.lastCompletedDate!.add(Duration(days: task.frequencyDays));
  }
}
