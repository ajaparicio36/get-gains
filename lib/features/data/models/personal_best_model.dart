class PersonalBestRecord {
  final double weight;
  final int reps;
  final DateTime achievedAt;

  PersonalBestRecord({
    required this.weight,
    required this.reps,
    required this.achievedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }

  factory PersonalBestRecord.fromMap(Map<String, dynamic> map) {
    return PersonalBestRecord(
      weight: map['weight']?.toDouble() ?? 0.0,
      reps: map['reps']?.toInt() ?? 0,
      achievedAt: DateTime.parse(map['achievedAt']),
    );
  }
}
