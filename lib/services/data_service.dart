import 'dart:js' as js;
import 'dart:js_util' as js_util;
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
    required double initialCleanliness,
  }) async {
    final frequencyDays = frequencyUnit == FrequencyUnit.weeks 
        ? frequencyValue * 7 
        : frequencyValue;

    // Calculate lastCompletedDate based on initial cleanliness level
    final totalMinutes = frequencyDays * 24 * 60;
    final minutesSinceClean = ((1.0 - initialCleanliness) * totalMinutes).round();
    
    final lastCompleted = DateTime.now().subtract(Duration(minutes: minutesSinceClean));

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      roomId: roomId,
      frequencyValue: frequencyValue,
      frequencyUnit: frequencyUnit,
      lastCompletedDate: lastCompleted,
      createdAt: DateTime.now(),
      cleanlinessLevel: initialCleanliness,
    );

    _tasks.add(task);
    await _saveTasks();
    
    // Sync to Supabase
    await _syncService.syncTask(task, _getNotificationDate(getNextDueDate(task)));
    
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
      final levelClamped = level.clamp(0.0, 1.0);

      // Match the modal preview: "days until next" = level * frequencyDays.
      // So nextDueDate = now + (level * frequencyDays). We store lastCompletedDate
      // so that lastCompletedDate + frequencyDays = now + level * frequencyDays,
      // i.e. lastCompletedDate = now - (1 - level) * frequencyDays.
      final daysToSubtract = ((1.0 - levelClamped) * task.frequencyDays).round().clamp(0, task.frequencyDays);
      final lastCompletedDate = DateTime.now().subtract(Duration(days: daysToSubtract));

      _tasks[index] = Task(
        id: task.id,
        name: task.name,
        roomId: task.roomId,
        frequencyValue: task.frequencyValue,
        frequencyUnit: task.frequencyUnit,
        lastCompletedDate: lastCompletedDate,
        createdAt: task.createdAt,
        cleanlinessLevel: levelClamped,
      );
      await _saveTasks();

      final updatedTask = _tasks[index];
      await _syncService.syncTask(updatedTask, _getNotificationDate(getNextDueDate(updatedTask)));

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
      final updatedTask = _tasks[index];
      await _syncService.syncTask(updatedTask, _getNotificationDate(getNextDueDate(updatedTask)));
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
    final promise = js.context.callMethod('requestNotificationPermission');
    final status = await js_util.promiseToFuture(promise);
    print('Notification permission status: $status');
    
    if (status == 'granted') {
      await setupBackgroundPush();
    }
    notifyListeners();
  }

  String getNotificationPermission() {
    try {
      return js.context.callMethod('getNotificationPermission');
    } catch (e) {
      return 'unsupported';
    }
  }

  Future<void> setupBackgroundPush() async {
    // VAPID public key: set via --dart-define=VAPID_PUBLIC_KEY=your_base64_key at build time,
    // or replace the default below. Must match the key pair used by the Netlify send-due-push function.
    final vapidPublicKey = String.fromEnvironment(
      'VAPID_PUBLIC_KEY',
      defaultValue: 'YOUR_VAPID_PUBLIC_KEY_HERE',
    );

    if (vapidPublicKey == 'YOUR_VAPID_PUBLIC_KEY_HERE') {
      print('WARNING: VAPID Public Key is not set. Background push notifications will not work.');
    }

    try {
      final promise = js.context.callMethod('subscribeToPush', [vapidPublicKey]);
      final subscription = await js_util.promiseToFuture(promise);
      if (subscription != null) {
        await _syncService.saveSubscription(subscription);
      }
    } catch (e) {
      print('Error setting up background push: $e');
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

  /// Helper to ensure notifications are scheduled for 9 AM local time
  DateTime? _getNotificationDate(DateTime? dueDate) {
    if (dueDate == null) return null;
    
    // Create a new DateTime for the same day but at 9:00 AM
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, // 9 AM
      0, // 0 minutes
    );
  }
}
