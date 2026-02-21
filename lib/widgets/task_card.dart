import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/widgets/circular_progress_wheel.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  void _showTaskDetailDialog(BuildContext context) {
    final dataService = context.read<DataService>();
    // Initialize tempLevel from the current "days until next" to match what the card shows
    // This ensures the modal opens with the same value the user sees on the card
    final daysUntil = dataService.getDaysUntilNextCleaning(task);
    double tempLevel = daysUntil != null && daysUntil > 0 && task.frequencyDays > 0
        ? (daysUntil / task.frequencyDays).clamp(0.0, 1.0)
        : dataService.getCalculatedCleanlinessLevel(task);
    int tempFrequencyValue = task.frequencyValue;
    FrequencyUnit tempFrequencyUnit = task.frequencyUnit;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 380),
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
                  // Header with close and delete buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      Container(
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
                      // Delete button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: const Text('Are you sure you want to delete this task?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await dataService.deleteTask(task.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Task name
                  Text(
                    task.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Live preview: days until next cleaning based on current dial + frequency
                  // This updates in real-time as the user drags the wheel or changes frequency
                  // tempLevel (0.0-1.0) represents how much of the cleaning cycle remains
                  Builder(
                    builder: (context) {
                      // Recalculate frequency days from current temp values
                      final currentFreqDays = tempFrequencyUnit == FrequencyUnit.weeks
                          ? tempFrequencyValue * 7
                          : tempFrequencyValue;
                      
                      // Calculate preview: tempLevel * frequencyDays = days remaining
                      // Use ceil to ensure we show at least 1 day if there's any time left
                      final daysRemaining = tempLevel * currentFreqDays;
                      final previewDays = daysRemaining <= 0 
                          ? 0 
                          : (daysRemaining < 1 ? 1 : daysRemaining.ceil());
                      
                      final canShow = tempLevel > 0 && currentFreqDays > 0;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Text(
                              canShow
                                  ? (previewDays == 0
                                      ? 'Next cleaning: today'
                                      : 'Next cleaning: ${previewDays == 1 ? '1 day' : '$previewDays days'} from now')
                                  : 'Next cleaning: not set',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Frequency selector
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Frequency',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Minus button
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () {
                                  if (tempFrequencyValue > 1) {
                                    setState(() {
                                      tempFrequencyValue--;
                                    });
                                  }
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Number display
                            SizedBox(
                              width: 50,
                              child: Text(
                                '$tempFrequencyValue',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Plus button
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  setState(() {
                                    tempFrequencyValue++;
                                  });
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Unit selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => tempFrequencyUnit = FrequencyUnit.days),
                              child: Text(
                                tempFrequencyValue == 1 ? 'Day' : 'Days',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: tempFrequencyUnit == FrequencyUnit.days ? const Color(0xFF4B5244) : Colors.grey, // Thicket
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('|', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() => tempFrequencyUnit = FrequencyUnit.weeks),
                              child: Text(
                                tempFrequencyValue == 1 ? 'Week' : 'Weeks',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: tempFrequencyUnit == FrequencyUnit.weeks ? const Color(0xFF4B5244) : Colors.grey, // Thicket
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cleanliness section
                  const Text(
                    'How clean is it now?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Large circular wheel
                  CircularProgressWheel(
                    progress: tempLevel,
                    size: 180,
                    onProgressChanged: (value) {
                      setState(() {
                        tempLevel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Status text
                  Text(
                    getLevelText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Confirm button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4B5244), // Thicket
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x404B5244), // Thicket low opacity
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check, color: Colors.white, size: 28),
                        onPressed: () async {
                          // Update frequency if changed
                          if (tempFrequencyValue != task.frequencyValue || tempFrequencyUnit != task.frequencyUnit) {
                            await dataService.updateTaskFrequency(task.id, tempFrequencyValue, tempFrequencyUnit);
                          }
                          // Update cleanliness level
                          await dataService.updateCleanlinessLevel(task.id, tempLevel);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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
    final dataService = context.watch<DataService>();
    // Always resolve the current task from DataService so the list shows updated
    // due date / days remaining after the user saves from the edit modal
    final idx = dataService.tasks.indexWhere((t) => t.id == task.id);
    final currentTask = idx >= 0 ? dataService.tasks[idx] : task;

    final cleanlinessLevel = dataService.getCalculatedCleanlinessLevel(currentTask);
    final status = dataService.getTaskStatus(currentTask);

    Color getStatusColor() {
      switch (status) {
        case TaskStatus.overdue:
          return const Color(0xFFFF6B6B);
        case TaskStatus.dueSoon:
          return const Color(0xFF8C7D6E); // Silt (Brown/Orange-ish)
        case TaskStatus.upcoming:
          return const Color(0xFF4B5244); // Thicket (Green-ish)
      }
    }

    String getDueDateText() {
      final nextDue = dataService.getNextDueDate(currentTask);
      if (nextDue == null) return 'Never cleaned';
      
      final daysUntil = dataService.getDaysUntilNextCleaning(currentTask);
      if (daysUntil == null) return 'Never cleaned';
      
      if (daysUntil <= 0) {
        final daysOverdue = -daysUntil;
        return daysOverdue == 0 ? 'Due today' : 'Due ${daysOverdue} ${daysOverdue == 1 ? 'day' : 'days'} ago';
      } else if (daysUntil == 1) {
        return 'Due tomorrow';
      } else {
        return 'Due in $daysUntil days';
      }
    }

    return GestureDetector(
      onTap: () => _showTaskDetailDialog(context),
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
                    currentTask.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getDueDateText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircularProgressWheel(
              progress: cleanlinessLevel,
              size: 60,
              color: getStatusColor(),
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }
}
