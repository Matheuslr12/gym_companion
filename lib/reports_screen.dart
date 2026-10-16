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

    final totalSets = sessions.fold<int>(
      0,
      (total, session) => total + session.totalSets,
    );

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
                value: '$totalSets',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'FREQUÊNCIA SEMANAL',
          child: _WeeklyFrequencyChart(sessions: sessions),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'SEQUÊNCIA',
          child: _StreakCard(sessions: sessions),
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
              'Finalize treinos para acompanhar sua frequência e evolução.',
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

class _WeeklyFrequencyChart extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _WeeklyFrequencyChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = List.generate(8, (index) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: (7 - index) * 7));
      final end = start.add(const Duration(days: 7));

      final count = sessions.where((session) {
        return !session.completedAt.isBefore(start) &&
            session.completedAt.isBefore(end);
      }).length;

      return MapEntry('S${index + 1}', count);
    });

    final max = buckets
        .map((entry) => entry.value)
        .fold(1, (current, value) => value > current ? value : current);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: buckets.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 85 * (entry.value / max),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _StreakCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final days = sessions
        .map(
          (session) => DateTime(
            session.completedAt.year,
            session.completedAt.month,
            session.completedAt.day,
          ),
        )
        .toSet()
        .toList()
      ..sort();

    var best = 0;
    var running = 0;
    DateTime? previous;

    for (final day in days) {
      if (previous != null && day.difference(previous).inDays == 1) {
        running++;
      } else {
        running = 1;
      }

      if (running > best) best = running;
      previous = day;
    }

    var current = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var index = days.length - 1; index >= 0; index--) {
      final expected = todayDate.subtract(Duration(days: current));

      if (days[index] == expected ||
          days[index] == expected.subtract(const Duration(days: 1))) {
        current++;
      } else {
        break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'SEQUÊNCIA ATUAL',
            value: '$current dias',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: 'MELHOR SEQUÊNCIA',
            value: '$best dias',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
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
            '${session.totalSets} séries • ${session.totalExercises} exercícios',
          ),
          trailing: Text(
            '${session.completedAt.day}/${session.completedAt.month}',
          ),
        );
      }).toList(),
    );
  }
}