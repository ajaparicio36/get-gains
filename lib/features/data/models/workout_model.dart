import './workout_exercise_model.dart';

class WorkoutModel {
  final String id;
  final String name;
  final DateTime date;
  final List<WorkoutExercise> exercises;
  final bool isCompleted;
  final String? notes;
  final Duration? duration;

  WorkoutModel({
    required this.id,
    required this.name,
    required this.date,
    this.exercises = const [],
    this.isCompleted = false,
    this.notes,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'isCompleted': isCompleted,
      'notes': notes,
      'duration': duration?.inSeconds,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      date: DateTime.parse(map['date']),
      exercises: (map['exercises'] as List?)
              ?.map((exercise) => WorkoutExercise.fromMap(exercise))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'],
      duration:
          map['duration'] != null ? Duration(seconds: map['duration']) : null,
    );
  }

  WorkoutModel copyWith({
    String? id,
    String? name,
    DateTime? date,
    List<WorkoutExercise>? exercises,
    bool? isCompleted,
    String? notes,
    Duration? duration,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      duration: duration ?? this.duration,
    );
  }
}
