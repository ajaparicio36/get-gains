class ExerciseModel {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final List<String> muscleGroups;
  final double? personalBestWeight;
  final int? personalBestReps;
  final DateTime? lastPerformed;
  final String? notes;

  ExerciseModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.muscleGroups = const [],
    this.personalBestWeight,
    this.personalBestReps,
    this.lastPerformed,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'muscleGroups': muscleGroups,
      'personalBestWeight': personalBestWeight,
      'personalBestReps': personalBestReps,
      'lastPerformed': lastPerformed?.toIso8601String(),
      'notes': notes,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      category: map['category'],
      muscleGroups: List<String>.from(map['muscleGroups'] ?? []),
      personalBestWeight: map['personalBestWeight']?.toDouble(),
      personalBestReps: map['personalBestReps']?.toInt(),
      lastPerformed: map['lastPerformed'] != null
          ? DateTime.parse(map['lastPerformed'])
          : null,
      notes: map['notes'],
    );
  }

  ExerciseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<String>? muscleGroups,
    double? personalBestWeight,
    int? personalBestReps,
    DateTime? lastPerformed,
    String? notes,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      personalBestWeight: personalBestWeight ?? this.personalBestWeight,
      personalBestReps: personalBestReps ?? this.personalBestReps,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      notes: notes ?? this.notes,
    );
  }
}
