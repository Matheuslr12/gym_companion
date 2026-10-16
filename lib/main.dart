import 'package:flutter/material.dart';

import 'services/notification_service.dart';
import 'workout_execution_screen.dart';

import 'data/app_state.dart';
import 'models/exercise.dart';
import 'models/workout.dart';
import 'models/workout_session.dart';

import 'reports_screen.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await AppState().load();

  runApp(const GymCompanionApp());
}

class GymCompanionApp extends StatelessWidget {
  const GymCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCCFF00),
          brightness: Brightness.dark,
          primary: const Color(0xFFCCFF00),
          surface: const Color(0xFF141414),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          bodyMedium: TextStyle(fontSize: 15, color: Color(0xFFB8B8B8)),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppState appState = AppState();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final screens = [
          HomeTab(appState: appState),
          WorkoutsTab(appState: appState),
          const ReportsTab(),
        ];

        return Scaffold(
          body: screens[currentIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFF111111),
            indicatorColor: const Color(0xFFCCFF00),
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              setState(() => currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Colors.black),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center, color: Colors.black),
                label: 'Treinos',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart, color: Colors.black),
                label: 'Relatórios',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeTab extends StatefulWidget {
  final AppState appState;

  const HomeTab({super.key, required this.appState});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? selectedWorkoutId;

  Workout? get selectedWorkout {
    for (final workout in widget.appState.workouts) {
      if (workout.id == selectedWorkoutId) return workout;
    }
    return null;
  }

  void _ensureSelection() {
    final workouts = widget.appState.workouts;
    if (workouts.isEmpty) {
      selectedWorkoutId = null;
      return;
    }
    final selectionStillExists = workouts.any(
      (workout) => workout.id == selectedWorkoutId,
    );
    if (!selectionStillExists) {
      selectedWorkoutId = workouts.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureSelection();
    final workouts = widget.appState.workouts;
    final weeklySessions = widget.appState.sessionsThisWeek;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GYM\nCOMPANION',
              style: TextStyle(
                fontSize: 36,
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha um treino e comece agora.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Selecionar treino'),
            const SizedBox(height: 12),
            SizedBox(
              height: 126,
              child: workouts.isEmpty
                  ? const _EmptyCard(
                      title: 'Nenhum treino disponível',
                      subtitle: 'Crie um treino na aba Treinos.',
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: workouts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        final selected = workout.id == selectedWorkoutId;
                        return _WorkoutSelectorCard(
                          workout: workout,
                          selected: selected,
                          onTap: () {
                            setState(() => selectedWorkoutId = workout.id);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            _PrimaryButton(
              label: 'INICIAR TREINO',
              icon: Icons.play_arrow,
              onTap: _startSelectedWorkout,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Resumo da semana'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Treinos realizados',
                    value: weeklySessions.length.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Séries concluídas',
                    value: widget.appState.setsCompletedThisWeek.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: weeklySessions.isEmpty
                  ? const _EmptyCard(
                      title: 'Nenhum treino nesta semana',
                      subtitle: 'Os treinos finalizados aparecerão aqui.',
                    )
                  : ListView.separated(
                      itemCount: weeklySessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _WeeklySessionCard(
                          session: weeklySessions[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSelectedWorkout() {
    final workout = selectedWorkout;
    if (workout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie e selecione um treino primeiro.')),
      );
      return;
    }
    if (workout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um exercício a este treino.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WorkoutExecutionScreen(appState: widget.appState, workout: workout),
      ),
    );
  }
}

class WorkoutsTab extends StatelessWidget {
  final AppState appState;

  const WorkoutsTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final workouts = appState.workouts;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TREINOS',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'CRIAR TREINO',
              icon: Icons.add,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateWorkoutScreen(appState: appState),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: workouts.isEmpty
                  ? const _EmptyCard(
                      title: 'Sua lista está vazia',
                      subtitle:
                          'Crie treinos como Push, Pull, Pernas ou Full Body.',
                    )
                  : ListView.builder(
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        final workout = workouts[index];

                        return _WorkoutCard(
                          workout: workout,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutDetailsScreen(
                                  appState: appState,
                                  workout: workout,
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            showDeleteConfirmation(
                              context,
                              title: 'Excluir treino',
                              message:
                                  'Deseja excluir “${workout.name}” e todos os seus exercícios?',
                              onConfirm: () =>
                                  appState.removeWorkout(workout.id),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}



class CreateWorkoutScreen extends StatefulWidget {
  final AppState appState;

  const CreateWorkoutScreen({super.key, required this.appState});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final nameController = TextEditingController();
  String selectedMuscleGroup = 'Full Body';

  final muscleGroups = [
    'Full Body',
    'Peito',
    'Costas',
    'Pernas',
    'Ombros',
    'Braços',
    'Push',
    'Pull',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Criar treino'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Nome do treino'),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Ex: Push A'),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Grupo muscular'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscleGroups.map((group) {
                final selected = group == selectedMuscleGroup;

                return ChoiceChip(
                  label: Text(group),
                  selected: selected,
                  selectedColor: const Color(0xFFCCFF00),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) {
                    setState(() => selectedMuscleGroup = group);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            _PrimaryButton(
              label: 'CRIAR TREINO',
              icon: Icons.check,
              onTap: _saveWorkout,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF141414),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _saveWorkout() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite o nome do treino.')));
      return;
    }

    final workout = Workout(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      muscleGroup: selectedMuscleGroup,
    );

    widget.appState.addWorkout(workout);
    Navigator.pop(context);
  }
}

class WorkoutDetailsScreen extends StatelessWidget {
  final AppState appState;
  final Workout workout;

  const WorkoutDetailsScreen({
    super.key,
    required this.appState,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(workout.name),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatCard(title: 'Grupo', value: workout.muscleGroup),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Exercícios',
                  value: workout.totalExercises.toString(),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Exercícios'),
                const SizedBox(height: 12),
                Expanded(
                  child: workout.exercises.isEmpty
                      ? const _EmptyCard(
                          title: 'Nenhum exercício',
                          subtitle: 'Adicione exercícios ao seu treino.',
                        )
                      : ListView.builder(
                          itemCount: workout.exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = workout.exercises[index];

                            return _ExerciseCard(
                              exercise: exercise,
                              onDelete: () {
                                showDeleteConfirmation(
                                  context,
                                  title: 'Excluir exercício',
                                  message: 'Deseja excluir “${exercise.name}”?',
                                  onConfirm: () => appState.removeExercise(
                                    workoutId: workout.id,
                                    exerciseId: exercise.id,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                _PrimaryButton(
                  label: 'ADICIONAR EXERCÍCIO',
                  icon: Icons.add,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: const Color(0xFF141414),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (_) {
                        return AddExerciseSheet(
                          appState: appState,
                          workout: workout,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AddExerciseSheet extends StatefulWidget {
  final AppState appState;
  final Workout workout;

  const AddExerciseSheet({
    super.key,
    required this.appState,
    required this.workout,
  });

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final nameController = TextEditingController();
  final setsController = TextEditingController(text: '3');
  final repsController = TextEditingController(text: '10');

  String bodyPart = 'Superiores';
  String primaryMuscle = 'Peito';
  String secondaryMuscle = 'Nenhum';

  final upperMuscles = [
    'Peito',
    'Costas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Antebraço',
    'Abdômen',
  ];

  final lowerMuscles = [
    'Quadríceps',
    'Posterior de coxa',
    'Glúteos',
    'Panturrilha',
    'Adutores',
    'Abdutores',
  ];

  List<String> get muscles =>
      bodyPart == 'Superiores' ? upperMuscles : lowerMuscles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novo exercício',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Nome'),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Ex: Supino reto'),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Região do corpo'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BodyPartSelector(
                    label: 'Superiores',
                    selected: bodyPart == 'Superiores',
                    onTap: () {
                      setState(() {
                        bodyPart = 'Superiores';
                        primaryMuscle = upperMuscles.first;
                        secondaryMuscle = 'Nenhum';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BodyPartSelector(
                    label: 'Inferiores',
                    selected: bodyPart == 'Inferiores',
                    onTap: () {
                      setState(() {
                        bodyPart = 'Inferiores';
                        primaryMuscle = lowerMuscles.first;
                        secondaryMuscle = 'Nenhum';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DropdownField(
              label: 'Músculo primário',
              value: primaryMuscle,
              options: muscles,
              onChanged: (value) {
                setState(() {
                  primaryMuscle = value;

                  if (secondaryMuscle == value) {
                    secondaryMuscle = 'Nenhum';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Músculo secundário',
              value: secondaryMuscle,
              options: ['Nenhum', ...muscles],
              onChanged: (value) {
                setState(() => secondaryMuscle = value);
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Séries'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Repetições'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'SALVAR EXERCÍCIO',
              icon: Icons.check,
              onTap: _saveExercise,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _saveExercise() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do exercício.')),
      );
      return;
    }

    final exercise = Exercise(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      bodyPart: bodyPart,
      primaryMuscle: primaryMuscle,
      secondaryMuscle: secondaryMuscle,
      sets: int.tryParse(setsController.text) ?? 3,
      reps: int.tryParse(repsController.text) ?? 10,
    );

    widget.appState.addExercise(
      workoutId: widget.workout.id,
      exercise: exercise,
    );

    Navigator.pop(context);
  }
}

Future<void> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      );
    },
  );
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Color(0xFF8A8A8A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (selected) {
                if (selected != null) {
                  onChanged(selected);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF8A8A8A),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFCCFF00),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        icon: Icon(icon, size: 28),
        label: Text(label),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Color(0xFF8A8A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF232323)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle),
        ],
      ),
    );
  }
}

class _WorkoutSelectorCard extends StatelessWidget {
  final Workout workout;
  final bool selected;
  final VoidCallback onTap;

  const _WorkoutSelectorCard({
    required this.workout,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCCFF00) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFCCFF00) : const Color(0xFF262626),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.fitness_center,
                  color: selected ? Colors.black : const Color(0xFFCCFF00),
                ),
                const Spacer(),
                Text(
                  '${workout.totalExercises} EX.',
                  style: TextStyle(
                    color: selected ? Colors.black54 : const Color(0xFF8A8A8A),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              workout.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              workout.muscleGroup,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Colors.black.withValues(alpha: 0.7)
                    : const Color(0xFFB8B8B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySessionCard extends StatelessWidget {
  final WorkoutSession session;

  const _WeeklySessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final date = session.completedAt;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check, color: Color(0xFFCCFF00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.workoutName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.totalExercises} exercícios • ${session.totalSets} séries',
                ),
              ],
            ),
          ),
          Text(
            '$day/$month\n$hour:$minute',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.black),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${workout.muscleGroup} • ${workout.totalExercises} exercícios',
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onDelete;

  const _ExerciseCard({required this.exercise, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.bodyPart} • ${exercise.primaryMuscle} • Secundário: ${exercise.secondaryMuscle}',
                ),
                const SizedBox(height: 4),
                Text(exercise.summary),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _BodyPartSelector extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BodyPartSelector({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCCFF00) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
