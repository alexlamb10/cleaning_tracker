import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/database/database.dart';
import 'package:cleaning_tracker/services/task_service.dart';
import 'package:cleaning_tracker/screens/dashboard_screen.dart';

void main() {
  final database = AppDatabase();
  final taskService = TaskService(database);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<TaskService>.value(value: taskService),
      ],
      child: const CleanTrackApp(),
    ),
  );
}

class CleanTrackApp extends StatelessWidget {
  const CleanTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
