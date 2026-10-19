import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/notifications_service.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class _RemData {
  final List<Reminder> reminders;
  final List<String> nudges;
  _RemData(this.reminders, this.nudges);
}

/// 🔔 Smart Reminders — data-driven nudges + daily scheduled notifications.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<_RemData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RemData> _load() async {
    final db = HerDayDb.instance;
    await db.seedDefaultRemindersIfEmpty();
    final now = DateTime.now();
    final r = await Future.wait<dynamic>([
      db.fetchReminders(),
      db.fetchTasks(),
      db.fetchHabitsWithToday(),
      db.fetchShopping(),
      db.fetchMessages(),
      db.fetchJournal(),
      db.fetchGoals(),
    ]);
    final reminders = r[0] as List<Reminder>;
    final tasks = (r[1] as List<TaskItem>)
        .where((t) => isSameDay(t.dueDate, now) && !t.isDone)
        .length;
    final habits = r[2] as List<Habit>;
    final shoppingLeft = (r[3] as List<ShoppingItem>).where((i) => !i.isBought).length;
    final unread = (r[4] as List<LoveMessage>).where((m) => !m.isRead).length;
    final journalToday =
        (r[5] as List<JournalEntry>).any((e) => isSameDay(e.entryDate, now));
    final goals = r[6] as List<Goal>;

    final nudges = <String>[];
    if (unread > 0) nudges.add('💌 Someone left you $unread unread message${unread == 1 ? '' : 's'}.');
    if (tasks > 0) nudges.add('✅ You have $tasks task${tasks == 1 ? '' : 's'} left today. Kaya mo yan!');
    final water = habits.where((h) => h.name.toLowerCase().contains('water')).toList();
    if (water.isNotEmpty && !water.first.isDone) {
      nudges.add('💧 Water check: ${water.first.todayCount}/${water.first.goalPerDay} glasses so far.');
    }
    final incompleteHabits = habits.where((h) => !h.isDone).length;
    if (habits.isNotEmpty && incompleteHabits == 0) {
      nudges.add('🌸 Self-care complete today. Proud of you!');
    } else if (incompleteHabits > 0) {
      nudges.add('🌿 $incompleteHabits self-care habit${incompleteHabits == 1 ? '' : 's'} still open today.');
    }
    if (shoppingLeft > 0) nudges.add('🛒 $shoppingLeft shopping item${shoppingLeft == 1 ? '' : 's'} left to buy.');
    final nearGoal = goals.where((g) => !g.isDone && g.progress >= 0.8).toList();
    if (nearGoal.isNotEmpty) {
      nudges.add('🎯 Almost there! "${nearGoal.first.title}" is ${(nearGoal.first.progress * 100).round()}% done.');
    }
    if (!journalToday && now.hour >= 18) {
      nudges.add('📝 No journal entry yet today — how was your day, love?');
    }
    if (nudges.isEmpty) nudges.add('✨ All caught up today. Enjoy, love!');

    // (Re)schedule every enabled reminder so schedules survive reinstalls.
    for (final rem in reminders) {
      if (rem.isEnabled) {
        await NotificationsService.instance.scheduleDaily(
          id: rem.notifId,
          title: rem.title,
          body: rem.body,
          time: parseTimeOfDay(rem.remindTime),
        );
      }
    }
    return _RemData(reminders, nudges);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _toggle(Reminder rem, bool enabled) async {
    try {
      await HerDayDb.instance.setReminderEnabled(rem.id, enabled);
      if (enabled) {
        await NotificationsService.instance.requestPermission();
        await NotificationsService.instance.scheduleDaily(
          id: rem.notifId,
          title: rem.title,
          body: rem.body,
          time: parseTimeOfDay(rem.remindTime),
        );
      } else {
        await NotificationsService.instance.cancel(rem.notifId);
      }
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final body = TextEditingController();
    String kind = 'custom';
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);

    void applyPreset(String k, StateSetter setLocal) {
      kind = k;
      switch (k) {
        case 'morning':
          title.text = '☀️ Good morning!';
          body.text = "Check today's tasks and pick your mood 🌸";
          time = const TimeOfDay(hour: 8, minute: 0);
          break;
        case 'water':
          title.text = '💧 Water break';
          body.text = "Don't forget to drink water, love 💧";
          time = const TimeOfDay(hour: 10, minute: 0);
          break;
        case 'journal':
          title.text = '🌙 How was your day?';
          body.text = 'Write a little journal entry before bed 📝';
          time = const TimeOfDay(hour: 21, minute: 0);
          break;
      }
      setLocal(() {});
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New Reminder 🔔'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(label: const Text('☀️ Morning'), onPressed: () => applyPreset('morning', setLocal)),
                    ActionChip(label: const Text('💧 Water'), onPressed: () => applyPreset('water', setLocal)),
                    ActionChip(label: const Text('🌙 Journal'), onPressed: () => applyPreset('journal', setLocal)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(time.format(ctx)),
                  subtitle: const Text('Every day at this time'),
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: time);
                    if (picked != null) setLocal(() => time = picked);
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
      await HerDayDb.instance.addReminder(
        title: title.text.trim(),
        body: body.text.trim(),
        remindTime: formatTimeOfDay(time),
        kind: kind,
        notifId: DateTime.now().millisecondsSinceEpoch % 100000000,
      );
      await NotificationsService.instance.requestPermission();
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String _kindIcon(String kind) {
    switch (kind) {
      case 'morning':
        return '☀️';
      case 'water':
        return '💧';
      case 'journal':
        return '🌙';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders 🔔')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Reminder'),
      ),
      body: AsyncBody<_RemData>(
        future: _future,
        onRetry: _reload,
        builder: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              const SectionTitle('✨ Smart nudges for today'),
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.nudges
                        .map((n) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Text(n,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer)),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SectionTitle('⏰ Daily reminders'),
              if (!NotificationsService.instance.isReady)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'ℹ️ Scheduled notifications run on Android/iOS. On web, reminders are saved here and nudges still work in-app.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              if (data.reminders.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No reminders yet — add your first one 🔔'),
                  ),
                ),
              ...data.reminders.map((rem) => Dismissible(
                    key: ValueKey(rem.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await NotificationsService.instance.cancel(rem.notifId);
                      try {
                        await HerDayDb.instance.deleteReminder(rem.id);
                        _reload();
                      } catch (e) {
                        if (mounted) showError(context, e);
                      }
                    },
                    child: Card(
                      child: SwitchListTile(
                        secondary: Text(_kindIcon(rem.kind), style: const TextStyle(fontSize: 26)),
                        title: Text(rem.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Daily at ${rem.remindTime}${rem.body.isNotEmpty ? '\n${rem.body}' : ''}'),
                        value: rem.isEnabled,
                        onChanged: (v) => _toggle(rem, v),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await NotificationsService.instance.requestPermission();
                  await NotificationsService.instance.showNow(
                    '💕 HerDay reminder test',
                    "Notifications are working, love! 🌸",
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test notification sent — check your notifications 🔔')),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send a test notification'),
              ),
            ],
          );
        },
      ),
    );
  }
}
