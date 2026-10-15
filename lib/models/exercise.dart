class Exercise {
  final String id;
  String name;
  String bodyPart;
  String muscleGroup;
  int sets;
  int reps;
  double weight;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    this.weight = 0,
  });

  String get summary {
    return '$sets x $reps';
  }
}