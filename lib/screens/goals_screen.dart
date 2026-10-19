import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Future<List<Goal>> _future;

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.fetchGoals();
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchGoals());

  Future<void> _add() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final target = TextEditingController();
    final unit = TextEditingController();
    DateTime? deadline;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Goal 🎯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Goal (e.g. Save for a trip)'),
                ),
                const SizedBox(height: 12),
                TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: target,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Target'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unit,
                        decoration: const InputDecoration(labelText: 'Unit (e.g. ₱, books)'),
                      ),
                    ),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(deadline == null ? 'No deadline' : shortDate(deadline!)),
                  subtitle: const Text('Deadline (optional)'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => deadline = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add Goal')),
          ],
        ),
      ),
    );
    final t = double.tryParse(target.text.trim()) ?? 0;
    if (saved != true || title.text.trim().isEmpty || t <= 0) return;
    try {
      await HerDayDb.instance.addGoal(
        title: title.text.trim(),
        description: desc.text.trim(),
        target: t,
        unit: unit.text.trim(),
        deadline: deadline,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _editProgress(Goal g) async {
    double value = g.currentValue;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(g.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_fmt(value)} / ${_fmt(g.target)} ${g.unit}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Slider(
                value: value.clamp(0, g.target).toDouble(),
                min: 0,
                max: g.target,
                onChanged: (v) => setLocal(() => value = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(onPressed: () => setLocal(() => value = (value - 1).clamp(0, g.target).toDouble()), child: const Text('−1')),
                  OutlinedButton(onPressed: () => setLocal(() => value = (value + 1).clamp(0, g.target).toDouble()), child: const Text('+1')),
                  OutlinedButton(onPressed: () => setLocal(() => value = (value + 10).clamp(0, g.target).toDouble()), child: const Text('+10')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    try {
      await HerDayDb.instance.setGoalProgress(g, value);
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Goals 🎯')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: AsyncBody<List<Goal>>(
        future: _future,
        onRetry: _reload,
        builder: (goals) {
          if (goals.isEmpty) {
            return const EmptyState(
              emoji: '🎯',
              title: 'No goals yet',
              subtitle: 'Save ₱20,000, finish a course, read 5 books — dream it here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final g = goals[i];
              return Dismissible(
                key: ValueKey(g.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  try {
                    await HerDayDb.instance.deleteGoal(g.id);
                    _reload();
                  } catch (e) {
                    if (mounted) showError(context, e);
                  }
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(g.isDone ? '${g.title} ✓' : g.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                            Text('${(g.progress * 100).round()}%',
                                style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary)),
                          ],
                        ),
                        if (g.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(g.description, style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 10),
                        HerProgress(value: g.progress),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_fmt(g.currentValue)} / ${_fmt(g.target)} ${g.unit}'
                                '${g.deadline != null ? ' · until ${shortDate(g.deadline!)}' : ''}',
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              ),
                            ),
                            TextButton(onPressed: () => _editProgress(g), child: const Text('Update')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
