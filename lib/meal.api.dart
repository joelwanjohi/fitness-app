import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MealApi {
  // Get API key from .env file
  static String? get _apiKey => dotenv.env['GEMINI_API_KEY'];

  static Future<Map<String, dynamic>> fetchNutritionInfo(String query) async {
    if (_apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
I need nutritional information for this food/meal: '$query'.
Please provide a JSON object with the following fields ONLY (all numeric values should be numbers, not strings):

{
  "name": "the food item name",
  "calories": numeric value,
  "serving_size_g": numeric value,
  "fat_total_g": numeric value,
  "fat_saturated_g": numeric value,
  "protein_g": numeric value,
  "sodium_mg": numeric value,
  "potassium_mg": numeric value,
  "sugar_g": numeric value
}

Please provide ONLY the JSON with NO additional explanation text.
"""
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.1,
            "topK": 1,
            "topP": 1,
            "maxOutputTokens": 1024
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Extract the text from Gemini's response
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Find and extract the JSON object from the text
        final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        final match = jsonRegex.firstMatch(textResponse);
        
        if (match != null) {
          try {
            // Parse the extracted JSON
            final jsonString = match.group(0);
            if (jsonString != null) {
              final parsedJson = jsonDecode(jsonString);
              
              // Convert any string numeric values to actual numeric values
              final Map<String, dynamic> cleanedJson = {
                'name': parsedJson['name'],
                'calories': _parseNumeric(parsedJson['calories']),
                'serving_size_g': _parseNumeric(parsedJson['serving_size_g']),
                'fat_total_g': _parseNumeric(parsedJson['fat_total_g']),
                'fat_saturated_g': _parseNumeric(parsedJson['fat_saturated_g']),
                'protein_g': _parseNumeric(parsedJson['protein_g']),
                'sodium_mg': _parseNumeric(parsedJson['sodium_mg']),
                'potassium_mg': _parseNumeric(parsedJson['potassium_mg']),
                'sugar_g': _parseNumeric(parsedJson['sugar_g']),
              };
              
              return cleanedJson;
            }
          } catch (e) {
            throw Exception('Failed to parse JSON response: $e');
          }
        }
        
        throw Exception('Failed to extract JSON from response');
      } else {
        throw Exception('Failed to fetch nutrition information: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with Gemini API: $e');
    }
  }
  
  // Helper method to ensure values are numeric
  static dynamic _parseNumeric(dynamic value) {
    if (value is num) {
      return value;
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}