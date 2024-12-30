import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/shared_workout_model.dart';
import 'shared_workout_detail.dart';
import '../../data/services/shared_workout_service.dart';

class WorkoutSearchScreen extends StatefulWidget {
  const WorkoutSearchScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutSearchScreen> createState() => _WorkoutSearchScreenState();
}

class _WorkoutSearchScreenState extends State<WorkoutSearchScreen> {
  final SharedWorkoutService _sharedWorkoutService = SharedWorkoutService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<SharedWorkoutModel> _searchResults = [];
  List<String> _selectedTags = [];
  List<TagWithCount> _popularTags = [];
  bool _isLoading = false;
  SortOption _currentSort = SortOption.mostCopied;

  @override
  void initState() {
    super.initState();
    _loadPopularTags();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPopularTags() async {
    try {
      final tags = await _sharedWorkoutService.getPopularTags();
      setState(() {
        _popularTags = tags;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final results = await _sharedWorkoutService.searchWorkouts(
        nameQuery: _searchController.text,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        sortBy: _currentSort,
      );
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to search workouts')),
      );
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Workouts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workouts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption sortOption) {
              setState(() => _currentSort = sortOption);
              _performSearch();
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
          // Tags Section
          if (_popularTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularTags.length,
                  itemBuilder: (context, index) {
                    final tag = _popularTags[index].tag;
                    final isSelected = _selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (_) => _toggleTag(tag),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty &&
                                  _selectedTags.isEmpty
                              ? 'Start searching for workouts'
                              : 'No workouts found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final workout = _searchResults[index];
                          return WorkoutSearchResultCard(
                            workout: workout,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WorkoutDetailScreen(workout: workout),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class WorkoutSearchResultCard extends StatelessWidget {
  final SharedWorkoutModel workout;
  final VoidCallback onTap;

  const WorkoutSearchResultCard({
    Key? key,
    required this.workout,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${workout.ownerName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, size: 16),
                          const SizedBox(width: 4),
                          Text('${workout.heartCount}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.copy, size: 16),
                          const SizedBox(width: 4),
                          Text('${workout.copyCount}'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (workout.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: workout.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.all(4),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
