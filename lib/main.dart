import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAKTuQc_mPQqym6UesK4u7KV0OR7oQ4nV8",
      authDomain: "cleaning-tracker-5408d.firebaseapp.com",
      projectId: "cleaning-tracker-5408d",
      storageBucket: "cleaning-tracker-5408d.firebasestorage.app",
      messagingSenderId: "621678496436",
      appId: "1:621678496436:web:63d1b0c900ab8965cee5e1",
      measurementId: "G-XTXZF7SLXQ",
    ),
  );

  // Load data before runApp to prevent empty-list flash on startup
  final dataService = DataService();
  await dataService.loadData();

  runApp(
    ChangeNotifierProvider.value(
      value: dataService,
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
          color: Colors.white,
          elevation: 2,
          shadowColor: Color(0x1A4B5244),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF121212)),
          titleTextStyle: TextStyle(
            color: Color(0xFF121212),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF121212)),
          titleMedium: TextStyle(color: Color(0xFF121212)),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}