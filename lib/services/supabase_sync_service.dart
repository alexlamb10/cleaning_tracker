import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseSyncService {
  // Removed: duplicate supabaseUrl / supabaseKey constants (never used — init is in main.dart)

  Future<void> syncTask(Task task, DateTime? nextDueDate) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('push_tasks').upsert(
        {
          'task_id': task.id,
          'task_name': task.name,
          'next_due_date': nextDueDate?.toIso8601String(),
        },
        onConflict: 'task_id',
      );
      debugPrint('Synced task to Supabase: ${task.name}');
    } catch (e) {
      debugPrint('Error syncing task to Supabase: $e');
    }
  }

  Future<void> removeTask(String taskId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('push_tasks').delete().eq('task_id', taskId);
      debugPrint('Removed task from Supabase: $taskId');
    } catch (e) {
      debugPrint('Error removing task from Supabase: $e');
    }
  }

  Future<void> saveSubscription(String subscriptionJson) async {
    try {
      final supabase = Supabase.instance.client;
      // Fixed: was .insert() which duplicated rows on every permission grant.
      // Now upserts keyed on endpoint so each device has exactly one row.
      final endpoint =
          (jsonDecode(subscriptionJson) as Map<String, dynamic>)['endpoint']
              as String;
      await supabase.from('push_subscriptions').upsert(
        {
          'endpoint': endpoint,
          'subscription': subscriptionJson,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'endpoint',
      );
      debugPrint('Saved push subscription to Supabase');
    } catch (e) {
      debugPrint('Error saving push subscription: $e');
    }
  }
}