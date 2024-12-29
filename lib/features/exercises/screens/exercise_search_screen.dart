import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/services/workout_service.dart';
import '../adapters/exercisedb_adapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSearchScreen extends StatefulWidget {
  final String userId;
  final String? workoutId;
  final WorkoutService workoutService;

  const ExerciseSearchScreen({
    Key? key,
    required this.userId,
    this.workoutId,
    required this.workoutService,
  }) : super(key: key);

  @override
  _ExerciseSearchScreenState createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  final _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;

  Future<void> _searchExercises(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://exercisedb-api.vercel.app/api/v1/exercises/autocomplete?search=$query'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        setState(() {
          _suggestions = results
              .map((item) => {
                    'name': item['name'].toString(),
                    'exerciseId': item['exerciseId'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching exercises: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExerciseSelection(
      String exerciseId, String exerciseName) async {
    setState(() => _isLoading = true);

    try {
      // First check if exercise already exists in user's collection
      final existingExercise = await _db
          .collection('users')
          .doc(widget.userId)
          .collection('exercises')
          .doc(exerciseId)
          .get();

      if (!existingExercise.exists) {
        // Fetch and save new exercise
        final response = await http.get(
          Uri.parse(
              'https://exercisedb-api.vercel.app/api/v1/exercises/$exerciseId'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final exerciseData = json.decode(response.body);
          final exercise = ExerciseApiAdapter.fromApiResponse(exerciseData);

          // Save exercise to user's collection
          await _db
              .collection('users')
              .doc(widget.userId)
              .collection('exercises')
              .doc(exercise.id)
              .set(exercise.toMap());
        }
      }

      // If workoutId is provided, add to workout as well
      if (widget.workoutId != null) {
        await widget.workoutService.addExerciseToWorkout(
          widget.userId,
          widget.workoutId!,
          exerciseId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise added to workout')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise added to your collection')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding exercise: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = widget.workoutId != null
        ? 'Add Exercise to Workout'
        : 'Add New Exercise';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Exercises',
                hintText: 'Enter exercise name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchExercises,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    title: Text(suggestion['name']),
                    onTap: () async {
                      _searchController.text = suggestion['name'];
                      setState(() => _suggestions = []);
                      await _handleExerciseSelection(
                        suggestion['exerciseId'],
                        suggestion['name'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
