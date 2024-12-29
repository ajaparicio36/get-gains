import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_model.dart';
import '../../data/services/workout_service.dart';
import 'workout_details.dart';

class WorkoutsScreen extends StatelessWidget {
  WorkoutsScreen({super.key});

  final WorkoutService _workoutService = WorkoutService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _showEditNameDialog(
      BuildContext context, WorkoutModel workout) async {
    final nameController = TextEditingController(text: workout.name);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workout Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Workout Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _workoutService.updateWorkoutName(
                    userId,
                    workout.id,
                    nameController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout name updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Error updating workout name: ${e.toString()}'),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reperformWorkout(
      BuildContext context, WorkoutModel workout) async {
    try {
      final newWorkoutId =
          await _workoutService.copyWorkout(userId, workout.id);

      // Navigate to the new workout
      if (context.mounted) {
        // Get the new workout details
        final workoutDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(newWorkoutId)
            .get();

        final newWorkout = WorkoutModel.fromMap(workoutDoc.data()!);
        await _showEditNameDialog(context, newWorkout);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating workout: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateWorkoutDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            elevation: 0,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Long press to view options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // In Progress Workouts Section
          Expanded(
            flex: 1, // Smaller flex for in-progress
            child: Card(
              elevation: 0,
              color: Colors.transparent,
              child: _buildWorkoutSection(
                title: 'In Progress',
                stream: _getInProgressWorkouts(),
                onLongPress: _handleInProgressWorkoutLongPress,
              ),
            ),
          ),
          // Previous Workouts Section
          Expanded(
            flex: 2, // Larger flex for previous workouts
            child: Card(
              elevation: 0,
              color: Colors.transparent,
              child: _buildWorkoutSection(
                title: 'Previous Workouts',
                stream: _getPreviousWorkouts(),
                onLongPress: _handlePreviousWorkoutLongPress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSection({
    required String title,
    required Stream<List<WorkoutModel>> stream,
    required Function(BuildContext, WorkoutModel) onLongPress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<WorkoutModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final workouts = snapshot.data ?? [];
              if (workouts.isEmpty) {
                return Center(
                  child: Text(
                    'No workouts found',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                );
              }

              return ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return _buildWorkoutTile(context, workout, onLongPress);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutTile(
    BuildContext context,
    WorkoutModel workout,
    Function(BuildContext, WorkoutModel) onLongPress,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Theme.of(context).colorScheme.primary.withOpacity(1),
      child: ListTile(
        title: Text(workout.name),
        subtitle: Text(
          '${workout.exercises.length} exercises • ${_formatDate(workout.date)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToWorkoutDetail(context, workout),
        onLongPress: () => onLongPress(context, workout),
      ),
    );
  }

  Stream<List<WorkoutModel>> _getInProgressWorkouts() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .where('isCompleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<WorkoutModel>> _getPreviousWorkouts() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .where('isCompleted', isEqualTo: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutModel.fromMap(doc.data()))
            .toList());
  }

  void _handleInProgressWorkoutLongPress(
      BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Name'),
              onTap: () async {
                Navigator.pop(context);
                await _showEditNameDialog(context, workout);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Mark as Complete'),
              onTap: () async {
                Navigator.pop(context);
                await _markWorkoutAsComplete(workout);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Workout',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteWorkout(context, workout);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePreviousWorkoutLongPress(
      BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Name'),
              onTap: () async {
                Navigator.pop(context);
                await _showEditNameDialog(context, workout);
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reperform Workout'),
              onTap: () async {
                Navigator.pop(context);
                await _reperformWorkout(context, workout);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Workout'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Workout',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteWorkout(context, workout);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markWorkoutAsComplete(WorkoutModel workout) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .update({'isCompleted': true});
  }

  Future<void> _deleteWorkout(
      BuildContext context, WorkoutModel workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workout.id)
          .delete();
    }
  }

  void _showCreateWorkoutDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Workout'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Workout Name',
            hintText: 'e.g., Upper Body, Leg Day',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final workoutId = await _workoutService.createWorkout(
                  userId,
                  nameController.text.trim(),
                );
                Navigator.pop(context);
                _navigateToWorkoutDetail(
                  context,
                  WorkoutModel(
                    id: workoutId,
                    name: nameController.text.trim(),
                    date: DateTime.now(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToWorkoutDetail(BuildContext context, WorkoutModel workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    );
  }
}
