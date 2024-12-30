import '../models/exercise_model.dart';

class SharedWorkoutModel {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String? description;
  final List<ExerciseModel> exercises;
  final DateTime createdAt;
  final int copyCount;
  final List<String> tags;
  final int heartCount;
  final List<String> heartedBy;

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
      'exercises': exercises
          .map((exercise) => {
                'id': exercise.id,
                'name': exercise.name,
                'description': exercise.description,
                'category': exercise.category,
                'musclesWorked': exercise.musclesWorked,
                // Exclude personal data like personalBestRecords and lastPerformed
              })
          .toList(),
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
              ?.map((exercise) => ExerciseModel(
                    id: exercise['id'] ?? '',
                    name: exercise['name'] ?? '',
                    description: exercise['description'],
                    category: exercise['category'],
                    musclesWorked:
                        List<String>.from(exercise['musclesWorked'] ?? []),
                    // Initialize empty personal data
                    personalBestRecords: [],
                    lastPerformed: null,
                  ))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
      copyCount: map['copyCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      heartCount: map['heartCount'] ?? 0,
      heartedBy: List<String>.from(map['heartedBy'] ?? []),
    );
  }

  SharedWorkoutModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? ownerName,
    String? description,
    List<ExerciseModel>? exercises,
    DateTime? createdAt,
    int? copyCount,
    List<String>? tags,
    int? heartCount,
    List<String>? heartedBy,
  }) {
    return SharedWorkoutModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      copyCount: copyCount ?? this.copyCount,
      tags: tags ?? this.tags,
      heartCount: heartCount ?? this.heartCount,
      heartedBy: heartedBy ?? this.heartedBy,
    );
  }
}
