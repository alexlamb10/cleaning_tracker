import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/screens/add_room_screen.dart';
import 'package:cleaning_tracker/screens/add_task_screen.dart';
import 'package:cleaning_tracker/widgets/task_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CleanTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddRoomScreen()),
              );
            },
            tooltip: 'Add Room',
          ),
        ],
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          if (dataService.rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No rooms yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddRoomScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Room'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: dataService.rooms.length,
            itemBuilder: (context, index) {
              final room = dataService.rooms[index];
              return _RoomSection(room: room);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}

class _RoomSection extends StatelessWidget {
  final Room room;

  const _RoomSection({required this.room});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final tasks = dataService.getTasksForRoom(room.id);
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(room.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              ...tasks.map((task) => TaskCard(task: task)),
            ],
          ),
        );
      },
    );
  }
}
