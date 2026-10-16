import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'models/workout_session.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EVOLUÇÃO',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white,
                indicator: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  borderRadius: BorderRadius.circular(20),
                ),
                tabs: const [
                  Tab(text: '7 dias'),
                  Tab(text: '4 semanas'),
                  Tab(text: '3 meses'),
                  Tab(text: 'Tudo'),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: TabBarView(
                  children: [
                    _ReportPeriod(period: const Duration(days: 7)),
                    _ReportPeriod(period: const Duration(days: 28)),
                    _ReportPeriod(period: const Duration(days: 90)),
                    const _ReportPeriod(period: null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPeriod extends StatelessWidget {
  final Duration? period;

  const _ReportPeriod({required this.period});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final now = DateTime.now();

    final sessions = period == null
        ? appState.workoutSessions
        : appState.sessionsInRange(
            now.subtract(period!),
            now.add(const Duration(days: 1)),
          );

    if (sessions.isEmpty) {
      return const _EmptyState();
    }

    final logs = sessions.expand((session) => session.setLogs).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'TREINOS',
                value: '${sessions.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'SÉRIES',
                value: '${logs.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'DIAS DA SEMANA TREINADOS',
          child: _WeekdayChart(sessions: sessions),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'MÚSCULOS MAIS TRABALHADOS',
          child: _MuscleRanking(logs: logs),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'MÉDIA DE PESO POR MÚSCULO',
          child: _MuscleAverageWeight(logs: logs),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'TREINOS RECENTES',
          child: _RecentSessions(sessions: sessions),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_rounded,
              color: Color(0xFFCCFF00),
              size: 42,
            ),
            SizedBox(height: 14),
            Text(
              'Sem dados ainda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Finalize treinos registrando carga e repetições para ver seu dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB8B8B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _WeekdayChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final counts = List<int>.filled(7, 0);

    for (final session in sessions) {
      counts[session.completedAt.weekday - 1]++;
    }

    final max = counts.fold(1, (current, value) => value > current ? value : current);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${counts[index]}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 90 * (counts[index] / max),
                    decoration: BoxDecoration(
                      color: counts[index] == 0
                          ? const Color(0xFF242424)
                          : const Color(0xFFCCFF00),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MuscleRanking extends StatelessWidget {
  final List<ExerciseSetLog> logs;

  const _MuscleRanking({required this.logs});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};

    for (final log in logs) {
      counts[log.primaryMuscle] = (counts[log.primaryMuscle] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const Text(
        'Nenhuma série registrada ainda.',
        style: TextStyle(color: Color(0xFF8A8A8A)),
      );
    }

    final max = entries.first.value;

    return Column(
      children: entries.take(6).map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${entry.value} séries',
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: entry.value / max,
                  minHeight: 7,
                  backgroundColor: const Color(0xFF242424),
                  color: const Color(0xFFCCFF00),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MuscleAverageWeight extends StatelessWidget {
  final List<ExerciseSetLog> logs;

  const _MuscleAverageWeight({required this.logs});

  @override
  Widget build(BuildContext context) {
    final totals = <String, List<double>>{};

    for (final log in logs) {
      totals.putIfAbsent(log.primaryMuscle, () => []).add(log.weight);
    }

    final entries = totals.entries.toList()
      ..sort((a, b) {
        final averageA = a.value.fold<double>(0, (total, weight) => total + weight) / a.value.length;
        final averageB = b.value.fold<double>(0, (total, weight) => total + weight) / b.value.length;
        return averageB.compareTo(averageA);
      });

    if (entries.isEmpty) {
      return const Text(
        'Nenhuma carga registrada ainda.',
        style: TextStyle(color: Color(0xFF8A8A8A)),
      );
    }

    return Column(
      children: entries.take(6).map((entry) {
        final average = entry.value.fold<double>(
              0,
              (total, weight) => total + weight,
            ) /
            entry.value.length;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.monitor_weight_outlined,
            color: Color(0xFFCCFF00),
          ),
          title: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${entry.value.length} séries'),
          trailing: Text(
            '${average.toStringAsFixed(average.truncateToDouble() == average ? 0 : 1)} kg',
            style: const TextStyle(
              color: Color(0xFFCCFF00),
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentSessions extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _RecentSessions({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sessions.take(5).map((session) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.fitness_center_rounded,
            color: Color(0xFFCCFF00),
          ),
          title: Text(
            session.workoutName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${session.totalSets} séries • ${session.totalVolume.toStringAsFixed(0)} kg de volume',
          ),
          trailing: Text(
            '${session.completedAt.day}/${session.completedAt.month}',
          ),
        );
      }).toList(),
    );
  }
}