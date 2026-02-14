import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/database/database.dart';
import 'package:cleaning_tracker/services/task_service.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskService = context.read<TaskService>();
    final status = taskService.getTaskStatus(task);
    final nextDue = taskService.getNextDueDate(task);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case TaskStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = 'Overdue';
        break;
      case TaskStatus.dueSoon:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Due Soon';
        break;
      case TaskStatus.upcoming:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Upcoming';
        break;
      case TaskStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
    }

    return ListTile(
      leading: Icon(statusIcon, color: statusColor),
      title: Text(task.name),
      subtitle: nextDue != null
          ? Text(
              'Next due: ${DateFormat.yMMMd().format(nextDue)} ($statusText)',
              style: TextStyle(color: statusColor),
            )
          : const Text('Never completed'),
      trailing: Checkbox.adaptive(
        value: false,
        onChanged: (value) async {
          if (value == true) {
            await taskService.completeTask(task.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${task.name} completed!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
