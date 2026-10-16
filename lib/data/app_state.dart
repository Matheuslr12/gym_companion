import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState _instance = AppState._();

  factory AppState() => _instance;

  static const String _workoutsKey = 'gym_companion_workouts';
  static const String _sessionsKey = 'gym_companion_sessions';

  final List<Workout> _workouts = [];
  final List<WorkoutSession> _workoutSessions = [];

  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<WorkoutSession> get workoutSessions =>
      List.unmodifiable(_workoutSessions);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    final workoutsJson = preferences.getString(_workoutsKey);
    final sessionsJson = preferences.getString(_sessionsKey);

    _workouts.clear();
    _workoutSessions.clear();

    if (workoutsJson != null && workoutsJson.isNotEmpty) {
      final decoded = jsonDecode(workoutsJson) as List;

      for (final item in decoded) {
        _workouts.add(_workoutFromJson(item as Map<String, dynamic>));
      }
    }

    if (sessionsJson != null && sessionsJson.isNotEmpty) {
      final decoded = jsonDecode(sessionsJson) as List;

      for (final item in decoded) {
        _workoutSessions.add(
          _sessionFromJson(item as Map<String, dynamic>),
        );
      }
    }

    notifyListeners();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _workoutsKey,
      jsonEncode(_workouts.map(_workoutToJson).toList()),
    );

    await preferences.setString(
      _sessionsKey,
      jsonEncode(_workoutSessions.map(_sessionToJson).toList()),
    );
  }

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
    _save();
  }

  void addWorkout(Workout workout) {
    _workouts.add(workout);
    notifyListeners();
    _save();
  }

  void removeWorkout(String workoutId) {
    _workouts.removeWhere((workout) => workout.id == workoutId);
    notifyListeners();
    _save();
  }

  void addExercise({
    required String workoutId,
    required Exercise exercise,
  }) {
    final index = _workouts.indexWhere((workout) => workout.id == workoutId);

    if (index != -1) {
      _workouts[index].exercises.add(exercise);
      notifyListeners();
      _save();
    }
  }

  void removeExercise({
    required String workoutId,
    required String exerciseId,
  }) {
    final index = _workouts.indexWhere((workout) => workout.id == workoutId);

    if (index != -1) {
      _workouts[index].exercises.removeWhere(
        (exercise) => exercise.id == exerciseId,
      );

      notifyListeners();
      _save();
    }
  }

  Map<String, dynamic> _exerciseToJson(Exercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'bodyPart': exercise.bodyPart,
      'primaryMuscle': exercise.primaryMuscle,
      'secondaryMuscle': exercise.secondaryMuscle,
      'sets': exercise.sets,
      'reps': exercise.reps,
    };
  }

  Exercise _exerciseFromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      bodyPart: json['bodyPart'] as String,
      primaryMuscle: json['primaryMuscle'] as String,
      secondaryMuscle: json['secondaryMuscle'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
    );
  }

  Map<String, dynamic> _workoutToJson(Workout workout) {
    return {
      'id': workout.id,
      'name': workout.name,
      'muscleGroup': workout.muscleGroup,
      'exercises': workout.exercises.map(_exerciseToJson).toList(),
    };
  }

  Workout _workoutFromJson(Map<String, dynamic> json) {
    final exercises = (json['exercises'] as List)
        .map(
          (item) => _exerciseFromJson(item as Map<String, dynamic>),
        )
        .toList();

    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      exercises: exercises,
    );
  }

  Map<String, dynamic> _setLogToJson(ExerciseSetLog log) {
    return {
      'exerciseId': log.exerciseId,
      'exerciseName': log.exerciseName,
      'primaryMuscle': log.primaryMuscle,
      'setIndex': log.setIndex,
      'weight': log.weight,
      'reps': log.reps,
    };
  }

  ExerciseSetLog _setLogFromJson(Map<String, dynamic> json) {
    return ExerciseSetLog(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      primaryMuscle: json['primaryMuscle'] as String,
      setIndex: json['setIndex'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
    );
  }

  Map<String, dynamic> _sessionToJson(WorkoutSession session) {
    return {
      'id': session.id,
      'workoutId': session.workoutId,
      'workoutName': session.workoutName,
      'completedAt': session.completedAt.toIso8601String(),
      'totalSets': session.totalSets,
      'totalExercises': session.totalExercises,
      'duration': session.duration.inMilliseconds,
      'totalVolume': session.totalVolume,
      'setLogs': session.setLogs.map(_setLogToJson).toList(),
    };
  }

  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    final logs = (json['setLogs'] as List)
        .map(
          (item) => _setLogFromJson(item as Map<String, dynamic>),
        )
        .toList();

    return WorkoutSession(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      totalSets: json['totalSets'] as int,
      totalExercises: json['totalExercises'] as int,
      duration: Duration(milliseconds: json['duration'] as int),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      setLogs: logs,
    );
  }
}