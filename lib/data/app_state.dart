import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/workout.dart';

class AppState extends ChangeNotifier {
  final List<Workout> _workouts = [];

  List<Workout> get workouts => List.unmodifiable(_workouts);

  void addWorkout(Workout workout) {
    _workouts.add(workout);
    notifyListeners();
  }

  void removeWorkout(String workoutId) {
    _workouts.removeWhere((workout) => workout.id == workoutId);
    notifyListeners();
  }

  void addExercise({
    required String workoutId,
    required Exercise exercise,
  }) {
    final index = _workouts.indexWhere(
      (workout) => workout.id == workoutId,
    );

    if (index != -1) {
      _workouts[index].exercises.add(exercise);
      notifyListeners();
    }
  }

  void removeExercise({
    required String workoutId,
    required String exerciseId,
  }) {
    final index = _workouts.indexWhere(
      (workout) => workout.id == workoutId,
    );

    if (index != -1) {
      _workouts[index].exercises.removeWhere(
            (exercise) => exercise.id == exerciseId,
          );

      notifyListeners();
    }
  }
}