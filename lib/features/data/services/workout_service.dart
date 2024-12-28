import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../models/workout_exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../models/exercise_model.dart';

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

    // Update if new personal bests achieved
    if (newSet.weight > (exercise.personalBestWeight ?? 0)) {
      await exerciseRef.update({
        'personalBestWeight': newSet.weight,
        'lastPerformed': DateTime.now().toIso8601String(),
      });
    }

    if (newSet.reps > (exercise.personalBestReps ?? 0)) {
      await exerciseRef.update({
        'personalBestReps': newSet.reps,
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
