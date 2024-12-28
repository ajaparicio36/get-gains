import 'package:flutter/material.dart';
import '../../data/models/exercise_model.dart';
import 'package:intl/intl.dart';

class ExerciseDetailsScreen extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseDetailsScreen({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.7),
                          ),
                        ),
                        Text(
                          exercise.category ?? 'Uncategorized',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (exercise.musclesWorked.isNotEmpty) ...[
                          Text(
                            'Muscles Worked',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: exercise.musclesWorked
                                .map((group) => Chip(
                                      label: Text(group),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (exercise.description != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            exercise.description!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Personal Best Records Section
              Text(
                'Personal Best History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (exercise.personalBestRecords.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No personal best records yet'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercise.personalBestRecords.length,
                  itemBuilder: (context, index) {
                    final record = exercise.personalBestRecords[index];
                    final isLatest = index == 0;

                    return Card(
                      elevation: isLatest ? 2 : 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLatest
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${record.weight.toStringAsFixed(1)}kg × ${record.reps} reps',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: isLatest ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy').format(record.achievedAt),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7),
                            ),
                          ),
                          trailing: isLatest
                              ? Chip(
                                  label: const Text('Latest PB'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  labelStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),

              if (exercise.lastPerformed != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Last Performed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      title: Text(
                        DateFormat('MMMM d, yyyy')
                            .format(exercise.lastPerformed!),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
