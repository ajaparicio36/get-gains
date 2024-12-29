import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/data/services/firestore_service.dart';
import '../../features/data/models/user_model.dart';
import '../constants/colors.dart';
import '../../features/workout/screens/workout_screen.dart';
import '../../features/exercises/screens/exercises_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import 'loading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Get Gains',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: StreamBuilder<UserModel?>(
        stream: firestoreService.getUserStream(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondaryColor,
                        AppColors.secondaryDark,
                      ],
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (user?.username ?? user?.displayName ?? 'U')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  accountName: Text(user?.displayName ?? 'User'),
                  accountEmail: Text('@${user?.username ?? ''}'),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.home),
                              title: const Text('Home'),
                              onTap: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => const HomeScreen()),
                                  (Route<dynamic> route) =>
                                      false, // This removes all previous routes
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.fitness_center),
                              title: const Text('Workouts'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutsScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.sports_gymnastics),
                              title: const Text('Exercises'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExercisesScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Share'),
                              onTap: () {
                                // Handle share
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('Report Issue'),
                        onTap: () {
                          // Handle report
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Sign Out'),
                        onTap: () {
                          Navigator.pop(context);
                          FirebaseAuth.instance.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }

          final user = snapshot.data;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section with Username
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
                                AppColors.secondaryColor.withOpacity(0.8),
                                AppColors.secondaryDark.withOpacity(1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back,',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '@${user?.username ?? user?.displayName ?? 'User'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.9),
                                      child: Text(
                                        (user?.username ??
                                                user?.displayName ??
                                                'U')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.secondaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ready to crush your fitness goals today?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // Modified Quick Actions - 2 cards in a row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.8),
                                    AppColors.primaryLight.withOpacity(1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _QuickActionCard(
                                icon: Icons.fitness_center,
                                title: 'Start a Workout',
                                color: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WorkoutsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.secondaryColor.withOpacity(0.8),
                                    AppColors.secondaryDark.withOpacity(1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _QuickActionCard(
                                icon: Icons.track_changes,
                                title: 'Track Progress',
                                color: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProgressScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.secondaryColor.withOpacity(0.8),
                                    AppColors.secondaryDark.withOpacity(1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _QuickActionCard(
                                icon: Icons.sports_gymnastics,
                                title: 'Exercises',
                                color: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExercisesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.8),
                                    AppColors.primaryDark.withOpacity(1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _QuickActionCard(
                                icon: Icons.book,
                                title: 'Browse Workouts',
                                color: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExercisesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ), // Empty space for symmetry
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
