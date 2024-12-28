import 'personal_best_model.dart';

class ExerciseModel {
  static const int maxPersonalBestRecords = 5;

  final String id;
  final String name;
  final String? description;
  final String? category;
  final List<String> musclesWorked;
  final List<PersonalBestRecord> personalBestRecords;
  final DateTime? lastPerformed;
  final String? notes;

  ExerciseModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.musclesWorked = const [],
    this.personalBestRecords = const [],
    this.lastPerformed,
    this.notes,
  });

  // Getters for the most recent personal best
  PersonalBestRecord? get latestPersonalBest {
    if (personalBestRecords.isEmpty) return null;
    return personalBestRecords.reduce(
        (curr, next) => curr.achievedAt.isAfter(next.achievedAt) ? curr : next);
  }

  double? get personalBestWeight => latestPersonalBest?.weight;
  int? get personalBestReps => latestPersonalBest?.reps;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'musclesWorked': musclesWorked,
      'personalBestRecords':
          personalBestRecords.map((record) => record.toMap()).toList(),
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
      musclesWorked: List<String>.from(map['musclesWorked'] ?? []),
      personalBestRecords: (map['personalBestRecords'] as List?)
              ?.map((record) => PersonalBestRecord.fromMap(record))
              .toList() ??
          [],
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
    List<String>? musclesWorked,
    List<PersonalBestRecord>? personalBestRecords,
    DateTime? lastPerformed,
    String? notes,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      musclesWorked: musclesWorked ?? this.musclesWorked,
      personalBestRecords: personalBestRecords ?? this.personalBestRecords,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      notes: notes ?? this.notes,
    );
  }
}
