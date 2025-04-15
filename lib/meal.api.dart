import 'dart:convert';
import 'package:http/http.dart' as http;

class MealApi {
  static const String _baseUrl =
      'https://api.spoonacular.com/recipes/parseIngredients';
  static const String _apiKey = '77c136162da84d17a61a4de056d86989';

  static Future<Map<String, dynamic>> fetchNutritionInfo(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?query=$query'),
      headers: {
        'X-RapidAPI-Key': _apiKey,
        'X-RapidAPI-Host': 'nutrition-by-api-ninjas.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final dynamic jsonData = jsonDecode(response.body);

      // Check if the response is a list (if so, return the first item)
      if (jsonData is List) {
        if (jsonData.isNotEmpty) {
          return jsonData.first;
        } else {
          throw Exception('Empty response returned');
        }
      } else {
        return jsonData;
      }
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception('Failed to load nutrition information');
    }
  }
}
