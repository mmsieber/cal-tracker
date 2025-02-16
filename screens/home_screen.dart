import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'meal_input_screen.dart';
import 'water_input_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box _box;
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _box = Hive.box('calorieData');
  }

  List<dynamic> _getMealsForDate(String date) {
    final data = _box.get(date, defaultValue: {"meals": [], "water": 0.0});
    return (data is Map && data.containsKey("meals")) ? List<dynamic>.from(data["meals"]) : [];
  }

  double _getWaterIntakeForDate(String date) {
    final data = _box.get(date, defaultValue: {"meals": [], "water": 0.0});
    return (data is Map && data.containsKey("water")) ? (data["water"] as double) : 0.0;
  }

  Map<String, List<dynamic>> _categorizeMeals(List<dynamic> meals) {
    final Map<String, List<dynamic>> categorizedMeals = {
      "Breakfast": [],
      "Lunch": [],
      "Dinner": [],
      "Snack": [],
    };

    for (var meal in meals) {
      final category = meal['category'] ?? "Uncategorized";
      if (categorizedMeals.containsKey(category)) {
        categorizedMeals[category]!.add(meal);
      } else {
        categorizedMeals[category] = [meal];
      }
    }
    return categorizedMeals;
  }

  Future<void> _deleteMeal(String date, String category, int index) async {
    final data = _box.get(date, defaultValue: {"meals": [], "water": 0.0});
    if (data is Map && data.containsKey("meals")) {
      final meals = List.from(data["meals"]);
      final categorizedMeals = _categorizeMeals(meals);

      if (categorizedMeals[category] != null) {
        categorizedMeals[category]!.removeAt(index);
        data["meals"] = categorizedMeals.values.expand((e) => e).toList();
        await _box.put(date, data);
        setState(() {});
      }
    }
  }

  String _getFormattedTitle() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().substring(0, 10);

    if (_selectedDate == today) {
      return "Today (${_formatDate(_selectedDate)})";
    } else if (_selectedDate == yesterday) {
      return "Yesterday (${_formatDate(_selectedDate)})";
    } else {
      return _formatDate(_selectedDate);
    }
  }

  String _formatDate(String date) {
    final parts = date.split("-");
    return (parts.length == 3) ? "${parts[2]}.${parts[1]}.${parts[0]}" : date;
  }

  Map<String, double> _calculateTotals(List<dynamic> meals) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in meals) {
      final nutrition = meal['nutrition'];
      if (nutrition != null) {
        totalCalories += (nutrition['calories'] ?? 0).toDouble();
        totalProtein += (nutrition['protein'] ?? 0).toDouble();
        totalCarbs += (nutrition['carbs'] ?? 0).toDouble();
        totalFat += (nutrition['fat'] ?? 0).toDouble();
      }
    }

    return {
      "calories": totalCalories,
      "protein": totalProtein,
      "carbs": totalCarbs,
      "fat": totalFat,
    };
  }

  @override
  Widget build(BuildContext context) {
    final meals = _getMealsForDate(_selectedDate);
    final categorizedMeals = _categorizeMeals(meals);
    final totals = _calculateTotals(meals);
    final dailyWaterIntake = _getWaterIntakeForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getFormattedTitle()),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                setState(() {
                  _selectedDate = selectedDate.toIso8601String().substring(0, 10);
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: meals.isEmpty
                ? Center(
                    child: Text(
                      "No meals recorded for this day.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView(
                    children: categorizedMeals.entries.map((entry) {
                      final category = entry.key;
                      final meals = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ...meals.asMap().entries.map((mealEntry) {
                            final index = mealEntry.key;
                            final meal = mealEntry.value;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(meal['description'] ?? "Unnamed Meal"),
                                subtitle: meal['nutrition'] != null
                                    ? Text(
                                        "Calories: ${meal['nutrition']['calories']} kcal\n"
                                        "Protein: ${meal['nutrition']['protein']}g\n"
                                        "Carbs: ${meal['nutrition']['carbs']}g\n"
                                        "Fat: ${meal['nutrition']['fat']}g",
                                      )
                                    : Text("No nutrition data available"),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteMeal(
                                    _selectedDate,
                                    category,
                                    index,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daily Totals:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text("Calories: ${(totals['calories'] ?? 0).toStringAsFixed(1)} kcal"),
                Text("Protein: ${(totals['protein'] ?? 0).toStringAsFixed(1)} g"),
                Text("Carbs: ${(totals['carbs'] ?? 0).toStringAsFixed(1)} g"),
                Text("Fat: ${(totals['fat'] ?? 0).toStringAsFixed(1)} g"),
                SizedBox(height: 10),
                Text("💧 Water Intake: ${(dailyWaterIntake / 100).toStringAsFixed(2)} L"),

              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: Icon(Icons.local_drink),
            backgroundColor: Colors.blue,
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => WaterInputScreen(selectedDate: _selectedDate),
              ));
              setState(() {});
            },
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => MealInputScreen(selectedDate: _selectedDate),
              ));
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
