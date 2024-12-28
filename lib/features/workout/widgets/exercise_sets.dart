import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_exercise_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_set_model.dart';
import '../../data/services/workout_service.dart';

class ExerciseSetsSection extends StatefulWidget {
  final String workoutId;
  final WorkoutExercise exercise;
  final ExerciseModel exerciseData;

  const ExerciseSetsSection({
    super.key,
    required this.workoutId,
    required this.exercise,
    required this.exerciseData,
  });

  @override
  State<ExerciseSetsSection> createState() => _ExerciseSetsState();
}

class _ExerciseSetsState extends State<ExerciseSetsSection> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _workoutService = WorkoutService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Previous sets
        if (widget.exercise.sets.isNotEmpty) ...[
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.exercise.sets.length,
            itemBuilder: (context, index) {
              final set = widget.exercise.sets[index];
              return ListTile(
                dense: true,
                title: Text(
                  'Set ${index + 1}: ${set.weight}kg × ${set.reps} reps',
                  style: TextStyle(
                    decoration:
                        set.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: set.isCompleted,
                      onChanged: (value) =>
                          _updateSetCompletion(index, value ?? false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditSetDialog(context, index, set),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        // Add new set
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addSet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addSet() async {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight != null && reps != null) {
      final newSet = ExerciseSet(
        weight: weight,
        reps: reps,
        timestamp: DateTime.now(),
      );

      await _workoutService.recordSet(
        userId,
        widget.workoutId,
        widget.exercise.exerciseId,
        newSet,
      );

      _weightController.clear();
      _repsController.clear();
    }
  }

  Future<void> _updateSetCompletion(int index, bool isCompleted) async {
    final set = widget.exercise.sets[index];
    final updatedSet = set.copyWith(isCompleted: isCompleted);

    await _workoutService.editSet(
      userId,
      widget.workoutId,
      widget.exercise.exerciseId,
      index,
      updatedSet,
    );
  }

  void _showEditSetDialog(BuildContext context, int index, ExerciseSet set) {
    final weightController = TextEditingController(text: set.weight.toString());
    final repsController = TextEditingController(text: set.reps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Set ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);

              if (weight != null && reps != null) {
                final updatedSet = set.copyWith(
                  weight: weight,
                  reps: reps,
                );

                await _workoutService.editSet(
                  userId,
                  widget.workoutId,
                  widget.exercise.exerciseId,
                  index,
                  updatedSet,
                );

                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }
}
