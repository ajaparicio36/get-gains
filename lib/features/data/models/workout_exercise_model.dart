import "exercise_set_model.dart";

class WorkoutExercise {
  final String exerciseId;
  final List<ExerciseSet> sets;
  final String? notes;
  final bool isCompleted;

  WorkoutExercise({
    required this.exerciseId,
    required this.sets,
    this.notes,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] ?? '',
      sets: (map['sets'] as List?)
              ?.map((set) => ExerciseSet.fromMap(set))
              .toList() ??
          [],
      notes: map['notes'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    List<ExerciseSet>? sets,
    String? notes,
    bool? isCompleted,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
