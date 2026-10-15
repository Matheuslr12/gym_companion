class WorkoutSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime completedAt;
  final int totalSets;
  final int totalExercises;

  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    required this.totalSets,
    required this.totalExercises,
  });
}
