class Meal {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl; // New field for image URL

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
  });

  // Add fromJson and toJson methods if not present
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
    };
  }
}
