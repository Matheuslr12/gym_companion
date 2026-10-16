import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState _instance = AppState._();

  factory AppState() => _instance;

  final List<Workout> _workouts = [];
  final List<WorkoutSession> _workoutSessions = [];

  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<WorkoutSession> get workoutSessions =>
      List.unmodifiable(_workoutSessions);

  List<WorkoutSession> sessionsInRange(DateTime start, DateTime end) {
    final sessions = _workoutSessions.where((session) {
      return !session.completedAt.isBefore(start) &&
          session.completedAt.isBefore(end);
    }).toList();

    sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.unmodifiable(sessions);
  }

  List<WorkoutSession> get sessionsThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return sessionsInRange(
      startOfWeek,
      startOfWeek.add(const Duration(days: 7)),
    );
  }

  int get setsCompletedThisWeek =>
      sessionsThisWeek.fold(0, (total, session) => total + session.totalSets);

  void recordWorkoutCompletion({
    required Workout workout,
    required int totalSets,
    required Duration duration,
    required List<ExerciseSetLog> setLogs,
  }) {
    final volume = setLogs.fold<double>(
      0,
      (total, log) => total + log.volume,
    );

    _workoutSessions.add(
      WorkoutSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        workoutId: workout.id,
        workoutName: workout.name,
        completedAt: DateTime.now(),
        totalSets: totalSets,
        totalExercises: workout.exercises.length,
        duration: duration,
        totalVolume: volume,
        setLogs: List.unmodifiable(setLogs),
      ),
    );
    notifyListeners();
  }

  void addWorkout(Workout workout) {
    _workouts.add(workout);
    notifyListeners();
  }

  void removeWorkout(String workoutId) {
    _workouts.removeWhere((workout) => workout.id == workoutId);
    notifyListeners();
  }

  void addExercise({required String workoutId, required Exercise exercise}) {
    final index = _workouts.indexWhere((workout) => workout.id == workoutId);

    if (index != -1) {
      _workouts[index].exercises.add(exercise);
      notifyListeners();
    }
  }

  void removeExercise({required String workoutId, required String exerciseId}) {
    final index = _workouts.indexWhere((workout) => workout.id == workoutId);

    if (index != -1) {
      _workouts[index].exercises.removeWhere(
        (exercise) => exercise.id == exerciseId,
      );

      notifyListeners();
    }
  }
}