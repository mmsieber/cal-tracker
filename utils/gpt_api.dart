import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTApi {
  static const String _apiKey = "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"; // Replace with your valid API key

  static Future<Map<String, dynamic>> getCalories(Map<String, dynamic> mealData) async {
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $_apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "You are an AI that calculates nutritional values. Estimate where necessary."
          },
          {"role": "user", "content": _buildPrompt(mealData)},
        ],
        "max_tokens": 200,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String? responseContent = responseBody['choices']?[0]['message']?['content'];

      if (responseContent != null) {
        return jsonDecode(_extractJson(responseContent));
      } else {
        throw Exception("GPT response content is null.");
      }
    } else {
      throw Exception("Failed to fetch GPT data. Status Code: ${response.statusCode}");
    }
  }

  static String _buildPrompt(Map<String, dynamic> mealData) {
    final description = mealData['description'] ?? "No description provided.";
    final category = mealData['category'] ?? "Uncategorized";
    final List<dynamic> ingredients = mealData['ingredients'] ?? [];

    String ingredientDetails = "";
    for (var ingredient in ingredients) {
      ingredientDetails += "- ${ingredient['item']}";
      if (ingredient.containsKey('amount') && ingredient['amount'] > 0) {
        ingredientDetails += ": ${ingredient['amount']}g";
      }
      ingredientDetails += "\n";
    }

    return """
    Provide a JSON-only response:
    {
      "calories": total_calories,
      "protein": total_protein_in_grams,
      "carbs": total_carbs_in_grams,
      "fat": total_fat_in_grams
    }
    Meal: $description
    Ingredients:
    $ingredientDetails
    """;
  }

  static String _extractJson(String responseContent) {
    final startIndex = responseContent.indexOf('{');
    final endIndex = responseContent.lastIndexOf('}');
    if (startIndex != -1 && endIndex > startIndex) {
      return responseContent.substring(startIndex, endIndex + 1);
    } else {
      throw Exception("No valid JSON found in GPT response.");
    }
  }
}
