import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'habits_screen.dart';
import 'journal_screen.dart';
import 'meals_screen.dart';
import 'shopping_screen.dart';

class _DashData {
  final Profile? profile;
  final List<TaskItem> todayTasks;
  final double todaySpent;
  final double todayIncome;
  final List<MoodLog> weekMoods;
  final List<Habit> habits;
  final LoveMessage? latestMessage;
  final Goal? topGoal;

  _DashData({
    required this.profile,
    required this.todayTasks,
    required this.todaySpent,
    required this.todayIncome,
    required this.weekMoods,
    required this.habits,
    required this.latestMessage,
    required this.topGoal,
  });
}

const List<String> _quotes = [
  "You've got this! ❤️",
  "One day at a time, love. 🌸",
  "Don't forget to eat and drink water today 💧",
  "I'm proud of you — always. 💕",
  'Small steps every day still move you forward ✨',
  'Rest is productive too. Take it easy today 🌙',
  'You are so loved. Never forget that 💌',
];

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAllTasks;
  const DashboardScreen({super.key, this.onSeeAllTasks});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashData> _future;
  String? _todayMood;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashData> _load() async {
    final db = HerDayDb.instance;
    final now = DateTime.now();
    final results = await Future.wait<dynamic>([
      db.fetchProfile(),
      db.fetchTasks(),
      db.fetchTransactionsOn(now),
      db.fetchMoods(days: 7),
      db.fetchHabitsWithToday(),
      db.fetchMessages(),
      db.fetchGoals(),
    ]);
    final allTasks = results[1] as List<TaskItem>;
    final todayTasks = allTasks.where((t) => isSameDay(t.dueDate, now)).toList()
      ..sort((a, b) => (a.isDone ? 1 : 0).compareTo(b.isDone ? 1 : 0));
    final txns = results[2] as List<Txn>;
    final spent = txns.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final income = txns.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final moods = results[3] as List<MoodLog>;
    final todayMood = moods.where((m) => isSameDay(m.loggedDate, now)).toList();
    _todayMood = todayMood.isEmpty ? null : todayMood.first.mood;
    final goals = results[6] as List<Goal>;
    goals.sort((a, b) => b.progress.compareTo(a.progress));
    final messages = results[5] as List<LoveMessage>;
    return _DashData(
      profile: results[0] as Profile?,
      todayTasks: todayTasks,
      todaySpent: spent,
      todayIncome: income,
      weekMoods: moods,
      habits: results[4] as List<Habit>,
      latestMessage: messages.isEmpty ? null : messages.first,
      topGoal: goals.isEmpty ? null : goals.first,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _pickMood(String mood) async {
    setState(() => _todayMood = mood);
    try {
      await HerDayDb.instance.upsertMood(mood, DateTime.now());
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _toggleTask(TaskItem t, bool done) async {
    try {
      await HerDayDb.instance.setTaskDone(t, done);
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HerDay 🌸')),
      body: AsyncBody<_DashData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final scheme = Theme.of(context).colorScheme;
          final name = (data.profile?.displayName.isNotEmpty ?? false)
              ? data.profile!.displayName
              : 'love';
          final now = DateTime.now();
          final doneCount = data.todayTasks.where((t) => t.isDone).length;
          final dailyGoal = data.todayTasks.isEmpty
              ? 0.0
              : doneCount / data.todayTasks.length;
          final budget = data.profile?.dailyBudget ?? 500;
          final quote = _quotes[now.day % _quotes.length];

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text('${greeting()}, $name ❤️',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(friendlyDate(now), style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 18),

                // ---- Mood ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('☀️ How are you feeling?',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: moods.map((m) {
                            final selected = _todayMood == m;
                            return GestureDetector(
                              onTap: () => _pickMood(m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(color: scheme.primary, width: 2)
                                      : null,
                                ),
                                child: Text(m, style: TextStyle(fontSize: selected ? 26 : 22)),
                              ),
                            );
                          }).toList(),
                        ),
                        if (data.weekMoods.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'This week: ${data.weekMoods.reversed.map((m) => m.mood).join('  ')}',
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ---- Today's tasks ----
                SectionTitle("📋 Today's Tasks",
                    actionLabel: 'See all', onAction: widget.onSeeAllTasks),
                Card(
                  child: data.todayTasks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nothing scheduled today. Enjoy the calm 🌿'))
                      : Column(
                          children: data.todayTasks.take(5).map((t) {
                            return CheckboxListTile(
                              value: t.isDone,
                              onChanged: (v) => _toggleTask(t, v ?? false),
                              title: Text(t.title,
                                  style: TextStyle(
                                    decoration: t.isDone ? TextDecoration.lineThrough : null,
                                    color: t.isDone ? scheme.onSurfaceVariant : null,
                                  )),
                              subtitle: Text('${categoryIcon(t.category)} ${t.category}'
                                  '${t.isRecurring ? ' · 🔁 daily' : ''}'),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          }).toList(),
                        ),
                ),

                // ---- Spending + daily goal ----
                const SectionTitle('💰 Today & Goals'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Today's Spending", style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('${peso(data.todaySpent)} / ${peso(budget)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              HerProgress(value: budget <= 0 ? 0 : data.todaySpent / budget),
                              if (data.todayIncome > 0) ...[
                                const SizedBox(height: 6),
                                Text('Income today: ${peso(data.todayIncome)}',
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🌸 Daily Goal', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('${(dailyGoal * 100).round()}% done',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              HerProgress(value: dailyGoal),
                              const SizedBox(height: 6),
                              Text('$doneCount of ${data.todayTasks.length} tasks',
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ---- Top goal ----
                if (data.topGoal != null) ...[
                  const SectionTitle('🎯 Goal Spotlight'),
                  Card(
                    child: ListTile(
                      title: Text(data.topGoal!.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: HerProgress(value: data.topGoal!.progress),
                      ),
                      trailing: Text('${(data.topGoal!.progress * 100).round()}%'),
                      onTap: () => _push(const GoalsScreen()),
                    ),
                  ),
                ],

                // ---- Message for you ----
                const SectionTitle('💌 A little message for you'),
                Card(
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      data.latestMessage?.body.isNotEmpty == true
                          ? '"${data.latestMessage!.body}"'
                          : '"$quote"',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: scheme.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                // ---- Self-care snapshot ----
                if (data.habits.isNotEmpty) ...[
                  SectionTitle('💧 Self-Care Today',
                      actionLabel: 'Open', onAction: () => _push(const HabitsScreen())),
                  Card(
                    child: Column(
                      children: data.habits.take(3).map((h) {
                        return ListTile(
                          dense: true,
                          leading: Text(h.icon, style: const TextStyle(fontSize: 22)),
                          title: Text(h.name),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: HerProgress(value: h.progress, height: 7),
                          ),
                          trailing: Text('${h.todayCount}/${h.goalPerDay} ${h.unit}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // ---- Quick actions ----
                const SectionTitle('✨ Quick Actions'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _QuickAction(emoji: '📝', label: 'Journal', onTap: () => _push(const JournalScreen())),
                    _QuickAction(emoji: '💰', label: 'Budget', onTap: () => _push(const BudgetScreen())),
                    _QuickAction(emoji: '🛒', label: 'Shopping', onTap: () => _push(const ShoppingScreen())),
                    _QuickAction(emoji: '💧', label: 'Self-Care', onTap: () => _push(const HabitsScreen())),
                    _QuickAction(emoji: '🍱', label: 'Meals', onTap: () => _push(const MealsScreen())),
                    _QuickAction(emoji: '🎯', label: 'Goals', onTap: () => _push(const GoalsScreen())),
                    _QuickAction(emoji: '🤖', label: 'Ask HerDay', onTap: () => _push(const AssistantScreen())),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
