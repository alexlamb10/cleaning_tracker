import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/screens/add_task_screen.dart';
import 'package:cleaning_tracker/widgets/gradient_background.dart';
import 'package:cleaning_tracker/widgets/task_card.dart';

class RoomDetailScreen extends StatelessWidget {
  final Room room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(room.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(room.name),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // TODO: Implement edit room
              },
              child: const Text('Edit', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
        body: Consumer<DataService>(
          builder: (context, dataService, child) {
            final tasks = dataService.getTasksForRoom(room.id);

            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No tasks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTaskScreen(preselectedRoomId: room.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5FCBAA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(preselectedRoomId: room.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5FCBAA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(task: tasks[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
