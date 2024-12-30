import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../models/shared_workout_model.dart';
import '../models/workout_exercise_model.dart';

class SharedWorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: constant_identifier_names
  static const int MAX_SEARCH_RESULTS = 10;

  Future<bool> toggleHeartWorkout(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final workoutRef = _db.collection('shared_workouts').doc(workoutId);

    return _db.runTransaction((transaction) async {
      final workoutDoc = await transaction.get(workoutRef);

      if (!workoutDoc.exists) {
        throw Exception('Workout not found');
      }

      final heartedBy =
          List<String>.from(workoutDoc.data()?['heartedBy'] ?? []);
      final currentHeartCount = workoutDoc.data()?['heartCount'] ?? 0;

      // Check if user already hearted
      final hasHearted = heartedBy.contains(userId);

      if (hasHearted) {
        // Remove heart
        transaction.update(workoutRef, {
          'heartedBy': FieldValue.arrayRemove([userId]),
          'heartCount': currentHeartCount - 1,
        });
        return false; // Returning false means the workout is no longer hearted
      } else {
        // Add heart
        transaction.update(workoutRef, {
          'heartedBy': FieldValue.arrayUnion([userId]),
          'heartCount': currentHeartCount + 1,
        });
        return true; // Returning true means the workout is now hearted
      }
    });
  }

  // Check if a workout is hearted by the current user
  Future<bool> isWorkoutHearted(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final workoutDoc =
        await _db.collection('shared_workouts').doc(workoutId).get();

    if (!workoutDoc.exists) return false;

    final heartedBy = List<String>.from(workoutDoc.data()?['heartedBy'] ?? []);
    return heartedBy.contains(userId);
  }

  // Get workouts hearted by the current user
  Stream<List<SharedWorkoutModel>> getHeartedWorkoutsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('shared_workouts')
        .where('heartedBy', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharedWorkoutModel.fromMap(doc.data()))
            .toList());
  }

  // Copy a shared workout to user's personal workouts
  Future<String> copyWorkout(String sharedWorkoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get the shared workout
    final sharedWorkoutDoc =
        await _db.collection('shared_workouts').doc(sharedWorkoutId).get();

    if (!sharedWorkoutDoc.exists) {
      throw Exception('Shared workout not found');
    }

    final sharedWorkout = SharedWorkoutModel.fromMap(sharedWorkoutDoc.data()!);

    // Start a batch write
    final batch = _db.batch();

    // Map to store new exercise IDs
    Map<String, String> exerciseIdMap = {};

    // 1. Copy exercises to user's exercise collection
    for (var exercise in sharedWorkout.exercises) {
      final exerciseRef =
          _db.collection('users').doc(userId).collection('exercises').doc();

      final newExercise = ExerciseModel(
        id: exerciseRef.id,
        name: exercise.name,
        description: exercise.description,
        category: exercise.category,
        musclesWorked: exercise.musclesWorked,
        // Initialize empty personal bests and timestamps
        personalBestRecords: [],
        lastPerformed: null,
      );

      batch.set(exerciseRef, newExercise.toMap());
      exerciseIdMap[exercise.id] = exerciseRef.id;
    }

    // 2. Create new workout in user's collection with workout exercises
    final newWorkoutRef =
        _db.collection('users').doc(userId).collection('workouts').doc();

    final newWorkout = WorkoutModel(
      id: newWorkoutRef.id,
      name: sharedWorkout.name,
      date: DateTime.now(),
      exercises: sharedWorkout.exercises
          .map((exercise) => WorkoutExercise(
                exerciseId: exerciseIdMap[exercise.id] ?? '',
                sets: [], // Start with empty sets
              ))
          .toList(),
    );

    batch.set(newWorkoutRef, newWorkout.toMap());

    // 3. Increment the copy count of the shared workout
    batch.update(sharedWorkoutDoc.reference, {
      'copyCount': FieldValue.increment(1),
    });

    // Execute all operations
    await batch.commit();

    // Return the ID of the newly created workout
    return newWorkoutRef.id;
  }

  // Get stream of shared workouts
  Stream<List<SharedWorkoutModel>> getSharedWorkoutsStream({
    String? searchQuery,
    List<String>? tags,
    int limit = 20,
  }) {
    Query query = _db
        .collection('shared_workouts')
        .orderBy('copyCount', descending: true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    return query.limit(limit).snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            SharedWorkoutModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<SharedWorkoutModel>> searchWorkouts({
    String? nameQuery,
    List<String>? tags,
    String? ownerName,
    SortOption sortBy = SortOption.mostCopied,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db.collection('shared_workouts');

    // Apply name search if provided
    if (nameQuery != null && nameQuery.isNotEmpty) {
      // Create array of search terms
      final searchTerms = nameQuery.toLowerCase().split(' ');

      // Search using the first term (can be enhanced with array-contains-any for multiple terms)
      query = query.where('searchTerms', arrayContains: searchTerms[0]);
    }

    // Apply tag filter if provided
    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    // Apply owner name filter if provided
    if (ownerName != null && ownerName.isNotEmpty) {
      query = query.where('ownerName', isEqualTo: ownerName);
    }

    // Apply sorting
    switch (sortBy) {
      case SortOption.mostCopied:
        query = query.orderBy('copyCount', descending: true);
        break;
      case SortOption.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case SortOption.alphabetical:
        query = query.orderBy('name');
        break;
      case SortOption.mostHearted:
        query = query.orderBy('heartCount', descending: true);
        break;
    }

    // Apply pagination if startAfter is provided
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Limit results
    query = query.limit(MAX_SEARCH_RESULTS);

    // Execute query
    final querySnapshot = await query.get();

    return querySnapshot.docs
        .map((doc) =>
            SharedWorkoutModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<TagWithCount>> getPopularTags({int limit = 10}) async {
    final aggregateQuery = await _db.collection('shared_workouts').get();

    // Count tag occurrences
    Map<String, int> tagCounts = {};
    for (var doc in aggregateQuery.docs) {
      final tags = List<String>.from(doc.data()['tags'] ?? []);
      for (var tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // Convert to list and sort
    final sortedTags = tagCounts.entries
        .map((e) => TagWithCount(tag: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return sortedTags.take(limit).toList();
  }

  // Helper method to update search terms when sharing a workout
  Future<void> _updateSearchTerms(String workoutId, String workoutName) async {
    // Create array of search terms (words) from the workout name
    final searchTerms = workoutName
        .toLowerCase()
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();

    await _db.collection('shared_workouts').doc(workoutId).update({
      'searchTerms': searchTerms,
    });
  }

  // Share a workout with search terms
  Future<void> shareWorkout({
    required String workoutId,
    String? description,
    List<String> tags = const [],
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get the workout and user data
    final workoutDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .get();

    final userDoc = await _db.collection('users').doc(userId).get();

    if (!workoutDoc.exists || !userDoc.exists) {
      throw Exception('Workout or user not found');
    }

    final workout = WorkoutModel.fromMap(workoutDoc.data()!);
    final ownerName = userDoc.data()?['displayName'] ??
        userDoc.data()?['username'] ??
        'Anonymous';

    // Fetch all exercise details
    List<ExerciseModel> exercises = [];
    for (var workoutExercise in workout.exercises) {
      final exerciseDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(workoutExercise.exerciseId)
          .get();

      if (exerciseDoc.exists) {
        exercises.add(ExerciseModel.fromMap({
          ...exerciseDoc.data()!,
          'id': exerciseDoc.id,
        }));
      }
    }

    // Create search terms from workout name
    final searchTerms = workout.name
        .toLowerCase()
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();

    // Create shared workout document
    final sharedWorkoutRef = _db.collection('shared_workouts').doc();
    final sharedWorkout = SharedWorkoutModel(
      id: sharedWorkoutRef.id,
      name: workout.name,
      ownerId: userId,
      ownerName: ownerName,
      description: description,
      exercises: exercises
          .map((exercise) => ExerciseModel(
                id: exercise.id,
                name: exercise.name,
                description: exercise.description,
                category: exercise.category,
                musclesWorked: exercise.musclesWorked,
                // Don't include personal bests or timestamps when sharing
              ))
          .toList(),
      createdAt: DateTime.now(),
      tags: tags,
      heartCount: 0,
      heartedBy: [],
    );

    // Add the workout with search terms
    await sharedWorkoutRef.set({
      ...sharedWorkout.toMap(),
      'searchTerms': searchTerms,
    });
  }

  Stream<List<SharedWorkoutModel>> getMySharedWorkoutsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('shared_workouts')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharedWorkoutModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> deleteSharedWorkout(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final workoutDoc =
        await _db.collection('shared_workouts').doc(workoutId).get();

    if (!workoutDoc.exists) {
      throw Exception('Workout not found');
    }

    final workout = SharedWorkoutModel.fromMap(workoutDoc.data()!);

    if (workout.ownerId != userId) {
      throw Exception('Unauthorized: You can only delete your own workouts');
    }

    await _db.collection('shared_workouts').doc(workoutId).delete();
  }
}

// Enums and helper classes
enum SortOption {
  mostCopied,
  newest,
  alphabetical,
  mostHearted,
}

class TagWithCount {
  final String tag;
  final int count;

  TagWithCount({
    required this.tag,
    required this.count,
  });
}
