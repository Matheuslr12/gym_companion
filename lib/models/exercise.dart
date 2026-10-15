class Exercise {
  final String id;
  String name;
  String bodyPart;
  String primaryMuscle;
  String secondaryMuscle;
  int sets;
  int reps;
  double weight;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.primaryMuscle,
    required this.secondaryMuscle,
    required this.sets,
    required this.reps,
    this.weight = 0,
  });

  String get summary {
    return '$sets x $reps';
  }
}