class ExerciseSet {
  final double weight;
  final int reps;
  final bool isCompleted;
  final DateTime? timestamp;

  ExerciseSet({
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      weight: map['weight']?.toDouble() ?? 0.0,
      reps: map['reps']?.toInt() ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      timestamp:
          map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
    );
  }

  ExerciseSet copyWith({
    double? weight,
    int? reps,
    bool? isCompleted,
    DateTime? timestamp,
  }) {
    return ExerciseSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
