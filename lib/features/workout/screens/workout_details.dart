import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workout_service.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_screen.dart';

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
  final WorkoutService _workoutService = WorkoutService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseScreen(context),
          ),
        ],
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

          final workoutData = snapshot.data?.data() as Map<String, dynamic>?;
          if (workoutData == null) {
            return const Center(child: Text('Workout not found'));
          }

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
                    onPressed: () => _showAddExerciseDialog(context),
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

  Future<void> _showAddExerciseDialog(BuildContext context) async {
    final exercises = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .get();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.docs.length,
            itemBuilder: (context, index) {
              final exercise =
                  ExerciseModel.fromMap(exercises.docs[index].data());
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.category ?? 'Uncategorized'),
                onTap: () async {
                  await _workoutService.addExerciseToWorkout(
                    userId,
                    widget.workout.id,
                    exercise.id,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
