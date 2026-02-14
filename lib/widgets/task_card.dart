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
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
                  // Close button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'How clean is it now?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Large circular wheel
                  CircularProgressWheel(
                    progress: tempLevel,
                    size: 200,
                    onProgressChanged: (value) {
                      setState(() {
                        tempLevel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Status text
                  Text(
                    getLevelText(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Confirm button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5FCBAA),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x405FCBAA),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check, color: Colors.white, size: 28),
                        onPressed: () {
                          dataService.updateCleanlinessLevel(task.id, tempLevel);
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                      ),
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        getDueText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircularProgressWheel(
                  progress: level,
                  size: 60,
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
