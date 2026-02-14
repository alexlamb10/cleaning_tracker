import 'package:cleaning_tracker/database/database.dart';
import 'package:drift/drift.dart';

enum TaskStatus {
  overdue,
  dueSoon,
  upcoming,
  completed,
}

class TaskService {
  final AppDatabase _db;

  TaskService(this._db);

  // Calculate task status based on next due date
  TaskStatus getTaskStatus(Task task) {
    if (task.lastCompletedDate == null) {
      return TaskStatus.overdue; // Never completed
    }

    final nextDue = task.lastCompletedDate!.add(Duration(days: task.frequencyDays));
    final now = DateTime.now();
    final daysUntilDue = nextDue.difference(now).inDays;

    if (daysUntilDue < 0) {
      return TaskStatus.overdue;
    } else if (daysUntilDue <= 2) {
      return TaskStatus.dueSoon;
    } else {
      return TaskStatus.upcoming;
    }
  }

  // Get next due date for a task
  DateTime? getNextDueDate(Task task) {
    if (task.lastCompletedDate == null) return null;
    return task.lastCompletedDate!.add(Duration(days: task.frequencyDays));
  }

  // Add a new task with current status
  Future<int> addTask({
    required String name,
    required int roomId,
    required int frequencyDays,
    required bool justCleaned,
  }) async {
    final lastCompleted = justCleaned
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: frequencyDays));

    return await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            name: name,
            roomId: roomId,
            frequencyDays: frequencyDays,
            lastCompletedDate: Value(lastCompleted),
          ),
        );
  }

  // Complete a task (update lastCompletedDate to now)
  Future<void> completeTask(int taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        lastCompletedDate: Value(DateTime.now()),
      ),
    );
  }

  // Get all tasks for a room
  Stream<List<Task>> getTasksForRoom(int roomId) {
    return (_db.select(_db.tasks)..where((t) => t.roomId.equals(roomId))).watch();
  }

  // Get all tasks grouped by room
  Future<Map<Room, List<Task>>> getTasksByRoom() async {
    final rooms = await _db.select(_db.rooms).get();
    final tasks = await _db.select(_db.tasks).get();

    final Map<Room, List<Task>> grouped = {};
    for (final room in rooms) {
      grouped[room] = tasks.where((t) => t.roomId == room.id).toList();
    }
    return grouped;
  }

  // Room CRUD
  Future<int> addRoom(String name, {String icon = '🏠', String color = '#2196F3'}) async {
    return await _db.into(_db.rooms).insert(
          RoomsCompanion.insert(
            name: name,
            icon: Value(icon),
            color: Value(color),
          ),
        );
  }

  Stream<List<Room>> watchAllRooms() {
    return _db.select(_db.rooms).watch();
  }

  Future<void> deleteRoom(int roomId) async {
    await (_db.delete(_db.rooms)..where((r) => r.id.equals(roomId))).go();
  }
}
