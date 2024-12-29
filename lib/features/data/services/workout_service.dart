import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../models/workout_exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../models/exercise_model.dart';
import '../models/personal_best_model.dart';

class WorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int MAX_SET_HISTORY = 6;

  // 1. Create a new workout
  Future<String> createWorkout(String userId, String workoutName) async {
    final workoutRef =
        _db.collection('users').doc(userId).collection('workouts').doc();

    final workout = WorkoutModel(
      id: workoutRef.id,
      name: workoutName,
      date: DateTime.now(),
    );

    await workoutRef.set(workout.toMap());
    return workoutRef.id;
  }

  Future<String> copyWorkout(String userId, String workoutId) async {
    // Get the original workout
    final originalWorkoutDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .get();

    final originalWorkout = WorkoutModel.fromMap(originalWorkoutDoc.data()!);

    // Create a new workout document reference
    final newWorkoutRef =
        _db.collection('users').doc(userId).collection('workouts').doc();

    // Create new workout with same name but current date and empty sets
    final newWorkout = WorkoutModel(
      id: newWorkoutRef.id,
      name:
          "${originalWorkout.name} (Copy)", // Optional: add (Copy) to differentiate
      date: DateTime.now(),
      exercises: originalWorkout.exercises
          .map((exercise) => WorkoutExercise(
                exerciseId: exercise.exerciseId,
                sets: [], // Initialize with empty sets
              ))
          .toList(),
    );

    // Save the new workout
    await newWorkoutRef.set(newWorkout.toMap());

    return newWorkoutRef.id;
  }

  Future<void> updateWorkoutName(
    String userId,
    String workoutId,
    String newName,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .update({'name': newName});
  }

  // 2. Add an exercise to the workout
  Future<void> addExerciseToWorkout(
    String userId,
    String workoutId,
    String exerciseId, // Either existing or newly created
  ) async {
    final workoutExercise = WorkoutExercise(
      exerciseId: exerciseId,
      sets: [], // Starts with no sets
    );

    await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .update({
      'exercises': FieldValue.arrayUnion([workoutExercise.toMap()]),
    });
  }

  Future<void> removeExerciseFromWorkout(
    String userId,
    String workoutId,
    String exerciseId,
  ) async {
    final workoutRef = _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId);

    final workoutDoc = await workoutRef.get();
    final workout = WorkoutModel.fromMap(workoutDoc.data()!);

    final updatedExercises = workout.exercises
        .where((exercise) => exercise.exerciseId != exerciseId)
        .toList();

    await workoutRef.update({
      'exercises': updatedExercises.map((e) => e.toMap()).toList(),
    });
  }

  // 3. Record a set for an exercise in a workout
  Future<void> recordSet(
    String userId,
    String workoutId,
    String exerciseId,
    ExerciseSet newSet,
  ) async {
    final workoutRef = _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId);

    final workoutDoc = await workoutRef.get();
    final workout = WorkoutModel.fromMap(workoutDoc.data()!);

    final updatedExercises = workout.exercises.map((exercise) {
      if (exercise.exerciseId == exerciseId) {
        var updatedSets = [...exercise.sets, newSet];
        // Keep only the last MAX_SET_HISTORY sets
        if (updatedSets.length > MAX_SET_HISTORY) {
          updatedSets =
              updatedSets.skip(updatedSets.length - MAX_SET_HISTORY).toList();
        }
        return exercise.copyWith(sets: updatedSets);
      }
      return exercise;
    }).toList();

    await workoutRef.update({
      'exercises': updatedExercises.map((e) => e.toMap()).toList(),
    });

    await updatePersonalBests(userId, exerciseId, newSet);
  }

  Future<void> editSet(
    String userId,
    String workoutId,
    String exerciseId,
    int setIndex,
    ExerciseSet updatedSet,
  ) async {
    final workoutRef = _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId);

    final workoutDoc = await workoutRef.get();
    final workout = WorkoutModel.fromMap(workoutDoc.data()!);

    final updatedExercises = workout.exercises.map((exercise) {
      if (exercise.exerciseId == exerciseId) {
        final updatedSets = List<ExerciseSet>.from(exercise.sets);
        if (setIndex < updatedSets.length) {
          updatedSets[setIndex] = updatedSet;
        }
        return exercise.copyWith(sets: updatedSets);
      }
      return exercise;
    }).toList();

    await workoutRef.update({
      'exercises': updatedExercises.map((e) => e.toMap()).toList(),
    });

    // Check if this edit creates a new personal best
    await updatePersonalBests(userId, exerciseId, updatedSet);
  }

  Future<void> deleteSet(
    String userId,
    String workoutId,
    String exerciseId,
    int setIndex,
  ) async {
    final workoutRef = _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId);

    final workoutDoc = await workoutRef.get();
    final workout = WorkoutModel.fromMap(workoutDoc.data()!);

    final updatedExercises = workout.exercises.map((exercise) {
      if (exercise.exerciseId == exerciseId) {
        final updatedSets = List<ExerciseSet>.from(exercise.sets);
        if (setIndex < updatedSets.length) {
          updatedSets.removeAt(setIndex);
        }
        return exercise.copyWith(sets: updatedSets);
      }
      return exercise;
    }).toList();

    await workoutRef.update({
      'exercises': updatedExercises.map((e) => e.toMap()).toList(),
    });
  }

  // 4. Update personal bests in exercise model
  Future<void> updatePersonalBests(
    String userId,
    String exerciseId,
    ExerciseSet newSet,
  ) async {
    final exerciseRef = _db
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId);

    final exerciseDoc = await exerciseRef.get();
    final exercise = ExerciseModel.fromMap(exerciseDoc.data()!);

    // Get current personal bests
    final currentBestWeight = exercise.personalBestWeight ?? 0;
    final currentBestReps = exercise.personalBestReps ?? 0;

    // Check if this set achieved a new personal best
    bool isNewPersonalBest = false;

    if (newSet.weight > currentBestWeight || newSet.reps > currentBestReps) {
      isNewPersonalBest = true;
    }

    if (isNewPersonalBest) {
      // Create new personal best record
      final newRecord = PersonalBestRecord(
        weight: newSet.weight,
        reps: newSet.reps,
        achievedAt: DateTime.now(),
      );

      // Get current records and add new one
      List<PersonalBestRecord> updatedRecords = [
        ...exercise.personalBestRecords,
        newRecord,
      ];

      // Sort by date, most recent first
      updatedRecords.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

      // Keep only the most recent 5 records
      if (updatedRecords.length > ExerciseModel.maxPersonalBestRecords) {
        updatedRecords =
            updatedRecords.take(ExerciseModel.maxPersonalBestRecords).toList();
      }

      // Update exercise document
      await exerciseRef.update({
        'personalBestRecords':
            updatedRecords.map((record) => record.toMap()).toList(),
        'lastPerformed': DateTime.now().toIso8601String(),
      });
    } else {
      // Just update the last performed date
      await exerciseRef.update({
        'lastPerformed': DateTime.now().toIso8601String(),
      });
    }
  }

  // 5. Get exercise history (for progress page)
  Stream<List<Map<String, dynamic>>> getExerciseHistory(
    String userId,
    String exerciseId,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .where('exercises.exerciseId', isEqualTo: exerciseId)
        .orderBy('date', descending: true)
        .limit(MAX_SET_HISTORY) // Limit the number of workouts queried
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final workout = WorkoutModel.fromMap(doc.data());
        final exercise =
            workout.exercises.firstWhere((e) => e.exerciseId == exerciseId);

        return {
          'date': workout.date,
          'sets': exercise.sets,
          'workoutName': workout.name,
        };
      }).toList();
    });
  }
}
