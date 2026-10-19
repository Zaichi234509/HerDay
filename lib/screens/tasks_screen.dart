import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<TaskItem>> _future;
  String _filter = 'Today';
  final List<String> _filters = ['Today', 'Upcoming', 'All', 'Done'];

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.fetchTasks();
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchTasks());

  List<TaskItem> _apply(List<TaskItem> all) {
    final now = DateTime.now();
    switch (_filter) {
      case 'Today':
        return all.where((t) => isSameDay(t.dueDate, now)).toList();
      case 'Upcoming':
        return all.where((t) => !t.isDone && t.dueDate.isAfter(DateTime(now.year, now.month, now.day))).toList();
      case 'Done':
        return all.where((t) => t.isDone).toList();
      default:
        return all.where((t) => !t.isDone).toList();
    }
  }

  Future<void> _showEditor({TaskItem? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    String category = existing?.category ?? 'Personal';
    String priority = existing?.priority ?? 'Normal';
    DateTime due = existing?.dueDate ?? DateTime.now();
    bool recurring = existing?.isRecurring ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New Task ✅' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'What needs doing?'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: taskCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text('${categoryIcon(c)} $c')))
                      .toList(),
                  onChanged: (v) => setLocal(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setLocal(() => priority = v ?? priority),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(shortDate(due)),
                  subtitle: const Text('Due date'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: due,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => due = picked);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat daily 🔁'),
                  value: recurring,
                  onChanged: (v) => setLocal(() => recurring = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || title.text.trim().isEmpty) return;
    try {
      if (existing != null) await HerDayDb.instance.deleteTask(existing.id);
      await HerDayDb.instance.addTask(
        title: title.text.trim(),
        notes: notes.text.trim(),
        category: category,
        priority: priority,
        dueDate: due,
        isRecurring: recurring,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Color _priorityColor(String p, ColorScheme scheme) {
    switch (p) {
      case 'High':
        return Colors.red.shade400;
      case 'Low':
        return scheme.onSurfaceVariant;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks ✅')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: AsyncBody<List<TaskItem>>(
              future: _future,
              onRetry: _reload,
              builder: (all) {
                final tasks = _apply(all);
                if (tasks.isEmpty) {
                  return const EmptyState(
                    emoji: '🌸',
                    title: 'No tasks here',
                    subtitle: 'Tap "New Task" to add something for today.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return Dismissible(
                        key: ValueKey(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          try {
                            await HerDayDb.instance.deleteTask(t.id);
                            _reload();
                          } catch (e) {
                            if (mounted) showError(context, e);
                          }
                        },
                        child: Card(
                          child: CheckboxListTile(
                            value: t.isDone,
                            onChanged: (v) async {
                              try {
                                await HerDayDb.instance.setTaskDone(t, v ?? false);
                                _reload();
                              } catch (e) {
                                if (mounted) showError(context, e);
                              }
                            },
                            title: Text(t.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: t.isDone ? TextDecoration.lineThrough : null,
                                )),
                            subtitle: Text(
                              '${categoryIcon(t.category)} ${t.category} · ${shortDate(t.dueDate)}'
                              '${t.isRecurring ? ' · 🔁' : ''}'
                              '${t.notes.isNotEmpty ? '\n${t.notes}' : ''}',
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _priorityColor(t.priority, scheme).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(t.priority,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _priorityColor(t.priority, scheme))),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
