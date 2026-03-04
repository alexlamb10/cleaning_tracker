import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/firestore_service.dart';
import 'package:cleaning_tracker/services/notification_service.dart'
    if (dart.library.js) 'package:cleaning_tracker/services/notification_web.dart';

class DataService extends ChangeNotifier {
  static const _roomsKey = 'rooms';
  static const _tasksKey = 'tasks';
  static const _uuid = Uuid();

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Room> _rooms = [];
  List<Task> _tasks = [];
  String? _currentUserId;

  List<Room> get rooms => _rooms;
  List<Task> get tasks => _tasks;
  String? get currentUserId => _currentUserId;

  DataService() {
    _initForegroundMessaging();
  }

  void _initForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
  }

  Future<void> _initializeAuth() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      _currentUserId = _auth.currentUser?.uid;
      debugPrint('Authenticated as: $_currentUserId');
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
    }
  }

  /// Public so main() can await it before runApp(), preventing empty-list flash.
  Future<void> loadData() async {
    await _initializeAuth();

    final prefs = await SharedPreferences.getInstance();

    final roomsJson = prefs.getString(_roomsKey);
    if (roomsJson != null) {
      final List decoded = jsonDecode(roomsJson);
      _rooms = decoded.map((json) => Room.fromJson(json)).toList();
    }

    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson != null) {
      final List decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((json) => Task.fromJson(json)).toList();

      // Silent Migration: "Stamp" local tasks with the current UID if missing.
      bool migrated = false;
      if (_currentUserId != null) {
        for (int i = 0; i < _tasks.length; i++) {
          final task = _tasks[i];
          if (task.creatorUid == null) {
            _tasks[i] = Task(
              id: task.id,
              name: task.name,
              roomId: task.roomId,
              frequencyValue: task.frequencyValue,
              frequencyUnit: task.frequencyUnit,
              lastCompletedDate: task.lastCompletedDate,
              createdAt: task.createdAt,
              cleanlinessLevel: task.cleanlinessLevel,
              creatorUid: _currentUserId,
            );
            migrated = true;
            // Immediate sync to Firestore for each migrated task.
            await _firestoreService.syncTask(
                _tasks[i], _getNotificationDate(getNextDueDate(_tasks[i])), _currentUserId);
          }
        }
      }
      if (migrated) {
        await _saveTasks();
      }
    }
    notifyListeners();

    // Register token with the UID.
    final token = await NotificationService.getToken('BD9KRxBRpbVGbHeyQu-BlCc74SGzoZCm9vUsy3ukFCNxaFhabmf9XFIV3YkWRJ1sn7XBqpky2snbC2kwgQiQKoY');
    if (token != null && _currentUserId != null) {
      await _firestoreService.saveFcmToken(token, _currentUserId);
    }
  }

  Future<void> _saveRooms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomsKey, jsonEncode(_rooms.map((r) => r.toJson()).toList()));
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  // ── Room operations ────────────────────────────────────────────────────────

  Future<void> addRoom(String name) async {
    final room = Room(
      id: _uuid.v4(), // Fixed: was DateTime.now().millisecondsSinceEpoch (collision risk)
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

  // ── Task operations ────────────────────────────────────────────────────────

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

    final totalMinutes = frequencyDays * 24 * 60;
    final minutesSinceClean = ((1.0 - initialCleanliness) * totalMinutes).round();
    final lastCompleted = DateTime.now().subtract(Duration(minutes: minutesSinceClean));

    final task = Task(
      id: _uuid.v4(), // Fixed: was DateTime.now().millisecondsSinceEpoch (collision risk)
      name: name,
      roomId: roomId,
      frequencyValue: frequencyValue,
      frequencyUnit: frequencyUnit,
      lastCompletedDate: lastCompleted,
      createdAt: DateTime.now(),
      cleanlinessLevel: 1.0, // Anchor at 1.0; decay is calculated purely from lastCompletedDate
      creatorUid: _currentUserId,
    );

    _tasks.add(task);
    await _saveTasks();
    await _firestoreService.syncTask(
        task, _getNotificationDate(getNextDueDate(task)), _currentUserId);
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
        cleanlinessLevel: 1.0,
        creatorUid: _currentUserId,
      );
      await _saveTasks();
      final updatedTask = _tasks[index];
      await _firestoreService.syncTask(updatedTask,
          _getNotificationDate(getNextDueDate(updatedTask)), _currentUserId);
      notifyListeners();
    }
  }

  Future<void> updateCleanlinessLevel(String taskId, double level) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final levelClamped = level.clamp(0.0, 1.0);
      final totalMinutes = task.frequencyDays * 24 * 60;
      final minutesSinceClean = ((1.0 - levelClamped) * totalMinutes).round();
      final lastCompletedDate =
          DateTime.now().subtract(Duration(minutes: minutesSinceClean));

      _tasks[index] = Task(
        id: task.id,
        name: task.name,
        roomId: task.roomId,
        frequencyValue: task.frequencyValue,
        frequencyUnit: task.frequencyUnit,
        lastCompletedDate: lastCompletedDate,
        createdAt: task.createdAt,
        cleanlinessLevel: 1.0, // Anchor at 1.0; decay is calculated purely from lastCompletedDate
        creatorUid: _currentUserId,
      );
      await _saveTasks();

      final updatedTask = _tasks[index];
      await _firestoreService.syncTask(updatedTask,
          _getNotificationDate(getNextDueDate(updatedTask)), _currentUserId);
      notifyListeners();
    }
  }

  Future<void> updateTaskFrequency(
      String taskId, int newValue, FrequencyUnit newUnit) async {
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
        creatorUid: _currentUserId,
      );
      await _saveTasks();
      final updatedTask = _tasks[index];
      await _firestoreService.syncTask(updatedTask,
          _getNotificationDate(getNextDueDate(updatedTask)), _currentUserId);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    await _firestoreService.removeTask(taskId);
    notifyListeners();
  }

  List<Task> getTasksForRoom(String roomId) =>
      _tasks.where((t) => t.roomId == roomId).toList();

  // ── Notification helpers ───────────────────────────────────────────────────

  Future<void> requestNotificationPermission() async {
    final status = await NotificationService.requestPermission();
    debugPrint('Notification permission status: $status');

    if (status == 'granted') {
      await setupBackgroundPush();
    }
    notifyListeners();
  }

  String getNotificationPermission() =>
      NotificationService.getPermission();

  Future<void> setupBackgroundPush() async {
    // BD9KRxBRpbVGbHeyQu-BlCc74SGzoZCm9vUsy3ukFCNxaFhabmf9XFIV3YkWRJ1sn7XBqpky2snbC2kwgQiQKoY
    const vapidPublicKey = 'BD9KRxBRpbVGbHeyQu-BlCc74SGzoZCm9vUsy3ukFCNxaFhabmf9XFIV3YkWRJ1sn7XBqpky2snbC2kwgQiQKoY';

    try {
      final token = await NotificationService.subscribeToPush(vapidPublicKey);
      if (token != null) {
        await _firestoreService.saveFcmToken(token, _currentUserId);
      }
    } catch (e) {
      debugPrint('Error setting up background push: $e');
    }
  }

  // ── Cleanliness / status calculations ─────────────────────────────────────

  double getCalculatedCleanlinessLevel(Task task) {
    if (task.lastCompletedDate == null) return 0.0;

    final minutesSinceClean =
        DateTime.now().difference(task.lastCompletedDate!).inMinutes;
    final totalMinutesInFrequency = task.frequencyDays * 24 * 60;

    if (totalMinutesInFrequency <= 0) return 1.0;

    final decayAmount = minutesSinceClean / totalMinutesInFrequency;
    return (1.0 - decayAmount).clamp(0.0, 1.0);
  }

  int? getDaysUntilNextCleaning(Task task) {
    if (task.lastCompletedDate == null) return null;
    final daysSinceClean =
        DateTime.now().difference(task.lastCompletedDate!).inDays;
    final daysRemaining = task.frequencyDays - daysSinceClean;
    return daysRemaining > 0 ? daysRemaining : 0;
  }

  TaskStatus getTaskStatus(Task task) {
    final level = getCalculatedCleanlinessLevel(task);
    if (level <= 0.2) return TaskStatus.overdue;
    if (level <= 0.5) return TaskStatus.dueSoon;
    return TaskStatus.upcoming;
  }

  DateTime? getNextDueDate(Task task) {
    if (task.lastCompletedDate == null) return null;
    return task.lastCompletedDate!.add(Duration(days: task.frequencyDays));
  }

  DateTime? _getNotificationDate(DateTime? dueDate) {
    if (dueDate == null) return null;
    // Create local 9 AM, then convert to UTC for the server. 
    // This allows the server to compare "due date" (UTC) vs "now" (UTC) 
    // and trigger at exactly the user's local 9 AM.
    return DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0).toUtc();
  }
}