import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/progress_service.dart';
import '../../data/models/workout_model.dart';
import '../../data/models/exercise_model.dart';
import '../../../app/constants/colors.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/workout_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final PageController _pageController = PageController();
  final ProgressService _progressService = ProgressService();
  final FirestoreService _firestoreService = FirestoreService();
  final WorkoutService _workoutService = WorkoutService();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          Row(
            children: [
              Text(
                '${_currentPage + 1}/2',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          _buildMainProgressView(),
          _buildMuscleDistributionView(),
        ],
      ),
    );
  }

  Widget _buildMainProgressView() {
    return StreamBuilder<List<WorkoutModel>>(
      stream: _workoutService
          .getRecentWorkoutsStream(_firestoreService.currentUserId!),
      builder: (context, workoutSnapshot) {
        if (workoutSnapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (!workoutSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = workoutSnapshot.data!;
        final streak = _progressService.calculateWorkoutStreak(workouts);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStreakCard(streak),
              const SizedBox(height: 16),
              _buildPersonalBestsCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(int streak) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$streak days',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              streak == 0
                  ? 'Start working out to build your streak!'
                  : 'Keep going! You\'re doing great!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalBestsCard() {
    return StreamBuilder<List<ExerciseModel>>(
      stream: _firestoreService.getExercisesStream(),
      builder: (context, exerciseSnapshot) {
        if (!exerciseSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final exercises = exerciseSnapshot.data!;
        final pbData = _progressService.getPersonalBestsOverTime(exercises, 30);

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Bests (Last 30 Days)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 7,
                            getTitlesWidget: (value, meta) {
                              if (value % 7 == 0) {
                                return Text('${value.toInt()}d');
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: pbData,
                          isCurved: true,
                          color: AppColors.secondaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.secondaryColor.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMuscleDistributionView() {
    return StreamBuilder<List<WorkoutModel>>(
      stream: _workoutService
          .getRecentWorkoutsStream(_firestoreService.currentUserId!),
      builder: (context, workoutSnapshot) {
        return StreamBuilder<List<ExerciseModel>>(
          stream: _firestoreService.getExercisesStream(),
          builder: (context, exerciseSnapshot) {
            if (!workoutSnapshot.hasData || !exerciseSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final workouts = workoutSnapshot.data!;
            final exercises = exerciseSnapshot.data!;
            final muscleData = _progressService.calculateMuscleDistribution(
                workouts, exercises);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muscles Worked',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: muscleData
                            .map(
                              (data) => PieChartSectionData(
                                color: data.color,
                                value: data.percentage,
                                title: '',
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            .toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: muscleData.map((data) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: data.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      data.muscle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${data.percentage.toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
