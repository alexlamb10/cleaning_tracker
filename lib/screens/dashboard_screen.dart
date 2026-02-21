import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/models/models.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/screens/add_room_screen.dart';
import 'package:cleaning_tracker/screens/add_task_screen.dart';
import 'package:cleaning_tracker/screens/room_detail_screen.dart';
import 'package:cleaning_tracker/widgets/gradient_background.dart';
import 'package:cleaning_tracker/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Optional: request notification permission after first paint. On Safari/iOS, permission
    // is often granted only in response to a user gesture; use the "Enable notifications"
    // button in the notification banner for best results.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Delay slightly to ensure PWA environment is stable on mobile launch
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        context.read<DataService>().requestNotificationPermission();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          actions: _selectedIndex == 0
              ? [

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
                ]
              : null,
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF4B5244), // Thicket
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'To do',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Reminders',
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Rooms';
      case 1:
        return 'To Do';
      case 2:
        return 'Reminders';
      default:
        return 'CleanTrack';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildRoomsView();
      case 1:
        return _buildToDoView();
      case 2:
        return _buildRemindersView();
      default:
        return _buildRoomsView();
    }
  }

  Widget _buildRoomsView() {
    return Consumer<DataService>(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B5244), // Thicket
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
            _buildNotificationBanner(context, dataService),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dataService.rooms.length,
                itemBuilder: (context, index) {
                  final room = dataService.rooms[index];
                  final taskCount = dataService.getTasksForRoom(room.id).length;
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailScreen(roomId: room.id),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            room.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToDoView() {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final allTasks = dataService.tasks;
        
        if (allTasks.isEmpty) {
          return const Center(
            child: Text('No tasks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          );
        }

        // Sort by cleanliness level (dirtiest first)
        final sortedTasks = List<Task>.from(allTasks)
          ..sort((a, b) {
            final levelA = dataService.getCalculatedCleanlinessLevel(a);
            final levelB = dataService.getCalculatedCleanlinessLevel(b);
            return levelA.compareTo(levelB);
          });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sortedTasks.length,
          itemBuilder: (context, index) {
            return _TaskListItem(task: sortedTasks[index]);
          },
        );
      },
    );
  }

  Widget _buildRemindersView() {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final overdueTasks = dataService.tasks.where((task) {
          return dataService.getTaskStatus(task) == TaskStatus.overdue;
        }).toList();

        if (overdueTasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Color(0xFFA9BDC4)), // Ether
                SizedBox(height: 16),
                Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: overdueTasks.length,
          itemBuilder: (context, index) {
            return _TaskListItem(task: overdueTasks[index]);
          },
        );
      },
    );
  }

  Widget _buildNotificationBanner(BuildContext context, DataService dataService) {
    final status = dataService.getNotificationPermission();
    if (status != 'default') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFA9BDC4).withOpacity(0.2), // Ether with opacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA9BDC4).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Color(0xFF4B5244)), // Thicket
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Enable reminders to stay on top of your cleaning!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF121212), // Ink
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => dataService.requestNotificationPermission(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF4B5244), // Thicket
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Enable', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;

  const _TaskListItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final dataService = context.read<DataService>();
    final room = dataService.rooms.firstWhere((r) => r.id == task.roomId);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              room.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          TaskCard(task: task),
        ],
      ),
    );
  }
}
