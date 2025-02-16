import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WaterInputScreen extends StatefulWidget {
  final String selectedDate;

  const WaterInputScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  WaterInputScreenState createState() => WaterInputScreenState();
}

class WaterInputScreenState extends State<WaterInputScreen> {
  final TextEditingController _controller = TextEditingController();
  double _waterAmount = 0.0;

  Future<void> _saveWaterIntake() async {
    final box = Hive.box('calorieData');

    double newWaterAmount = _waterAmount;
    if (_controller.text.isNotEmpty) {
      double? manualEntry = double.tryParse(_controller.text);
      if (manualEntry != null && manualEntry > 0) {
        newWaterAmount += manualEntry;
      }
    }

    final updatedData = {
      "meals": box.get(widget.selectedDate)?["meals"] ?? [],
      "water": newWaterAmount,
    };

    await box.put(widget.selectedDate, updatedData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Water intake saved for ${widget.selectedDate}!")),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Water Intake")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter Water Intake (ml):", style: TextStyle(fontSize: 16)),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g., 500",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveWaterIntake,
              child: const Text("Save Water Intake"),
            ),
          ],
        ),
      ),
    );
  }
}
