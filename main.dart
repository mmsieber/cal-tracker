import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calorie_tracker/screens/home_screen.dart'; // Use HomeScreen as the starting point

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open a box for storing data
  await Hive.openBox('calorieData');

  // Run the app
  runApp(CalorieTrackerApp());
}

class CalorieTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calorie Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(), // Use HomeScreen as the default screen
    );
  }
}
