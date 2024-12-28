// workout_exercise_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_exercise_model.dart';
import '../../data/models/exercise_model.dart';
import 'exercise_sets.dart';

class WorkoutExerciseCard extends StatelessWidget {
  final String workoutId;
  final WorkoutExercise exercise;
  final Function(bool) onExerciseCompleted;

  const WorkoutExerciseCard({
    super.key,
    required this.workoutId,
    required this.exercise,
    required this.onExerciseCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exercise.exerciseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final exerciseData = ExerciseModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>);

        return Card(
          child: Column(
            children: [
              ListTile(
                title: Text(
                  exerciseData.name,
                  style: TextStyle(
                    decoration: exercise.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  exerciseData.category ?? 'Uncategorized',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                trailing: Checkbox(
                  value: exercise.isCompleted,
                  onChanged: (value) => onExerciseCompleted(value ?? false),
                ),
              ),
              ExerciseSetsSection(
                workoutId: workoutId,
                exercise: exercise,
                exerciseData: exerciseData,
              ),
            ],
          ),
        );
      },
    );
  }
}
