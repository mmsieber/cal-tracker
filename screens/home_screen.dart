import 'package:flutter/material.dart';
import 'meal_input_screen.dart';
import 'water_input_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calorie & Water Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealInputScreen(selectedDate: "2024-02-16"),
                  ),
                );
              },
              child: const Text("Track Meal"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaterInputScreen(selectedDate: "2024-02-16"),
                  ),
                );
              },
              child: const Text("Track Water Intake"),
            ),
          ],
        ),
      ),
    );
  }
}
