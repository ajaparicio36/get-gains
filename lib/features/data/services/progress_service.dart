import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../../../app/constants/colors.dart';

class ProgressService {
  // Calculate streak of workouts (consecutive days)
  int calculateWorkoutStreak(List<WorkoutModel> workouts) {
    if (workouts.isEmpty) return 0;

    // Sort workouts by date, most recent first
    final sortedWorkouts = workouts.where((w) => w.isCompleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedWorkouts.isEmpty) return 0;

    int streak = 1;
    final now = DateTime.now();
    var lastWorkout = sortedWorkouts[0].date;

    // If the last workout wasn't today or yesterday, streak is broken
    if (now.difference(lastWorkout).inDays > 1) return 0;

    // Calculate streak by checking consecutive days
    for (var i = 0; i < sortedWorkouts.length - 1; i++) {
      final difference =
          sortedWorkouts[i].date.difference(sortedWorkouts[i + 1].date).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // Get personal bests achieved in last n days
  List<FlSpot> getPersonalBestsOverTime(
    List<ExerciseModel> exercises,
    int days,
  ) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    // Create a map to store personal bests count by date
    Map<DateTime, int> pbsByDate = {};

    // Count personal bests for each day
    for (var exercise in exercises) {
      for (var pb in exercise.personalBestRecords) {
        if (pb.achievedAt.isAfter(startDate)) {
          final date = DateTime(
              pb.achievedAt.year, pb.achievedAt.month, pb.achievedAt.day);
          pbsByDate[date] = (pbsByDate[date] ?? 0) + 1;
        }
      }
    }

    // Convert to list of FlSpots for fl_chart
    List<FlSpot> spots = [];
    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i - 1));
      final dateKey = DateTime(date.year, date.month, date.day);
      spots.add(FlSpot(i.toDouble(), (pbsByDate[dateKey] ?? 0).toDouble()));
    }

    return spots;
  }

  // Calculate muscle group distribution
  List<MuscleWorkData> calculateMuscleDistribution(
      List<WorkoutModel> workouts, List<ExerciseModel> exercises) {
    Map<String, int> muscleCount = {};
    int totalExercises = 0;

    // Count exercises per muscle group
    for (var workout in workouts.where((w) => w.isCompleted)) {
      for (var workoutExercise in workout.exercises) {
        final exercise = exercises.firstWhere(
          (e) => e.id == workoutExercise.exerciseId,
          orElse: () => ExerciseModel(id: '', name: ''),
        );

        for (var muscle in exercise.musclesWorked) {
          muscleCount[muscle] = (muscleCount[muscle] ?? 0) + 1;
          totalExercises++;
        }
      }
    }

    // Convert to percentage and create data objects
    List<MuscleWorkData> muscleData = muscleCount.entries.map((entry) {
      return MuscleWorkData(
        muscle: entry.key,
        percentage: (entry.value / totalExercises) * 100,
        color: _getMuscleColor(entry.key),
      );
    }).toList();

    // Sort by percentage descending
    muscleData.sort((a, b) => b.percentage.compareTo(a.percentage));

    return muscleData;
  }

  // Helper method to assign colors to muscle groups
  Color _getMuscleColor(String muscle) {
    final colors = [
      AppColors.primaryColor,
      AppColors.primaryLight,
      AppColors.secondaryColor,
      AppColors.secondaryLight,
      AppColors.primaryDark,
      AppColors.secondaryDark,
      AppColors.errorColor,
      AppColors.successColor,
    ];

    // Generate a consistent index for each muscle name
    final index = muscle.hashCode % colors.length;
    return colors[index];
  }
}

// Data class for muscle work distribution
class MuscleWorkData {
  final String muscle;
  final double percentage;
  final Color color;

  MuscleWorkData({
    required this.muscle,
    required this.percentage,
    required this.color,
  });
}
