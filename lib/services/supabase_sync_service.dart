import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseSyncService {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    // Note: Initialization is usually done in main.dart
    // Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }

  Future<void> syncTask(Task task, DateTime? nextDueDate) async {
    try {
      final supabase = Supabase.instance.client;
      
      final data = {
        'task_id': task.id,
        'task_name': task.name,
        'next_due_date': nextDueDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('push_tasks')
          .upsert(data, onConflict: 'task_id');
          
      print('Synced task to Supabase: ${task.name}');
    } catch (e) {
      print('Error syncing task to Supabase: $e');
    }
  }

  Future<void> removeTask(String taskId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('push_tasks')
          .delete()
          .eq('task_id', taskId);
      print('Removed task from Supabase: $taskId');
    } catch (e) {
      print('Error removing task from Supabase: $e');
    }
  }

  Future<void> saveSubscription(String subscriptionJson) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('push_subscriptions')
          .insert({
            'subscription': subscriptionJson,
            'updated_at': DateTime.now().toIso8601String(),
          });
      print('Saved push subscription to Supabase');
    } catch (e) {
      print('Error saving push subscription: $e');
    }
  }
}
