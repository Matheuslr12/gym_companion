import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'models/exercise.dart';
import 'models/workout.dart';

void main() {
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
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: Color(0xFFB8B8B8),
          ),
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
                selectedIcon:
                    Icon(Icons.fitness_center, color: Colors.black),
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

class HomeTab extends StatelessWidget {
  final AppState appState;

  const HomeTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final workouts = appState.workouts;
    final totalExercises = workouts.fold<int>(
      0,
      (total, workout) => total + workout.exercises.length,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GYM\nCOMPANION',
              style: TextStyle(
                fontSize: 38,
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Treine com foco. Acompanhe sua evolução.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            _PrimaryButton(
              label: 'CRIAR TREINO',
              icon: Icons.add,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateWorkoutScreen(appState: appState),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Resumo'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Treinos',
                    value: workouts.length.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Exercícios',
                    value: totalExercises.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Seus treinos'),
            const SizedBox(height: 12),
            Expanded(
              child: workouts.isEmpty
                  ? const _EmptyCard(
                      title: 'Nenhum treino criado',
                      subtitle:
                          'Toque em “Criar treino” para começar.',
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
                              onConfirm: () => appState.removeWorkout(
                                workout.id,
                              ),
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
                    builder: (_) =>
                        CreateWorkoutScreen(appState: appState),
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

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EVOLUÇÃO',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 20),
            _EmptyCard(
              title: 'Sem dados ainda',
              subtitle:
                  'Registre seus treinos para acompanhar cargas, volume e progresso.',
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
  State<CreateWorkoutScreen> createState() =>
      _CreateWorkoutScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do treino.')),
      );
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
                _StatCard(
                  title: 'Grupo',
                  value: workout.muscleGroup,
                ),
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
                          subtitle:
                              'Adicione exercícios ao seu treino.',
                        )
                      : ListView.builder(
                          itemCount: workout.exercises.length,
                          itemBuilder: (context, index) {
                            final exercise =
                                workout.exercises[index];

                            return _ExerciseCard(
                              exercise: exercise,
                              onDelete: () {
                                showDeleteConfirmation(
                                  context,
                                  title: 'Excluir exercício',
                                  message:
                                      'Deseja excluir “${exercise.name}”?',
                                  onConfirm: () =>
                                      appState.removeExercise(
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
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
                    decoration:
                        _inputDecoration('Séries'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration:
                        _inputDecoration('Repetições'),
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
        const SnackBar(
          content: Text('Digite o nome do exercício.'),
        ),
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

  const _StatCard({
    required this.title,
    required this.value,
  });

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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.title,
    required this.subtitle,
  });

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
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(subtitle),
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
              child: const Icon(
                Icons.fitness_center,
                color: Colors.black,
              ),
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
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.onDelete,
  });

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
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
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
          color: selected
              ? const Color(0xFFCCFF00)
              : const Color(0xFF1E1E1E),
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