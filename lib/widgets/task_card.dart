import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/widgets/circular_progress_wheel.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  void _showCleanlinessDialog(BuildContext context) {
    final dataService = context.read<DataService>();
    double tempLevel = dataService.getCalculatedCleanlinessLevel(task);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 300),
          child: StatefulBuilder(
            builder: (context, setState) {
              String getLevelText() {
                if (tempLevel >= 0.9) return "Spotless!";
                if (tempLevel >= 0.7) return "Pretty clean";
                if (tempLevel >= 0.5) return "It's ok";
                if (tempLevel >= 0.3) return "Getting dirty";
                return "Needs cleaning";
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      const Text(
                        'How clean is it now?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CircularProgressWheel(
                    progress: tempLevel,
                    size: 180,
                    onProgressChanged: (value) {
                      setState(() {
                        tempLevel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getLevelText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      onPressed: () {
                        dataService.updateCleanlinessLevel(task.id, tempLevel);
                        Navigator.pop(context);
                      },
                      backgroundColor: const Color(0xFF5FCBAA),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final level = dataService.getCalculatedCleanlinessLevel(task);
        final nextDue = dataService.getNextDueDate(task);
        
        String getDueText() {
          if (nextDue == null) return 'Never cleaned';
          final daysUntil = nextDue.difference(DateTime.now()).inDays;
          if (daysUntil < 0) return 'Overdue';
          if (daysUntil == 0) return 'Due today';
          if (daysUntil == 1) return 'Due tomorrow';
          return 'Due in $daysUntil days';
        }

        return GestureDetector(
          onTap: () => _showCleanlinessDialog(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getDueText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressWheel(
                  progress: level,
                  size: 50,
                  interactive: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
