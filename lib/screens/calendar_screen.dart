import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class _CalData {
  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  _CalData(this.events, this.tasks);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<_CalData> _future;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CalData> _load() async {
    final r = await Future.wait<dynamic>([
      HerDayDb.instance.fetchEvents(),
      HerDayDb.instance.fetchTasks(),
    ]);
    return _CalData(r[0] as List<CalendarEvent>, r[1] as List<TaskItem>);
  }

  void _reload() => setState(() => _future = _load());

  bool _hasItems(_CalData d, DateTime day) =>
      d.events.any((e) => isSameDay(e.eventDate, day)) ||
      d.tasks.any((t) => isSameDay(t.dueDate, day));

  Future<void> _addEvent() async {
    final title = TextEditingController();
    final notes = TextEditingController();
    final time = TextEditingController();
    String category = 'Personal';
    DateTime date = _selected;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Event 📅'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Event title'),
                ),
                const SizedBox(height: 12),
                TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                const SizedBox(height: 12),
                TextField(controller: time, decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: taskCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text('${categoryIcon(c)} $c')))
                      .toList(),
                  onChanged: (v) => setLocal(() => category = v ?? category),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(shortDate(date)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => date = picked);
                  },
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
      await HerDayDb.instance.addEvent(
        title: title.text.trim(),
        notes: notes.text.trim(),
        date: date,
        startTime: time.text.trim(),
        category: category,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1; // Monday-first
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar 📅')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('Event'),
      ),
      body: AsyncBody<_CalData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          final dayEvents = data.events.where((e) => isSameDay(e.eventDate, _selected)).toList();
          final dayTasks = data.tasks.where((t) => isSameDay(t.dueDate, _selected)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_month).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                    .map((d) => Expanded(
                          child: Text(d,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              ...List.generate(rows, (r) {
                return Row(
                  children: List.generate(7, (c) {
                    final idx = r * 7 + c;
                    final dayNum = idx - offset + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) return const Expanded(child: SizedBox(height: 48));
                    final day = DateTime(_month.year, _month.month, dayNum);
                    final isToday = isSameDay(day, DateTime.now());
                    final isSel = isSameDay(day, _selected);
                    final has = _hasItems(data, day);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = day),
                        child: Container(
                          height: 48,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSel
                                ? scheme.primary
                                : isToday
                                    ? scheme.primaryContainer
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$dayNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? scheme.onPrimary : scheme.onSurface,
                                  )),
                              if (has)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSel ? scheme.onPrimary : scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
              SectionTitle('📍 ${shortDate(_selected)}'),
              if (dayEvents.isEmpty && dayTasks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nothing planned this day 🌿'),
                  ),
                ),
              ...dayEvents.map((e) => Card(
                    child: ListTile(
                      leading: const Text('📌', style: TextStyle(fontSize: 22)),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        if (e.startTime.isNotEmpty) '🕐 ${e.startTime}',
                        '${categoryIcon(e.category)} ${e.category}',
                        if (e.notes.isNotEmpty) e.notes,
                      ].join(' · ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            await HerDayDb.instance.deleteEvent(e.id);
                            _reload();
                          } catch (err) {
                            if (mounted) showError(context, err);
                          }
                        },
                      ),
                    ),
                  )),
              ...dayTasks.map((t) => Card(
                    child: ListTile(
                      leading: Text(t.isDone ? '✅' : '☐', style: const TextStyle(fontSize: 20)),
                      title: Text(t.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: t.isDone ? TextDecoration.lineThrough : null,
                          )),
                      subtitle: Text('${categoryIcon(t.category)} Task · ${t.priority}'),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
