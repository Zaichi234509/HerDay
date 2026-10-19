import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class _StatsData {
  final List<MoodLog> moods;
  final List<Txn> txns6mo;
  final List<TaskItem> tasks;
  final int journalCount;
  final List<Goal> goals;
  final int habitTotal;
  final int memoriesCount;

  _StatsData({
    required this.moods,
    required this.txns6mo,
    required this.tasks,
    required this.journalCount,
    required this.goals,
    required this.habitTotal,
    required this.memoriesCount,
  });
}

/// 📊 Life Statistics — mood trends, spending analytics, and life totals.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<_StatsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StatsData> _load() async {
    final db = HerDayDb.instance;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final r = await Future.wait<dynamic>([
      db.fetchMoods(days: 90),
      db.fetchTransactionsBetween(start, end),
      db.fetchTasks(),
      db.countJournal(),
      db.fetchGoals(),
      db.habitLogTotal(),
      db.fetchMemories(),
    ]);
    return _StatsData(
      moods: r[0] as List<MoodLog>,
      txns6mo: r[1] as List<Txn>,
      tasks: r[2] as List<TaskItem>,
      journalCount: r[3] as int,
      goals: r[4] as List<Goal>,
      habitTotal: r[5] as int,
      memoriesCount: (r[6] as List<Memory>).length,
    );
  }

  void _reload() => setState(() => _future = _load());

  int _moodStreak(List<MoodLog> moods) {
    final days = moods.map((m) => dateKey(m.loggedDate)).toSet();
    var streak = 0;
    var day = DateTime.now();
    // Allow today to be missing — streak counts from yesterday back.
    if (!days.contains(dateKey(day))) day = day.subtract(const Duration(days: 1));
    while (days.contains(dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Life Statistics 📊')),
      body: AsyncBody<_StatsData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final now = DateTime.now();
          final tasksDone = data.tasks.where((t) => t.isDone).length;
          final goalsDone = data.goals.where((g) => g.isDone).length;
          final streak = _moodStreak(data.moods);

          // Mood counts (last 90 days)
          final moodCounts = <String, int>{for (final m in moods) m: 0};
          for (final log in data.moods) {
            moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
          }
          final moodMax = moodCounts.values.isEmpty ? 1 : moodCounts.values.reduce((a, b) => a > b ? a : b);

          // Last 30 days mood strip (oldest → newest)
          final moodByDay = {for (final m in data.moods) dateKey(m.loggedDate): m.mood};
          final last30 = List.generate(30, (i) {
            final d = now.subtract(Duration(days: 29 - i));
            return (d, moodByDay[dateKey(d)]);
          });

          // 6-month income vs expense
          final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
          double monthSum(DateTime m, String type) => data.txns6mo
              .where((t) => t.type == type && t.txnDate.year == m.year && t.txnDate.month == m.month)
              .fold<double>(0, (s, t) => s + t.amount);
          final maxMonth = months
              .map((m) => [monthSum(m, 'income'), monthSum(m, 'expense')])
              .expand((e) => e)
              .fold<double>(1, (a, b) => a > b ? a : b);

          // Top categories this month
          final thisMonth = data.txns6mo
              .where((t) => t.type == 'expense' && t.txnDate.year == now.year && t.txnDate.month == now.month)
              .toList();
          final spentThisMonth = thisMonth.fold<double>(0, (s, t) => s + t.amount);
          final byCat = <String, double>{};
          for (final t in thisMonth) {
            byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
          }
          final topCats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // Life totals
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      children: [
                        _StatCell(value: '$tasksDone', label: '✅ Tasks done'),
                        _StatCell(value: '${data.journalCount}', label: '📔 Journal entries'),
                        _StatCell(value: '$goalsDone/${data.goals.length}', label: '🎯 Goals done'),
                        _StatCell(value: '${data.habitTotal}', label: '💧 Habit logs'),
                        _StatCell(value: '${data.memoriesCount}', label: '📸 Memories'),
                        _StatCell(value: '$streak 🔥', label: 'Mood streak (days)'),
                      ],
                    ),
                  ),
                ),

                // Mood trends
                const SectionTitle('😊 Mood Trends — last 90 days'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.moods.isEmpty)
                          const Text('No moods logged yet — pick one on the Home tab 🌸')
                        else ...[
                          ...moods.map((m) {
                            final count = moodCounts[m] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(width: 30, child: Text(m, style: const TextStyle(fontSize: 20))),
                                  Expanded(child: HerProgress(value: count / moodMax, height: 8)),
                                  const SizedBox(width: 10),
                                  SizedBox(width: 30, child: Text('$count', textAlign: TextAlign.right)),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          const Text('Last 30 days', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: last30.map((e) {
                              final (day, mood) = e;
                              return Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: mood == null ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(mood ?? '${day.day}', style: TextStyle(fontSize: mood == null ? 10 : 15)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Spending analytics
                const SectionTitle('💰 Spending Analytics — last 6 months'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _LegendDot(color: Colors.green.shade500, label: 'Income'),
                            const SizedBox(width: 16),
                            _LegendDot(color: scheme.error, label: 'Expense'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 130,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: months.map((m) {
                              final inc = monthSum(m, 'income');
                              final exp = monthSum(m, 'expense');
                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _Bar(value: inc / maxMonth, color: Colors.green.shade400),
                                        const SizedBox(width: 4),
                                        _Bar(value: exp / maxMonth, color: scheme.error),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(DateFormat('MMM').format(m), style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 24),
                        Text('This month: spent ${peso(spentThisMonth)}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (topCats.isEmpty)
                          Text('No expenses this month yet.', style: TextStyle(color: scheme.onSurfaceVariant))
                        else
                          ...topCats.take(5).map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Text('${categoryIcon(e.key)} ${e.key}')),
                                    Text(peso(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const _Bar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: (value.clamp(0, 1) * 90).toDouble(),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      ),
    );
  }
}
