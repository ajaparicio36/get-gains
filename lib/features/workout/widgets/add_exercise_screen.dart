// add_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workout_service.dart';

class AddExerciseScreen extends StatefulWidget {
  final String workoutId;

  const AddExerciseScreen({
    super.key,
    required this.workoutId,
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final exercises = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .get();

    final categories = exercises.docs
        .map((doc) => ExerciseModel.fromMap(doc.data()).category)
        .where((category) => category != null)
        .toSet()
        .toList();

    setState(() {
      _categories = ['All', ...categories.whereType<String>()];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add Exercise',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            // Category filter
            SizedBox(
              height: 60,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            // Exercise list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('exercises')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var exercises = snapshot.data!.docs
                      .map((doc) => ExerciseModel.fromMap(
                          doc.data() as Map<String, dynamic>))
                      .toList();

                  // Apply category filter
                  if (_selectedCategory != 'All') {
                    exercises = exercises
                        .where((exercise) =>
                            exercise.category == _selectedCategory)
                        .toList();
                  }

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    exercises = exercises
                        .where((exercise) => exercise.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();
                  }

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
                          const Text('No exercises found'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Card(
                        child: ListTile(
                          title: Text(exercise.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exercise.category ?? 'Uncategorized'),
                              if (exercise.personalBestWeight != null ||
                                  exercise.personalBestReps != null)
                                Text(
                                  'PB: ${exercise.personalBestWeight?.toStringAsFixed(1)}kg × ${exercise.personalBestReps} reps',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              await _workoutService.addExerciseToWorkout(
                                userId,
                                widget.workoutId,
                                exercise.id,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
