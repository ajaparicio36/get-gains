import '../models/workout_exercise_model.dart';

class SharedWorkoutModel {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String? description;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final int copyCount;
  final List<String> tags;
  final int heartCount;
  final List<String> heartedBy; // List of user IDs who hearted this workout

  SharedWorkoutModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    this.description,
    required this.exercises,
    required this.createdAt,
    this.copyCount = 0,
    this.tags = const [],
    this.heartCount = 0,
    this.heartedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'description': description,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'copyCount': copyCount,
      'tags': tags,
      'heartCount': heartCount,
      'heartedBy': heartedBy,
    };
  }

  factory SharedWorkoutModel.fromMap(Map<String, dynamic> map) {
    return SharedWorkoutModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      description: map['description'],
      exercises: (map['exercises'] as List?)
              ?.map((exercise) => WorkoutExercise.fromMap(exercise))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
      copyCount: map['copyCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      heartCount: map['heartCount'] ?? 0,
      heartedBy: List<String>.from(map['heartedBy'] ?? []),
    );
  }
}
