import 'dart:convert'; // For JSON operations
import 'package:http/http.dart' as http; // For HTTP requests

class GPTApi {
  static const String _apiKey =
      "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"; // Replace with your valid API key

  static Future<Map<String, dynamic>> getCalories(
      Map<String, dynamic> mealData) async {
    print("Preparing API request for GPT...");
    print("Meal Data: $mealData");

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
            "content":
                "You are an AI that calculates nutritional values. Where you do not know the exact values, you take estimates and provide response."
          },
          {"role": "user", "content": _buildPrompt(mealData)},
        ],
        "max_tokens": 200,
      }),
    );

    print("API request sent. Awaiting response...");

    if (response.statusCode == 200) {
      print("API response received successfully!");
      print("Raw Response Body: ${response.body}");

      // Parse the response body
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      // Extract GPT's message content
      final String? responseContent =
          responseBody['choices']?[0]['message']?['content'];

      if (responseContent != null) {
        print("Response Content: $responseContent");

        try {
          // Extract JSON from response content
          final jsonString = _extractJson(responseContent);
          final Map<String, dynamic> parsedResponse = jsonDecode(jsonString);
          print("Parsed Response: $parsedResponse");
          return parsedResponse;
        } catch (e) {
          print("Error parsing JSON from GPT response: $e");
          throw Exception("Failed to parse JSON from GPT response.");
        }
      } else {
        print("Error: GPT's response content is null.");
        throw Exception("GPT response content is null.");
      }
    } else {
      // Log and handle error response
      print("Failed to fetch GPT data. Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      throw Exception("Failed to fetch GPT data");
    }
  }

  static String _buildPrompt(Map<String, dynamic> mealData) {
    final description = mealData['description'] ?? "No description provided.";
    final category = mealData['category'] ?? "Uncategorized";

    // Prepare the ingredients list
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
    You are a nutritional analysis AI. Provide a JSON-only response with the following structure:
    {
      "calories": total_calories,
      "protein": total_protein_in_grams,
      "carbs": total_carbs_in_grams,
      "fat": total_fat_in_grams
    }

    Description: $description
    Category: $category
    Ingredients:
    $ingredientDetails
    Only provide the JSON response, with no additional text or explanations.
    """;
  }

  static String _extractJson(String responseContent) {
    print("Extracting JSON from GPT response...");
    final startIndex = responseContent.indexOf('{');
    final endIndex = responseContent.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      String json = responseContent.substring(startIndex, endIndex + 1);

      // Allow only valid JSON characters
      json = json.replaceAll(RegExp(r'[^\{\}\[\]0-9.,:"a-zA-Z_-]'), '');
      print("Extracted JSON: $json");
      return json;
    } else {
      print("Error: No valid JSON found in response.");
      throw Exception("No valid JSON found in GPT response.");
    }
  }
}
