import 'exercise.dart';

class Workout {
  final String id;
  String name;
  String muscleGroup;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name,
    required this.muscleGroup,
    List<Exercise>? exercises,
  }) : exercises = exercises ?? [];

  int get totalExercises => exercises.length;

  double get totalVolume {
    double volume = 0;

    for (final exercise in exercises) {
      volume += exercise.sets * exercise.reps * exercise.weight;
    }

    return volume;
  }
}