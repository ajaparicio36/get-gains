// workout details
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_model.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_screen.dart';
import '../../data/services/workout_service.dart';
import '../../exercises/screens/exercise_search_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final WorkoutService workoutService = WorkoutService();

  void _showAddExerciseOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Browse ExerciseDB'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseSearchScreen(
                      userId: userId,
                      workoutId: widget.workout.id,
                      workoutService: workoutService,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Choose from My Exercises'),
              onTap: () {
                Navigator.pop(context);
                _showAddExerciseScreen(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExerciseScreen(workoutId: widget.workout.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(widget.workout.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text('Workout not found'));
          }
          final workoutData = snapshot.data!.data() as Map<String, dynamic>;

          final workout = WorkoutModel.fromMap(workoutData);

          if (workout.exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddExerciseOptions(context),
                    child: const Text('Add Exercise'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workout.exercises.length,
            itemBuilder: (context, index) {
              final exercise = workout.exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WorkoutExerciseCard(
                  workoutId: workout.id,
                  exercise: exercise,
                  onExerciseCompleted: (isCompleted) =>
                      _toggleExerciseCompletion(
                          exercise.exerciseId, isCompleted),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleExerciseCompletion(
      String exerciseId, bool isCompleted) async {
    final workoutRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(widget.workout.id);

    final workoutDoc = await workoutRef.get();
    final workout = WorkoutModel.fromMap(workoutDoc.data()!);

    final updatedExercises = workout.exercises.map((exercise) {
      if (exercise.exerciseId == exerciseId) {
        return exercise.copyWith(isCompleted: isCompleted);
      }
      return exercise;
    }).toList();

    await workoutRef.update({
      'exercises': updatedExercises.map((e) => e.toMap()).toList(),
    });
  }
}
