import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_exercise_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_set_model.dart';
import '../../data/services/workout_service.dart';

class WorkoutExerciseCard extends StatefulWidget {
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
  State<WorkoutExerciseCard> createState() => _WorkoutExerciseCardState();
}

class _WorkoutExerciseCardState extends State<WorkoutExerciseCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _workoutService = WorkoutService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isExpanded = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(widget.exercise.exerciseId)
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

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withAlpha(100),
                Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
              ],
            ),
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    exerciseData.name,
                    style: TextStyle(
                      decoration: widget.exercise.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseData.category ?? 'Uncategorized',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      if (exerciseData.musclesWorked.isNotEmpty)
                        Text(
                          'Muscles: ${exerciseData.musclesWorked.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: widget.exercise.isCompleted,
                        onChanged: (value) =>
                            widget.onExerciseCompleted(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      IconButton(
                        icon: Icon(_isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Exercise'),
                            content: const Text(
                                'Are you sure you want to delete this exercise?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _workoutService.removeExerciseFromWorkout(
                                    userId,
                                    widget.workoutId,
                                    widget.exercise.exerciseId,
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
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
                              decoration: set.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteSet(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
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
              ],
            ),
          ),
        );
      },
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

  Future<void> _deleteSet(int index) async {
    await _workoutService.deleteSet(
      userId,
      widget.workoutId,
      widget.exercise.exerciseId,
      index,
    );
  }
}
