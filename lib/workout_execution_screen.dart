import 'dart:async';

import 'package:flutter/material.dart';

import 'models/exercise.dart';
import 'models/workout.dart';
import 'services/notification_service.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutExecutionScreen({super.key, required this.workout});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  static const int _restDuration = 60;
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<bool>> _completedSets = {};
  Timer? _restTimer;
  int _remainingSeconds = 0;

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
    NotificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.workout.name),
      ),
      body: Column(
        children: [
          _buildProgress(),
          if (_remainingSeconds > 0) _buildRestTimer(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: widget.workout.exercises.length,
              itemBuilder: (context, index) =>
                  _buildExercise(widget.workout.exercises[index]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _ActionButton(
                label: 'FINALIZAR TREINO',
                icon: Icons.flag,
                onTap: _finishWorkout,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final progress = _totalSets == 0 ? 0.0 : _doneSets / _totalSets;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROGRESSO',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A8A8A),
                ),
              ),
              Text(
                '$_doneSets/$_totalSets séries',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: const Color(0xFF242424),
            color: const Color(0xFFCCFF00),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.black, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESCANSO',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
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

  Widget _buildExercise(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text('${exercise.sets} séries • meta de ${exercise.reps} repetições'),
          const SizedBox(height: 16),
          const Row(
            children: [
              SizedBox(width: 46, child: Text('SÉRIE', style: _headerStyle)),
              Expanded(child: Text('CARGA (KG)', style: _headerStyle)),
              SizedBox(width: 10),
              Expanded(child: Text('REPS', style: _headerStyle)),
              SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(exercise.sets, (setIndex) {
            final completed = _completedSets[exercise.id]![setIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    child: Text(
                      '${setIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _weightControllers[exercise.id]![setIndex],
                      enabled: !completed,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('0'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _repsControllers[exercise.id]![setIndex],
                      enabled: !completed,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('0'),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Checkbox(
                      value: completed,
                      activeColor: const Color(0xFFCCFF00),
                      checkColor: Colors.black,
                      onChanged: (value) =>
                          _toggleSet(exercise, setIndex, value ?? false),
                    ),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () => _copyWeightToAll(exercise),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('COPIAR CARGA PARA TODAS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCCFF00),
              side: const BorderSide(color: Color(0xFFCCFF00)),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Color(0xFF8A8A8A),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFF202020),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

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
        if (!_completedSets[exercise.id]![index])
          controllers[index].text = source;
      }
    });
  }

  void _toggleSet(Exercise exercise, int setIndex, bool completed) {
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
    if (completed && !_workoutCompleted) _startRest();
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
          const SnackBar(content: Text('Descanso finalizado. Próxima série!')),
        );
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    NotificationService.cancelRestNotification();
    setState(() => _remainingSeconds = 0);
  }

  Future<void> _finishWorkout() async {
    if (!_workoutCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conclua todas as séries primeiro.')),
      );
      return;
    }
    final finish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Finalizar treino'),
        content: Text('Todas as $_totalSets séries foram concluídas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (finish == true && mounted) {
      _restTimer?.cancel();
      await NotificationService.cancelRestNotification();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final controllers in _weightControllers.values) {
      for (final controller in controllers) controller.dispose();
    }
    for (final controllers in _repsControllers.values) {
      for (final controller in controllers) controller.dispose();
    }
    super.dispose();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFCCFF00),
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
