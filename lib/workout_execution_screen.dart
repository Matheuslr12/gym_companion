import 'dart:async';

import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'models/exercise.dart';
import 'models/workout.dart';
import 'models/workout_session.dart';
import 'services/notification_service.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final AppState appState;
  final Workout workout;

  const WorkoutExecutionScreen({
    super.key,
    required this.appState,
    required this.workout,
  });

  @override
  State<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen>
    with WidgetsBindingObserver {
  static const int _restDuration = 60;

  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<bool>> _completedSets = {};
  final List<ExerciseSetLog> _setLogs = [];

  Timer? _elapsedTimer;
  Timer? _restTimer;

  Duration _elapsed = Duration.zero;
  int _remainingSeconds = 0;
  DateTime? _restEndTime;

  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  bool _isPaused = false;

  Exercise get _currentExercise =>
      widget.workout.exercises[_currentExerciseIndex];

  List<bool> get _currentExerciseSets =>
      _completedSets[_currentExercise.id]!;

  bool get _currentSetCompleted => _currentExerciseSets[_currentSetIndex];

  int get _totalSets => widget.workout.exercises.fold(
        0,
        (total, exercise) => total + exercise.sets,
      );

  int get _doneSets => _completedSets.values.fold(
        0,
        (total, sets) => total + sets.where((done) => done).length,
      );

  bool get _workoutCompleted => _totalSets > 0 && _doneSets == _totalSets;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    for (final exercise in widget.workout.exercises) {
      _weightControllers[exercise.id] = List.generate(
        exercise.sets,
        (_) => TextEditingController(),
      );

      _repsControllers[exercise.id] = List.generate(
        exercise.sets,
        (_) => TextEditingController(text: exercise.reps.toString()),
      );

      _completedSets[exercise.id] = List.filled(exercise.sets, false);
    }

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isPaused) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });

    NotificationService.requestPermissions().then((_) {
      if (mounted) _showActiveWorkoutNotification();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRestTimerAfterReturn();
    }
  }

  void _updateRestTimerAfterReturn() {
    if (_restEndTime == null) return;

    final remaining = _restEndTime!.difference(DateTime.now()).inSeconds;

    if (remaining <= 0) {
      _restTimer?.cancel();
      _restEndTime = null;

      if (mounted) {
        setState(() => _remainingSeconds = 0);
        _showActiveWorkoutNotification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descanso concluído. Prepare a próxima série!'),
          ),
        );
      }
    } else if (mounted) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: _buildAppBar(),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildWorkoutProgress(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _buildFocusedExercise(
                    key: ValueKey(
                      '${_currentExercise.id}-$_currentSetIndex',
                    ),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF080808),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      toolbarHeight: 68,
      title: Row(
        children: [
          IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'TREINO EM EXECUÇÃO',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showExercisePicker,
            tooltip: 'Lista de exercícios',
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutProgress() {
    final progress = _totalSets == 0 ? 0.0 : _doneSets / _totalSets;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF242424),
              color: const Color(0xFFCCFF00),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXERCÍCIO ${_currentExerciseIndex + 1} DE ${widget.workout.exercises.length}',
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$_doneSets/$_totalSets SÉRIES',
                style: const TextStyle(
                  color: Color(0xFFCCFF00),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusedExercise({required Key key}) {
    final exercise = _currentExercise;
    final completedInExercise =
        _currentExerciseSets.where((done) => done).length;

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _currentExerciseIndex > 0
                    ? () => _selectExercise(_currentExerciseIndex - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF181818),
                  disabledBackgroundColor: const Color(0xFF101010),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      exercise.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${exercise.primaryMuscle} • $completedInExercise/${exercise.sets} séries concluídas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _currentExerciseIndex <
                        widget.workout.exercises.length - 1
                    ? () => _selectExercise(_currentExerciseIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF181818),
                  disabledBackgroundColor: const Color(0xFF101010),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildExerciseStage(exercise),
          if (_remainingSeconds > 0) ...[
            const SizedBox(height: 16),
            _buildRestTimer(),
          ],
          const SizedBox(height: 20),
          _buildCurrentSetMetrics(exercise),
          const SizedBox(height: 8),
          const Text(
            'TOQUE NA CARGA OU NAS REPETIÇÕES PARA MODIFICAR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _copyCurrentWeightToAll(exercise),
            icon: const Icon(Icons.copy_all_outlined, size: 17),
            label: const Text('USAR ESTA CARGA EM TODAS AS SÉRIES'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCCFF00),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildDoneButton(),
          const SizedBox(height: 18),
          _buildSetSelector(exercise),
          const SizedBox(height: 16),
          _buildExerciseDots(),
        ],
      ),
    );
  }

  Widget _buildExerciseStage(Exercise exercise) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFFCCFF00),
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'DEMONSTRAÇÃO DO EXERCÍCIO EM BREVE',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSetMetrics(Exercise exercise) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SetValue(
              label: 'SÉRIE',
              child: Text(
                '${_currentSetIndex + 1}/${exercise.sets}',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const _ValueDivider(),
          Expanded(
            child: _SetValue(
              label: 'REPETIÇÕES',
              child: TextField(
                controller: _repsControllers[exercise.id]![_currentSetIndex],
                enabled: !_currentSetCompleted,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
                decoration: _metricInputDecoration('${exercise.reps}'),
              ),
            ),
          ),
          const _ValueDivider(),
          Expanded(
            child: _SetValue(
              label: 'CARGA (KG)',
              child: TextField(
                controller:
                    _weightControllers[exercise.id]![_currentSetIndex],
                enabled: !_currentSetCompleted,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
                decoration: _metricInputDecoration('0'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _metricInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCFF00), width: 2),
        ),
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      );

  Widget _buildRestTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = _remainingSeconds / _restDuration;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: Colors.black.withValues(alpha: 0.16),
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESCANSO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _skipRest,
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text(
              'PULAR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    final completed = _currentSetCompleted;

    return Semantics(
      button: true,
      label: completed ? 'Reabrir série' : 'Concluir série',
      child: InkWell(
        onTap: completed ? _reopenCurrentSet : _completeCurrentSet,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 138,
          height: 138,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: completed
                ? const Color(0xFF252525)
                : const Color(0xFFCCFF00),
            shape: BoxShape.circle,
            boxShadow: completed
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFCCFF00).withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                completed ? Icons.undo_rounded : Icons.check_rounded,
                color: completed ? Colors.white : Colors.black,
                size: 34,
              ),
              const SizedBox(height: 5),
              Text(
                completed ? 'REABRIR' : 'CONCLUÍR',
                style: TextStyle(
                  color: completed ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetSelector(Exercise exercise) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(exercise.sets, (index) {
        final selected = index == _currentSetIndex;
        final completed = _completedSets[exercise.id]![index];

        return GestureDetector(
          onTap: () => setState(() => _currentSetIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selected ? 32 : 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFFCCFF00)
                  : selected
                      ? Colors.white
                      : const Color(0xFF343434),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExerciseDots() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              List.generate(widget.workout.exercises.length, (index) {
            final exercise = widget.workout.exercises[index];
            final done = _completedSets[exercise.id]!.every((value) => value);
            final selected = index == _currentExerciseIndex;

            return GestureDetector(
              onTap: () => _selectExercise(index),
              child: Container(
                width: selected ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFCCFF00)
                      : selected
                          ? Colors.white
                          : const Color(0xFF303030),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Text(
          '${_currentExerciseIndex + 1} DE ${widget.workout.exercises.length} EXERCÍCIOS',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF252525))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(
                    _isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(_isPaused ? 'CONTINUAR' : 'PAUSAR'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Container(width: 1, color: const Color(0xFF292929)),
              Expanded(
                child: Center(
                  child: Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      color: Color(0xFFCCFF00),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: const Color(0xFF292929)),
              Expanded(
                child: TextButton(
                  onPressed: _workoutCompleted ? _finishWorkout : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCCFF00),
                    disabledForegroundColor: const Color(0xFF555555),
                  ),
                  child: const Text(
                    'FINALIZAR',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);

    if (_isPaused) {
      NotificationService.showPausedWorkout(
        exerciseName: _currentExercise.name,
        elapsed: _elapsed,
      );
    } else if (_remainingSeconds > 0) {
      NotificationService.showRestProgress(
        exerciseName: _currentExercise.name,
      );
    } else {
      _showActiveWorkoutNotification();
    }
  }

  void _showActiveWorkoutNotification() {
    NotificationService.showActiveWorkout(
      exerciseName: _currentExercise.name,
      elapsed: _elapsed,
    );
  }

  void _selectExercise(int index) {
    if (index < 0 || index >= widget.workout.exercises.length) return;

    final exercise = widget.workout.exercises[index];
    final sets = _completedSets[exercise.id]!;
    final firstOpen = sets.indexWhere((done) => !done);

    setState(() {
      _currentExerciseIndex = index;
      _currentSetIndex = firstOpen >= 0 ? firstOpen : sets.length - 1;
    });

    if (!_isPaused && _remainingSeconds == 0) {
      _showActiveWorkoutNotification();
    }
  }

  void _copyCurrentWeightToAll(Exercise exercise) {
    final current =
        _weightControllers[exercise.id]![_currentSetIndex].text.trim();

    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a carga desta série primeiro.')),
      );
      return;
    }

    setState(() {
      final controllers = _weightControllers[exercise.id]!;

      for (var index = 0; index < controllers.length; index++) {
        if (!_completedSets[exercise.id]![index]) {
          controllers[index].text = current;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Carga de $current kg aplicada às séries abertas.'),
      ),
    );
  }

  void _completeCurrentSet() {
    FocusScope.of(context).unfocus();

    final exercise = _currentExercise;

    final weight = double.tryParse(
      _weightControllers[exercise.id]![_currentSetIndex]
          .text
          .replaceAll(',', '.'),
    );

    final reps = int.tryParse(
      _repsControllers[exercise.id]![_currentSetIndex].text,
    );

    if (weight == null || weight < 0 || reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe carga e repetições válidas.')),
      );
      return;
    }

    _setLogs.removeWhere(
      (log) =>
          log.exerciseId == exercise.id &&
          log.setIndex == _currentSetIndex,
    );

    _setLogs.add(
      ExerciseSetLog(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        primaryMuscle: exercise.primaryMuscle,
        setIndex: _currentSetIndex,
        weight: weight,
        reps: reps,
      ),
    );

    setState(() {
      _completedSets[exercise.id]![_currentSetIndex] = true;
    });

    if (_workoutCompleted) {
      _skipRest();
      _showWorkoutCompletedMessage();
      return;
    }

    final next = _findNextOpenPosition();

    if (next != null) {
      setState(() {
        _currentExerciseIndex = next.exerciseIndex;
        _currentSetIndex = next.setIndex;
      });
    }

    _startRest();
  }

  _WorkoutPosition? _findNextOpenPosition() {
    final currentExercise = _currentExerciseIndex;
    final currentSet = _currentSetIndex;

    for (var set = currentSet + 1;
        set < widget.workout.exercises[currentExercise].sets;
        set++) {
      final exercise = widget.workout.exercises[currentExercise];

      if (!_completedSets[exercise.id]![set]) {
        return _WorkoutPosition(currentExercise, set);
      }
    }

    for (var exerciseIndex = currentExercise + 1;
        exerciseIndex < widget.workout.exercises.length;
        exerciseIndex++) {
      final exercise = widget.workout.exercises[exerciseIndex];
      final openSet =
          _completedSets[exercise.id]!.indexWhere((done) => !done);

      if (openSet >= 0) return _WorkoutPosition(exerciseIndex, openSet);
    }

    for (var exerciseIndex = 0;
        exerciseIndex <= currentExercise;
        exerciseIndex++) {
      final exercise = widget.workout.exercises[exerciseIndex];
      final openSet =
          _completedSets[exercise.id]!.indexWhere((done) => !done);

      if (openSet >= 0) return _WorkoutPosition(exerciseIndex, openSet);
    }

    return null;
  }

  void _reopenCurrentSet() {
    _setLogs.removeWhere(
      (log) =>
          log.exerciseId == _currentExercise.id &&
          log.setIndex == _currentSetIndex,
    );

    setState(() {
      _completedSets[_currentExercise.id]![_currentSetIndex] = false;
    });
  }

  void _startRest() {
    _restTimer?.cancel();

    _restEndTime = DateTime.now().add(
      const Duration(seconds: _restDuration),
    );

    NotificationService.scheduleRestFinished();
    NotificationService.showRestProgress(
      exerciseName: _currentExercise.name,
    );

    setState(() => _remainingSeconds = _restDuration);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _restEndTime == null) {
        timer.cancel();
        return;
      }

      final remaining =
          _restEndTime!.difference(DateTime.now()).inSeconds;

      if (remaining <= 0) {
        timer.cancel();
        _restEndTime = null;

        setState(() => _remainingSeconds = 0);
        _showActiveWorkoutNotification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descanso concluído. Prepare a próxima série!'),
          ),
        );
      } else {
        setState(() => _remainingSeconds = remaining);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _restEndTime = null;

    NotificationService.cancelRestNotification();

    if (mounted) {
      setState(() => _remainingSeconds = 0);

      if (_isPaused) {
        NotificationService.showPausedWorkout(
          exerciseName: _currentExercise.name,
          elapsed: _elapsed,
        );
      } else {
        _showActiveWorkoutNotification();
      }
    }
  }

  void _showWorkoutCompletedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Treino concluído! Salve para registrar a sessão.'),
        action: SnackBarAction(
          label: 'SALVAR',
          onPressed: _finishWorkout,
        ),
      ),
    );
  }

  void _showExercisePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'EXERCÍCIOS DO TREINO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.workout.exercises.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFF252525)),
                  itemBuilder: (context, index) {
                    final exercise = widget.workout.exercises[index];
                    final sets = _completedSets[exercise.id]!;
                    final completed = sets.where((done) => done).length;
                    final selected = index == _currentExerciseIndex;

                    return ListTile(
                      selected: selected,
                      selectedTileColor: const Color(0xFFCCFF00)
                          .withValues(alpha: 0.06),
                      leading: CircleAvatar(
                        backgroundColor: sets.every((done) => done)
                            ? const Color(0xFFCCFF00)
                            : const Color(0xFF292929),
                        foregroundColor: sets.every((done) => done)
                            ? Colors.black
                            : Colors.white,
                        child: sets.every((done) => done)
                            ? const Icon(Icons.check_rounded)
                            : Text('${index + 1}'),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('$completed/${exercise.sets} séries'),
                      trailing: selected
                          ? const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFFCCFF00),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _selectExercise(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    if (!_workoutCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Faltam ${_totalSets - _doneSets} séries para concluir o treino.',
          ),
        ),
      );
      return;
    }

    final finish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Treino concluído'),
        content: Text(
          'Você completou $_totalSets séries em ${_formatDuration(_elapsed)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar revisando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCCFF00),
              foregroundColor: Colors.black,
            ),
            child: const Text('Salvar treino'),
          ),
        ],
      ),
    );

    if (finish == true && mounted) {
      _elapsedTimer?.cancel();
      _restTimer?.cancel();

      await NotificationService.cancelRestNotification();
      await NotificationService.cancelWorkoutNotification();

      if (!mounted) return;

      widget.appState.recordWorkoutCompletion(
        workout: widget.workout,
        totalSets: _totalSets,
        duration: _elapsed,
        setLogs: List.of(_setLogs),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Sair do treino?'),
        content: const Text(
          'O progresso deste treino será perdido se você sair agora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar treino'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      _restTimer?.cancel();
      await NotificationService.cancelRestNotification();
      await NotificationService.cancelWorkoutNotification();

      if (mounted) Navigator.pop(context);
    }
  }