import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/exercise_model.dart';
import '../widgets/create_exercise.dart';

class ExercisesScreen extends StatelessWidget {
  ExercisesScreen({super.key});

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateExerciseDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('exercises')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!.docs
              .map((doc) =>
                  ExerciseModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  const Text('No exercises yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showCreateExerciseDialog(context),
                    child: const Text('Create Exercise'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      exercise.name,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.category ?? 'Uncategorized',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7)),
                        ),
                        if (exercise.personalBestWeight != null ||
                            exercise.personalBestReps != null)
                          Text(
                            'PB: ${exercise.personalBestWeight?.toStringAsFixed(1)}kg × ${exercise.personalBestReps} reps',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert,
                          color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => _showExerciseOptions(context, exercise),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateExerciseDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExerciseScreen(),
      ),
    );
  }

  void _showExerciseOptions(BuildContext context, ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Exercise'),
              onTap: () {
                Navigator.pop(context);
                _showEditExerciseDialog(context, exercise);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Progress'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to exercise progress screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress tracking coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Exercise',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditExerciseDialog(BuildContext context, ExerciseModel exercise) {
    final nameController = TextEditingController(text: exercise.name);
    final categoryController =
        TextEditingController(text: exercise.category ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Exercise Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
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
              if (nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('exercises')
                    .doc(exercise.id)
                    .update({
                  'name': nameController.text.trim(),
                  'category': categoryController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ExerciseModel exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: const Text('Are you sure you want to delete this exercise?\n\n'
            'This will also remove it from any workouts that use it.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('exercises')
                  .doc(exercise.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
