import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class Gpt4VisionService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final request = http.MultipartRequest("POST", Uri.parse(_apiUrl))
      ..headers['Authorization'] = "Bearer $_apiKey"
      ..headers['Content-Type'] = "multipart/form-data"
      ..fields['model'] = "gpt-4-vision"
      ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseData);
      final text = jsonResponse['choices'][0]['message']['content'];

      return _parseNutritionData(text);
    } else {
      throw Exception("Failed to analyze image: ${response.reasonPhrase}");
    }
  }

  static Map<String, dynamic> _parseNutritionData(String responseText) {
    final RegExp regExpCalories = RegExp(r"Calories: (\d+)");
    final RegExp regExpProtein = RegExp(r"Protein: (\d+)");
    final RegExp regExpCarbs = RegExp(r"Carbs: (\d+)");
    final RegExp regExpFat = RegExp(r"Fat: (\d+)");

    return {
      'calories': int.tryParse(regExpCalories.firstMatch(responseText)?.group(1) ?? "0") ?? 0,
      'protein': int.tryParse(regExpProtein.firstMatch(responseText)?.group(1) ?? "0") ?? 0,
      'carbs': int.tryParse(regExpCarbs.firstMatch(responseText)?.group(1) ?? "0") ?? 0,
      'fat': int.tryParse(regExpFat.firstMatch(responseText)?.group(1) ?? "0") ?? 0,
    };
  }
}
