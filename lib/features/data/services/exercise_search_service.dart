// exercise_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseSearchService {
  final String baseUrl; // Your API base URL

  ExerciseSearchService({required this.baseUrl});

  Future<List<String>> searchExercises(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/exercises/search?search=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(
              data['data'].map((exercise) => exercise['name']));
        }
      }
      return [];
    } catch (e) {
      print('Error searching exercises: $e');
      return [];
    }
  }
}
