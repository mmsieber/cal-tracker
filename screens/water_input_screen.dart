import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WaterInputScreen extends StatefulWidget {
  final String selectedDate;

  WaterInputScreen({required this.selectedDate});

  @override
  _WaterInputScreenState createState() => _WaterInputScreenState();
}

class _WaterInputScreenState extends State<WaterInputScreen> {
  double _waterAmount = 25.0; // Default to 25cl (0.25L)
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingWaterData();
  }

  void _loadExistingWaterData() {
    final box = Hive.box('calorieData');
    final existingData = box.get(widget.selectedDate, defaultValue: {"meals": [], "water": 0.0});

    if (existingData is Map && existingData.containsKey("water")) {
      setState(() {
        _waterAmount = (existingData["water"] as double);
      });
    }
  }

  Future<void> _saveWaterIntake() async {
    final box = Hive.box('calorieData');
    final existingData = box.get(widget.selectedDate, defaultValue: {"meals": [], "water": 0.0});

    double newWaterAmount = _waterAmount;
    if (_controller.text.isNotEmpty) {
      double? manualEntry = double.tryParse(_controller.text);
      if (manualEntry != null && manualEntry > 0) {
        newWaterAmount += manualEntry;
      }
    }

    final updatedData = {
      "meals": existingData["meals"] ?? [],
      "water": newWaterAmount, // Update total water intake in cl
    };

    await box.put(widget.selectedDate, updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Water intake saved for ${widget.selectedDate}!")),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log Water Intake")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter Water Intake (cl):", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g., 25 (centiliters)",
              ),
            ),
            SizedBox(height: 20),
            Text("Or use the slider:", style: TextStyle(fontSize: 16)),
            Slider(
              min: 10.0, // 10cl minimum
              max: 200.0, // 200cl (2 liters) max
              divisions: 19, // Allows selection every 10cl
              value: _waterAmount,
              label: "${_waterAmount.toStringAsFixed(0)} cl",
              onChanged: (value) {
                setState(() {
                  _waterAmount = value;
                });
              },
            ),
            Text("Selected: ${_waterAmount.toStringAsFixed(0)} cl"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveWaterIntake,
              child: Text("Save Water Intake"),
            ),
          ],
        ),
      ),
    );
  }
}
