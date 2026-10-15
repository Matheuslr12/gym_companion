import 'dart:async';

import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'models/exercise.dart';
import 'models/workout.dart';
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

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  static const int _restDuration = 60;
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<bool>> _completedSets = {};
  final ScrollController _scrollController = ScrollController();
  late final DateTime _startedAt;
  Timer? _elapsedTimer;
  Timer? _restTimer;
  Duration _elapsed = Duration.zero;
  int _remainingSeconds = 0;

  int get _totalSets => widget.workout.exercises.fold(
        0,
        (total, exercise) => total + exercise.sets,
      );

  int get _doneSets => _completedSets.values.fold(
        0,
        (total, sets) => total + sets.where((done) => done).length,
      );

  int get _completedExercises => widget.workout.exercises.where((exercise) {
        final sets = _completedSets[exercise.id];
        return sets != null && sets.isNotEmpty && sets.every((done) => done);
      }).length;

  bool get _workoutCompleted => _totalSets > 0 && _doneSets == _totalSets;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
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
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt));
      }
    });
    NotificationService.requestPermissions();
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
        body: Column(
          children: [
            _buildLiveSummary(),
            if (_remainingSeconds > 0) _buildRestTimer(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: widget.workout.exercises.length,
                itemBuilder: (context, index) => _buildExercise(
                  widget.workout.exercises[index],
                  index,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF080808),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      toolbarHeight: 72,
      title: Row(
        children: [
          IconButton.filledTonal(
            onPressed: _confirmExit,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1B1B1B),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCFF00),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TREINO AO VIVO',
                      style: TextStyle(
                        color: Color(0xFFCCFF00),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _finishWorkout,
            style: TextButton.styleFrom(
              foregroundColor: _workoutCompleted
                  ? const Color(0xFFCCFF00)
                  : const Color(0xFF8A8A8A),
            ),
            child: const Text(
              'FINALIZAR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSummary() {
    final progress = _totalSets == 0 ? 0.0 : _doneSets / _totalSets;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LiveMetric(
                  label: 'DURAÇÃO',
                  value: _formatDuration(_elapsed),
                  icon: Icons.timer_outlined,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _LiveMetric(
                  label: 'SÉRIES',
                  value: '$_doneSets/$_totalSets',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _LiveMetric(
                  label: 'EXERCÍCIOS',
                  value:
                      '$_completedExercises/${widget.workout.exercises.length}',
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFF292929),
              color: const Color(0xFFCCFF00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = _remainingSeconds / _restDuration;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: Colors.black.withValues(alpha: 0.16),
                  color: Colors.black,
                ),
                const Icon(Icons.hourglass_bottom, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESCANSO EM ANDAMENTO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _skipRest,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.black.withValues(alpha: 0.09),
            ),
            child: const Text(
              'PULAR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercise(Exercise exercise, int exerciseIndex) {
    final completedSets = _completedSets[exercise.id]!;
    final exerciseDone = completedSets.every((done) => done);
    final exerciseStarted = completedSets.any((done) => done);
    final statusLabel = exerciseDone
        ? 'CONCLUÍDO'
        : exerciseStarted
            ? 'EM ANDAMENTO'
            : 'A FAZER';
    final statusColor = exerciseDone
        ? const Color(0xFFCCFF00)
        : exerciseStarted
            ? const Color(0xFFFFC857)
            : const Color(0xFF777777);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: exerciseStarted && !exerciseDone
              ? const Color(0xFFCCFF00).withValues(alpha: 0.45)
              : const Color(0xFF242424),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: exerciseDone
                        ? const Color(0xFFCCFF00)
                        : const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: exerciseDone
                      ? const Icon(Icons.check, color: Colors.black, size: 21)
                      : Text(
                          '${exerciseIndex + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${exercise.primaryMuscle} • ${exercise.sets} × ${exercise.reps}',
                        style: const TextStyle(
                          color: Color(0xFF9A9A9A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF242424)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              children: [
                const Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text('SÉRIE', style: _headerStyle),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('CARGA (KG)', style: _headerStyle),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text('REPS', style: _headerStyle),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(exercise.sets, (setIndex) {
                  return _buildSetRow(exercise, setIndex);
                }),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: exerciseDone
                        ? null
                        : () => _copyWeightToAll(exercise),
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('REPETIR CARGA EM TODAS AS SÉRIES'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCCFF00),
                      disabledForegroundColor: const Color(0xFF5A5A5A),
                      side: BorderSide(
                        color: exerciseDone
                            ? const Color(0xFF292929)
                            : const Color(0xFFCCFF00).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(Exercise exercise, int setIndex) {
    final completed = _completedSets[exercise.id]![setIndex];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFFCCFF00).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFCCFF00)
                    : const Color(0xFF252525),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${setIndex + 1}',
                style: TextStyle(
                  color: completed ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _weightControllers[exercise.id]![setIndex],
              enabled: !completed,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration('0'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsControllers[exercise.id]![setIndex],
              enabled: !completed,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('${exercise.reps}'),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _toggleSet(exercise, setIndex, !completed),
              style: IconButton.styleFrom(
                backgroundColor: completed
                    ? const Color(0xFFCCFF00)
                    : const Color(0xFF292929),
                foregroundColor: completed ? Colors.black : Colors.white,
              ),
              icon: Icon(
                completed ? Icons.check : Icons.check_rounded,
                size: 20,
              ),
              tooltip: completed ? 'Reabrir série' : 'Concluir série',
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
    color: Color(0xFF777777),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF202020),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCFF00)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
      );

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _copyWeightToAll(Exercise exercise) {
    final controllers = _weightControllers[exercise.id]!;
    final source = controllers
        .map((controller) => controller.text.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma carga primeiro.')),
      );
      return;
    }
    setState(() {
      for (var index = 0; index < controllers.length; index++) {
        if (!_completedSets[exercise.id]![index]) {
          controllers[index].text = source;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Carga de $source kg aplicada às séries abertas.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSet(Exercise exercise, int setIndex, bool completed) {
    FocusScope.of(context).unfocus();
    if (completed) {
      final weight = double.tryParse(
        _weightControllers[exercise.id]![setIndex].text.replaceAll(',', '.'),
      );
      final reps = int.tryParse(_repsControllers[exercise.id]![setIndex].text);
      if (weight == null || weight < 0 || reps == null || reps <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe carga e repetições válidas.')),
        );
        return;
      }
    }
    setState(() => _completedSets[exercise.id]![setIndex] = completed);
    if (completed && !_workoutCompleted) {
      _startRest();
    } else if (_workoutCompleted) {
      _skipRest();
      _showWorkoutCompletedMessage();
    }
  }

  void _startRest() {
    _restTimer?.cancel();
    NotificationService.scheduleRestFinished();
    setState(() => _remainingSeconds = _restDuration);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descanso concluído. Prepare a próxima série!'),
          ),
        );
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    NotificationService.cancelRestNotification();
    if (mounted) setState(() => _remainingSeconds = 0);
  }

  void _showWorkoutCompletedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Treino concluído! Toque em FINALIZAR para salvar.'),
        action: SnackBarAction(
          label: 'FINALIZAR',
          onPressed: _finishWorkout,
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
      if (!mounted) return;
      widget.appState.recordWorkoutCompletion(
        workout: widget.workout,
        totalSets: _totalSets,
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
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _scrollController.dispose();
    for (final controllers in _weightControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _repsControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}

class _LiveMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _LiveMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFCCFF00)),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: const Color(0xFF2A2A2A),
    );
  }
}
