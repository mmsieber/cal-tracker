import 'dart:io';
import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../utils/gpt4_vision_service.dart';
import '../utils/image_picker_service.dart';

class MealProvider with ChangeNotifier {
  List<Meal> _meals = [];
  final Gpt4VisionService _gpt4VisionService = Gpt4VisionService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  List<Meal> get meals => _meals;

  void addMeal(Meal meal) {
    _meals.add(meal);
    notifyListeners();
  }

  Future<void> addMealWithImage(Meal meal) async {
    final image = await _imagePickerService.pickImage();
    if (image != null) {
      final updatedMeal = await _gpt4VisionService.analyzeImage(image, meal);
      if (updatedMeal != null) {
        _meals = _meals.map((m) => m.id == updatedMeal.id ? updatedMeal : m).toList();
        notifyListeners();
      } else {
        debugPrint("Image analysis failed.");
      }
    } else {
      debugPrint("Image selection failed.");
    }
  }
}
