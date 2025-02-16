import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:calorie_tracker/utils/gpt_api.dart';
import 'package:calorie_tracker/utils/gpt4_vision_service.dart';

class MealInputScreen extends StatefulWidget {
  final String selectedDate;

  const MealInputScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _MealInputScreenState createState() => _MealInputScreenState();
}

class _MealInputScreenState extends State<MealInputScreen> {
  String _mealDescription = "";
  String _selectedCategory = "Breakfast";
  final List<Map<String, dynamic>> _ingredients = [];
  final Map<int, TextEditingController> _controllers = {};
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  void _addIngredient(String item, {double amount = 0.0}) {
    setState(() {
      int index = _ingredients.length;
      _ingredients.add({"item": item, "amount": amount, "sliderActive": false});
      _controllers[index] = TextEditingController(text: item);
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _controllers.remove(index);
    });
  }

  void _toggleSlider(int index) {
    setState(() {
      _ingredients[index]["sliderActive"] = !_ingredients[index]["sliderActive"];
      if (!_ingredients[index]["sliderActive"]) {
        _ingredients[index]["amount"] = 0.0;
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      if (!mounted) return;
      setState(() {
        _selectedImage = File(image.path);
      });

      try {
        final nutritionData = await Gpt4VisionService.analyzeImage(_selectedImage!);
        if (mounted) {
          _updateMealWithNutrition(nutritionData);
          _showFeedbackDialog(nutritionData);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to extract nutrition data: $e")),
          );
        }
      }
    }
  }

  Future<void> _saveMeal() async {
    if (!mounted) return;
    final box = Hive.box('calorieData');
    final mealData = {
      "description": _mealDescription,
      "category": _selectedCategory,
      "ingredients": _ingredients.map((ingredient) {
        return {
          "item": ingredient["item"],
          "amount": ingredient["sliderActive"] ? ingredient["amount"] : 0.0,
        };
      }).toList(),
    };

    final existingData = box.get(widget.selectedDate, defaultValue: {"meals": []});
    if (existingData is Map<String, dynamic>) {
      existingData["meals"].add(mealData);
      await box.put(widget.selectedDate, existingData);
    } else {
      await box.put(widget.selectedDate, {"meals": [mealData]});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Meal saved for ${widget.selectedDate}!")),
      );
    }

    try {
      final feedback = await GPTApi.getCalories(mealData);
      if (mounted) {
        await _updateMealWithNutrition(feedback);
        _showFeedbackDialog(feedback);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching nutrition data: $e")),
        );
      }
    }
  }

  Future<void> _updateMealWithNutrition(Map<String, dynamic> nutritionData) async {
    final box = Hive.box('calorieData');
    final dayData = box.get(widget.selectedDate);

    if (dayData is Map<String, dynamic> && dayData["meals"] is List) {
      dayData["meals"].last["nutrition"] = nutritionData;
      await box.put(widget.selectedDate, dayData);
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> feedback) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Meal Feedback"),
          content: Text(
            "Calories: ${feedback['calories']} kcal\n"
            "Protein: ${feedback['protein']}g\n"
            "Carbs: ${feedback['carbs']}g\n"
            "Fat: ${feedback['fat']}g",
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Meal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text("Select Meal Category:", style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: _selectedCategory,
              items: ["Breakfast", "Lunch", "Dinner", "Snack"]
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Describe your meal:", style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue),
                  onPressed: _pickImage,
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g., 2 eggs and avocado",
              ),
              onChanged: (value) {
                setState(() {
                  _mealDescription = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveMeal, child: const Text("Save Meal")),
          ],
        ),
      ),
    );
  }
}
