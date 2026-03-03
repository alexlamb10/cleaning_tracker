import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncTask(Task task, DateTime? nextDueDate) async {
    try {
      await _firestore.collection('push_tasks').doc(task.id).set({
        'task_id': task.id,
        'task_name': task.name,
        'next_due_date': nextDueDate?.toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Synced task to Firestore: ${task.name}');
    } catch (e) {
      debugPrint('Error syncing task to Firestore: $e');
    }
  }

  Future<void> removeTask(String taskId) async {
    try {
      await _firestore.collection('push_tasks').doc(taskId).delete();
      debugPrint('Removed task from Firestore: $taskId');
    } catch (e) {
      debugPrint('Error removing task from Firestore: $e');
    }
  }

  Future<void> saveFcmToken(String token) async {
    try {
      await _firestore.collection('fcm_tokens').doc(token).set({
        'token': token,
        'last_updated': FieldValue.serverTimestamp(),
      });
      debugPrint('Saved FCM token to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }
}
