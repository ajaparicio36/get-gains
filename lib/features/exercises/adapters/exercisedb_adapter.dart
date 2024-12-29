import '../../data/models/exercise_model.dart';

class ExerciseApiAdapter {
  // Set of all available muscles in your model
  static final Set<String> _availableMuscles = _muscleMapping.values.toSet();

  // Mapping from API muscle names to your model's muscle categories
  static final Map<String, String> _muscleMapping = {
    // Chest mappings
    'chest': 'Mid/Lower Chest',
    'pectorals': 'Mid/Lower Chest',
    'upper chest': 'Upper Chest',

    // Back mappings
    'latissimus dorsi': 'Lats',
    'lats': 'Lats',
    'upper back': 'Upper Back',
    'trapezius': 'Upper Back',
    'traps': 'Upper Back',
    'rhomboids': 'Upper Back',

    // Shoulder mappings
    'deltoids': 'Side Delts',
    'delts': 'Side Delts',
    'rear deltoids': 'Rear Delts',
    'anterior deltoids': 'Front Delts',

    // Arm mappings
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'forearms': 'Forearms',
    'wrist flexors': 'Forearms',
    'wrist extensors': 'Forearms',

    // Core mappings
    'abs': 'Abs',
    'abdominals': 'Abs',
    'lower abs': 'Abs',

    // Leg mappings
    'quadriceps': 'Quads',
    'quads': 'Quads',
    'hamstrings': 'Hamstrings',
    'calves': 'Calves',
    'soleus': 'Calves',
    'glutes': 'Glutes',
  };

  // Convert API exercise data to your ExerciseModel
  static ExerciseModel fromApiResponse(Map<String, dynamic> apiResponse) {
    final data = apiResponse['data'];

    // Extract and map muscles
    List<String> mappedMuscles = [];

    // Handle primary target muscles
    if (data['targetMuscles'] != null) {
      mappedMuscles
          .addAll(_mapMuscles(List<String>.from(data['targetMuscles'])));
    }

    // Handle secondary muscles
    if (data['secondaryMuscles'] != null) {
      mappedMuscles
          .addAll(_mapMuscles(List<String>.from(data['secondaryMuscles'])));
    }

    // Remove duplicates and invalid mappings
    mappedMuscles = mappedMuscles.toSet().toList();

    // Create description from instructions
    String? description;
    if (data['instructions'] != null) {
      description = (data['instructions'] as List<dynamic>).join('\n');
    }

    // Create the exercise model
    return ExerciseModel(
      id: data['exerciseId'] ?? '',
      name: data['name'] ?? '',
      description: description,
      musclesWorked: mappedMuscles,
      category: _determineCategory(mappedMuscles),
      personalBestRecords: [], // Initialize empty as this comes from user data
    );
  }

  // Helper method to map API muscle names to your model's muscle categories
  static List<String> _mapMuscles(List<String> apiMuscles) {
    return apiMuscles
        .map((muscle) => _muscleMapping[muscle.toLowerCase()])
        .where((muscle) => muscle != null)
        .cast<String>()
        .toList();
  }

  // Helper method to determine the exercise category based on muscles worked
  static String? _determineCategory(List<String> musclesWorked) {
    if (musclesWorked.isEmpty) return null;

    // Simple category determination based on the first mapped muscle
    // You might want to implement more sophisticated logic here
    final primaryMuscle = musclesWorked.first;

    if (primaryMuscle.contains('Chest')) return 'Chest';
    if (primaryMuscle.contains('Back') || primaryMuscle == 'Lats')
      return 'Back';
    if (primaryMuscle.contains('Delt')) return 'Shoulders';
    if (primaryMuscle == 'Biceps' ||
        primaryMuscle == 'Triceps' ||
        primaryMuscle == 'Forearms') return 'Arms';
    if (primaryMuscle == 'Abs') return 'Core';
    if (primaryMuscle == 'Quads' ||
        primaryMuscle == 'Hamstrings' ||
        primaryMuscle == 'Calves' ||
        primaryMuscle == 'Glutes') return 'Legs';

    return null;
  }

  // Helper method to validate if a muscle exists in your model
  static bool isValidMuscle(String muscle) {
    return _availableMuscles.contains(muscle);
  }
}
