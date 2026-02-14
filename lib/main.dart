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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA9BDC4), // Ether
          primary: const Color(0xFF4B5244),   // Thicket
          secondary: const Color(0xFF8C7D6E), // Silt
          surface: const Color(0xFFD9CDBF),   // Bone
          onSurface: const Color(0xFF121212), // Ink
        ),
        scaffoldBackgroundColor: const Color(0xFFD9CDBF), // Bone
        cardTheme: const CardThemeData(
          color: Colors.white, // Keep white for contrast, or maybe very light Bone
          elevation: 2,
          shadowColor: Color(0x1A4B5244), // Thicket with opacity
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF121212)), // Ink
          titleTextStyle: TextStyle(
            color: Color(0xFF121212), // Ink
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF121212)), // Ink
          titleMedium: TextStyle(color: Color(0xFF121212)), // Ink
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
