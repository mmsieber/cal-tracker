import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calorie_tracker/utils/gpt_api.dart';

class MealInputScreen extends StatefulWidget {
  final String selectedDate;

  MealInputScreen({required this.selectedDate});

  @override
  _MealInputScreenState createState() => _MealInputScreenState();
}

class _MealInputScreenState extends State<MealInputScreen> {
  String _mealDescription = "";
  String _selectedCategory = "Breakfast";
  final List<Map<String, dynamic>> _ingredients = [];
  final Map<int, TextEditingController> _controllers = {};

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

  Future<void> _saveMeal() async {
    final box = Hive.box('calorieData');
    final mealData = {
      "description": _mealDescription,
      "category": _selectedCategory,
      "ingredients": _ingredients.map((ingredient) {
        if (ingredient["sliderActive"] && ingredient["amount"] > 0) {
          return {
            "item": ingredient["item"],
            "amount": ingredient["amount"],
          };
        } else {
          return {"item": ingredient["item"]};
        }
      }).toList(),
    };

    final existingData = box.get(widget.selectedDate, defaultValue: {"meals": []});
    if (existingData is Map<String, dynamic>) {
      existingData["meals"].add(mealData);
      await box.put(widget.selectedDate, existingData);
    } else {
      await box.put(widget.selectedDate, {"meals": [mealData]});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Meal saved for ${widget.selectedDate}!")),
    );

    // Fetch feedback from GPT and update the meal
    final feedback = await GPTApi.getCalories(mealData);
    await _updateMealWithNutrition(feedback, widget.selectedDate, box.get(widget.selectedDate));

    // Show feedback before returning to the HomeScreen
    _showFeedbackDialog(feedback);
  }

  Future<void> _updateMealWithNutrition(
      Map<String, dynamic> nutritionData, String selectedDate, dynamic dayData) async {
    final box = Hive.box('calorieData');

    if (dayData is Map<String, dynamic> && dayData["meals"] is List) {
      dayData["meals"].last["nutrition"] = nutritionData;
      await box.put(selectedDate, dayData);
    } else {
      print("Error: Invalid dayData format.");
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> feedback) {
    dynamic parseValue(dynamic field) {
      if (field is num) {
        return field;
      } else if (field is String) {
        final numericValue = double.tryParse(field.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return numericValue % 1 == 0 ? numericValue.toInt() : numericValue;
      } else {
        return 0;
      }
    }

    final calories = parseValue(feedback['calories']);
    final protein = parseValue(feedback['protein']);
    final carbs = parseValue(feedback['carbs']);
    final fat = parseValue(feedback['fat']);

    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) {
      print("Error: Nutrition data is null or invalid.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Meal Feedback"),
          content: Text(
            "Calories: $calories kcal\n"
            "Protein: ${protein}g\n"
            "Carbs: ${carbs}g\n"
            "Fat: ${fat}g",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close feedback dialog
                Navigator.of(context).pop(true); // Navigate back to HomeScreen with success flag
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Track Meal")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Select Meal Category:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
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
            SizedBox(height: 20),
            Text("Describe your meal:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g., 2 eggs and avocado",
              ),
              onChanged: (value) {
                setState(() {
                  _mealDescription = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text("Ingredients:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Column(
              children: _ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controllers[index],
                        decoration: InputDecoration(hintText: "Enter ingredient"),
                        onChanged: (value) {
                          setState(() {
                            ingredient["item"] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(ingredient["sliderActive"] ? Icons.close : Icons.tune),
                      onPressed: () => _toggleSlider(index),
                    ),
                    if (ingredient["sliderActive"])
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: 500,
                          divisions: 50,
                          value: ingredient["amount"],
                          onChanged: (value) {
                            setState(() {
                              ingredient["amount"] = value;
                            });
                          },
                        ),
                      ),
                    if (ingredient["sliderActive"])
                      Text("${ingredient["amount"].toInt()}g"),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeIngredient(index),
                    ),
                  ],
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: () => _addIngredient(""),
              child: Text("+ Add Ingredient"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMeal,
              child: Text("Save Meal"),
            ),
          ],
        ),
      ),
    );
  }
}
