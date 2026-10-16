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
                    _ReportDashboard(period: const Duration(days: 7)),
                    _ReportDashboard(period: const Duration(days: 28)),
                    _ReportDashboard(period: const Duration(days: 90)),
                    const _ReportDashboard(period: null),
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

class _ReportDashboard extends StatelessWidget {
  final Duration? period;

  const _ReportDashboard({required this.period});

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
    final totalSets = sessions.fold<int>(
      0,
      (total, session) => total + session.totalSets,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _StatCard(
          title: 'TREINOS REALIZADOS',
          value: '${sessions.length}',
          subtitle: '$totalSets séries concluídas',
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'DIAS DA SEMANA TREINADOS',
          child: _WeekdayChart(sessions: sessions),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'MÚSCULOS MAIS TRABALHADOS',
          child: _TopMuscles(logs: logs),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'MÉDIA DE PESO POR MÚSCULO',
          child: _AverageWeightByMuscle(logs: logs),
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
              'Finalize treinos para ver dias treinados, músculos e cargas.',
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
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
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
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final counts = List.filled(7, 0);

    for (final session in sessions) {
      counts[session.completedAt.weekday - 1]++;
    }

    final max = counts.fold(
      1,
      (current, value) => value > current ? value : current,
    );

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

class _TopMuscles extends StatelessWidget {
  final List<ExerciseSetLog> logs;

  const _TopMuscles({required this.logs});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};

    for (final log in logs) {
      counts[log.primaryMuscle] = (counts[log.primaryMuscle] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const Text(
        'Nenhuma série registrada ainda.',
        style: TextStyle(color: Color(0xFF8A8A8A)),
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final max = entries.first.value;

    return Column(
      children: entries.take(6).map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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

class _AverageWeightByMuscle extends StatelessWidget {
  final List<ExerciseSetLog> logs;

  const _AverageWeightByMuscle({required this.logs});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<double>>{};

    for (final log in logs) {
      if (log.weight > 0) {
        groups.putIfAbsent(log.primaryMuscle, () => []).add(log.weight);
      }
    }

    if (groups.isEmpty) {
      return const Text(
        'Registre cargas nas séries para ver a média por músculo.',
        style: TextStyle(color: Color(0xFF8A8A8A)),
      );
    }

    final averages = groups.entries.map((entry) {
      final total = entry.value.fold<double>(
        0,
        (sum, weight) => sum + weight,
      );

      return MapEntry(entry.key, total / entry.value.length);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: averages.take(6).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.fitness_center_rounded,
            color: Color(0xFFCCFF00),
          ),
          title: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: Text(
            '${entry.value.toStringAsFixed(entry.value.truncateToDouble() == entry.value ? 0 : 1)} kg',
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