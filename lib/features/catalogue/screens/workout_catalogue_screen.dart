import 'package:flutter/material.dart';
import '../../data/models/shared_workout_model.dart';
import '../../data/services/shared_workout_service.dart';
import 'shared_workout_detail.dart';

class WorkoutCatalogueScreen extends StatefulWidget {
  const WorkoutCatalogueScreen({super.key});

  @override
  State<WorkoutCatalogueScreen> createState() => _WorkoutCatalogueScreenState();
}

class _WorkoutCatalogueScreenState extends State<WorkoutCatalogueScreen> {
  final SharedWorkoutService _sharedWorkoutService = SharedWorkoutService();
  SortOption _currentSort = SortOption.mostCopied;
  String? _searchQuery;
  List<String>? _selectedTags;
  List<SharedWorkoutModel> _workouts = [];
  bool _isLoading = true;
  List<TagWithCount> _popularTags = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadPopularTags();
  }

  Future<void> _loadPopularTags() async {
    try {
      final tags = await _sharedWorkoutService.getPopularTags();
      setState(() => _popularTags = tags);
    } catch (e) {
      print('Failed to load popular tags: $e');
    }
  }

  Future<void> _loadWorkouts() async {
    try {
      setState(() => _isLoading = true);
      final workouts = await _sharedWorkoutService.searchWorkouts(
        nameQuery: _searchQuery,
        tags: _selectedTags,
        sortBy: _currentSort,
      );
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load workouts')),
        );
      }
      print(e);
    }
  }

  Future<void> _toggleHeart(String workoutId) async {
    try {
      await _sharedWorkoutService.toggleHeartWorkout(workoutId);
      // Reload workouts to reflect updated heart status
      _loadWorkouts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to like workout')),
        );
      }
    }
  }

  Future<void> _copyWorkout(String workoutId) async {
    try {
      await _sharedWorkoutService.copyWorkout(workoutId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout copied successfully!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied workout!')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy workout')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: WorkoutSearchDelegate(_sharedWorkoutService),
              );
              if (result != null) {
                setState(() => _searchQuery = result);
                _loadWorkouts();
              }
            },
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption sortOption) {
              setState(() => _currentSort = sortOption);
              _loadWorkouts();
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: SortOption.mostCopied,
                child: Text('Most Copied'),
              ),
              const PopupMenuItem(
                value: SortOption.newest,
                child: Text('Newest'),
              ),
              const PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('A-Z'),
              ),
              const PopupMenuItem(
                value: SortOption.mostHearted,
                child: Text('Most Liked'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_popularTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularTags
                      .map((tagWithCount) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(
                                  '${tagWithCount.tag} (${tagWithCount.count})'),
                              selected:
                                  _selectedTags?.contains(tagWithCount.tag) ??
                                      false,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTags = _selectedTags ?? [];
                                  if (selected) {
                                    _selectedTags!.add(tagWithCount.tag);
                                  } else {
                                    _selectedTags!.remove(tagWithCount.tag);
                                  }
                                  if (_selectedTags!.isEmpty) {
                                    _selectedTags = null;
                                  }
                                });
                                _loadWorkouts();
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return WorkoutCard(
                        workout: workout,
                        onHeartPressed: () => _toggleHeart(workout.id),
                        onCopyPressed: () => _copyWorkout(workout.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WorkoutDetailScreen(workout: workout),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class WorkoutSearchDelegate extends SearchDelegate<String?> {
  final SharedWorkoutService _sharedWorkoutService;

  WorkoutSearchDelegate(this._sharedWorkoutService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<SharedWorkoutModel>>(
      future: _sharedWorkoutService.searchWorkouts(nameQuery: query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error searching workouts'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data!;
        return ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return ListTile(
              title: Text(workout.name),
              subtitle: Text(workout.ownerName),
              onTap: () {
                close(context, query);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class WorkoutCard extends StatelessWidget {
  final SharedWorkoutModel workout;
  final VoidCallback onHeartPressed;
  final VoidCallback onCopyPressed;
  final VoidCallback onTap;

  const WorkoutCard({
    Key? key,
    required this.workout,
    required this.onHeartPressed,
    required this.onCopyPressed,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(1),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        workout.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: workout.heartedBy.contains('currentUserId')
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: onHeartPressed,
                        ),
                        Text('${workout.heartCount}'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: onCopyPressed,
                        ),
                        Text('${workout.copyCount}'),
                      ],
                    ),
                  ],
                ),
                if (workout.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    workout.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (workout.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: workout.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'By ${workout.ownerName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
