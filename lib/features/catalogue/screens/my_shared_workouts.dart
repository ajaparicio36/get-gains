import 'package:flutter/material.dart';
import '../../data/models/shared_workout_model.dart';
import '../../data/services/shared_workout_service.dart';

class MySharedWorkoutsScreen extends StatelessWidget {
  final SharedWorkoutService _sharedWorkoutService = SharedWorkoutService();

  MySharedWorkoutsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shared Workouts'),
      ),
      body: StreamBuilder<List<SharedWorkoutModel>>(
        stream: _sharedWorkoutService.getMySharedWorkoutsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No shared workouts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Navigate to workouts screen or show sharing dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Share a workout'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Dismissible(
                key: Key(workout.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Shared Workout'),
                        content: const Text(
                          'Are you sure you want to delete this shared workout? This action cannot be undone.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'DELETE',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await _sharedWorkoutService.deleteSharedWorkout(workout.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout deleted successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting workout: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        workout.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Shared ${_formatDate(workout.createdAt)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 20,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workout.heartCount}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(width: 24),
                              Icon(
                                Icons.copy,
                                size: 20,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workout.copyCount}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Shared Workout'),
                                  content: const Text(
                                    'Are you sure you want to delete this shared workout? This action cannot be undone.',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        'DELETE',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              try {
                                await _sharedWorkoutService
                                    .deleteSharedWorkout(workout.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Workout deleted successfully'),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting workout: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
