import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/screens/dashboard_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DataService(),
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
