import 'package:flutter/material.dart';

import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late Future<List<Habit>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Habit>> _load() async {
    await HerDayDb.instance.seedDefaultHabitsIfEmpty();
    return HerDayDb.instance.fetchHabitsWithToday();
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchHabitsWithToday());

  Future<void> _setCount(Habit h, int count) async {
    final clamped = count.clamp(0, 99);
    setState(() => h.todayCount = clamped);
    try {
      await HerDayDb.instance.logHabit(h, clamped);
    } catch (e) {
      if (mounted) showError(context, e);
      _reload();
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final icon = TextEditingController(text: '🌸');
    final goal = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'times');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Self-Care Habit 🌸'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(label: const Text('💧 Water ×8'), onPressed: () {
                    name.text = 'Drink water'; icon.text = '💧'; goal.text = '8'; unit.text = 'glasses';
                  }),
                  ActionChip(label: const Text('🧴 Skincare'), onPressed: () {
                    name.text = 'Skincare'; icon.text = '🧴'; goal.text = '2'; unit.text = 'times';
                  }),
                  ActionChip(label: const Text('😴 Sleep'), onPressed: () {
                    name.text = 'Sleep 8 hours'; icon.text = '😴'; goal.text = '1'; unit.text = 'night';
                  }),
                  ActionChip(label: const Text('🧘 Relax'), onPressed: () {
                    name.text = 'Relax / breathe'; icon.text = '🧘'; goal.text = '1'; unit.text = 'times';
                  }),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(controller: icon, decoration: const InputDecoration(labelText: 'Icon')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Habit name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: goal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Goal / day'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (saved != true || name.text.trim().isEmpty) return;
    try {
      await HerDayDb.instance.addHabit(
        name: name.text.trim(),
        icon: icon.text.trim().isEmpty ? '🌸' : icon.text.trim(),
        goalPerDay: int.tryParse(goal.text.trim()) ?? 1,
        unit: unit.text.trim().isEmpty ? 'times' : unit.text.trim(),
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Self-Care 🌸')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: AsyncBody<List<Habit>>(
        future: _future,
        onRetry: _reload,
        builder: (habits) {
          if (habits.isEmpty) {
            return const EmptyState(
              emoji: '💧',
              title: 'No habits yet',
              subtitle: 'Add water, skincare, vitamins — small daily wins.',
            );
          }
          final done = habits.where((h) => h.isDone).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "🌸 Today's Self-Care — $done of ${habits.length} complete. You're doing great, love!",
                    style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...habits.map((h) => Dismissible(
                    key: ValueKey(h.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      try {
                        await HerDayDb.instance.deleteHabit(h.id);
                        _reload();
                      } catch (e) {
                        if (mounted) showError(context, e);
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Text(h.icon, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h.isDone ? '${h.name} ✓' : h.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  HerProgress(value: h.progress, height: 7),
                                  const SizedBox(height: 4),
                                  Text('${h.todayCount} / ${h.goalPerDay} ${h.unit}',
                                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: h.todayCount <= 0 ? null : () => _setCount(h, h.todayCount - 1),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: scheme.primary, size: 30),
                              onPressed: () => _setCount(h, h.todayCount + 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
