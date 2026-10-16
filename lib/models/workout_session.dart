class ExerciseSetLog {
  final String exerciseId;
  final String exerciseName;
  final String primaryMuscle;
  final int setIndex;
  final double weight;
  final int reps;

  const ExerciseSetLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscle,
    required this.setIndex,
    required this.weight,
    required this.reps,
  });

  double get volume => weight * reps;
}

class WorkoutSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime completedAt;
  final int totalSets;
  final int totalExercises;
  final Duration duration;
  final double totalVolume;
  final List<ExerciseSetLog> setLogs;

  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    required this.totalSets,
    required this.totalExercises,
    this.duration = Duration.zero,
    this.totalVolume = 0,
    this.setLogs = const [],
  });
}