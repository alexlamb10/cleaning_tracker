import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/supabase_sync_service.dart';

class DataService extends ChangeNotifier {
  static const _roomsKey = 'rooms';
  static const _tasksKey = 'tasks';

  final SupabaseSyncService _syncService = SupabaseSyncService();
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
  Future<void> addRoom(String name) async {
    final room = Room(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _rooms.add(room);
    await _saveRooms();
    notifyListeners();
  }

  Future<void> updateRoom(String roomId, String newName) async {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _rooms[index];
      _rooms[index] = Room(
        id: room.id,
        name: newName,
        color: room.color,
        createdAt: room.createdAt,
      );
      await _saveRooms();
      notifyListeners();
    }
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
    required int frequencyValue,
    required FrequencyUnit frequencyUnit,
    required bool justCleaned,
  }) async {
    final frequencyDays = frequencyUnit == FrequencyUnit.weeks 
        ? frequencyValue * 7 
        : frequencyValue;

    final lastCompleted = justCleaned
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: frequencyDays));

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      roomId: roomId,
      frequencyValue: frequencyValue,
      frequencyUnit: frequencyUnit,
      lastCompletedDate: lastCompleted,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    await _saveTasks();
    
    // Sync to Supabase
    await _syncService.syncTask(task, getNextDueDate(task));
    
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
        frequencyValue: task.frequencyValue,
        frequencyUnit: task.frequencyUnit,
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
        frequencyValue: task.frequencyValue,
        frequencyUnit: task.frequencyUnit,
        lastCompletedDate: DateTime.now(), // Manual update resets the reference time
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

  Future<void> updateTaskFrequency(String taskId, int newValue, FrequencyUnit newUnit) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = Task(
        id: task.id,
        name: task.name,
        roomId: task.roomId,
        frequencyValue: newValue,
        frequencyUnit: newUnit,
        lastCompletedDate: task.lastCompletedDate,
        createdAt: task.createdAt,
        cleanlinessLevel: task.cleanlinessLevel,
      );
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    
    // Remove from Supabase
    await _syncService.removeTask(taskId);
    
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    final status = await js.context.callMethod('requestNotificationPermission');
    print('Notification permission status: $status');
  }

  void showTestNotification() {
    js.context.callMethod('showTestNotification', ['CleanTrack Test', 'This is a local notification test! 🧼']);
  }

  Future<void> debugSubtractDays(String taskId, int days) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      if (task.lastCompletedDate != null) {
        _tasks[index] = Task(
          id: task.id,
          name: task.name,
          roomId: task.roomId,
          frequencyValue: task.frequencyValue,
          frequencyUnit: task.frequencyUnit,
          lastCompletedDate: task.lastCompletedDate!.subtract(Duration(days: days)),
          createdAt: task.createdAt,
          cleanlinessLevel: task.cleanlinessLevel,
        );
        await _saveTasks();
        notifyListeners();
      }
    }
  }

  // Calculate cleanliness decay over time
  double getCalculatedCleanlinessLevel(Task task) {
    if (task.lastCompletedDate == null) {
      return 0.0; // Never cleaned
    }

    // Use minutes for smoother decay
    final minutesSinceClean = DateTime.now().difference(task.lastCompletedDate!).inMinutes;
    final totalMinutesInFrequency = task.frequencyDays * 24 * 60;
    
    if (totalMinutesInFrequency <= 0) return 1.0;
    
    final decayAmount = minutesSinceClean / totalMinutesInFrequency;
    final calculatedLevel = (task.cleanlinessLevel - decayAmount).clamp(0.0, 1.0);
    
    return calculatedLevel;
  }

  int? getDaysUntilNextCleaning(Task task) {
    if (task.lastCompletedDate == null) return null;
    
    final difference = DateTime.now().difference(task.lastCompletedDate!);
    final daysSinceClean = difference.inDays;
    final daysRemaining = task.frequencyDays - daysSinceClean;
    
    return daysRemaining > 0 ? daysRemaining : 0;
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
