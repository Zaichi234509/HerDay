import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class _ChatMsg {
  final String text;
  final bool fromHer;
  _ChatMsg(this.text, this.fromHer);
}

/// 🤖 Ask HerDay — a friendly assistant that answers from her real data.
///
/// Rule-based on purpose (no API keys, works offline against Supabase):
/// try "What do I need to do today?", "How much did I spend this week?",
/// "What are my goals?", "How's my mood this week?"
/// To upgrade to a full LLM later, swap [_answer] for a Supabase Edge
/// Function call — the UI won't need to change.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _msgs = [
    _ChatMsg("Hi love! 🌸 I'm HerDay. Ask me about your day, spending, goals, mood — anything in your app 💕", false),
  ];
  bool _thinking = false;

  static const List<String> _suggestions = [
    'What do I need to do today?',
    'How much did I spend this week?',
    'What are my goals?',
    "How's my mood this week?",
    'What do I need to buy?',
    'How is my self-care today?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty || _thinking) return;
    setState(() {
      _msgs.add(_ChatMsg(q, true));
      _thinking = true;
      _input.clear();
    });
    _scrollDown();
    try {
      final answer = await _answer(q.toLowerCase());
      if (!mounted) return;
      setState(() => _msgs.add(_ChatMsg(answer, false)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _msgs.add(_ChatMsg('Hmm, I had trouble checking that 😔 (${friendlyError(e)})', false)));
    } finally {
      if (mounted) setState(() => _thinking = false);
      _scrollDown();
    }
  }

  Future<String> _answer(String q) async {
    final db = HerDayDb.instance;
    final now = DateTime.now();
    bool has(List<String> words) => words.any(q.contains);

    // Tasks / today
    if (has(['today', 'do today', 'schedule', 'plan'])) {
      final tasks = (await db.fetchTasks()).where((t) => isSameDay(t.dueDate, now)).toList();
      final events = (await db.fetchEvents()).where((e) => isSameDay(e.eventDate, now)).toList();
      if (tasks.isEmpty && events.isEmpty) {
        return 'Nothing scheduled today, love 🌿 Enjoy the calm — or add a task from the Tasks tab ✅';
      }
      final buf = StringBuffer('Here\'s today (${friendlyDate(now)}):\n');
      for (final e in events) {
        buf.writeln('📌 ${e.title}${e.startTime.isNotEmpty ? ' at ${e.startTime}' : ''}');
      }
      for (final t in tasks) {
        buf.writeln('${t.isDone ? '✅' : '☐'} ${t.title} (${t.category})');
      }
      final left = tasks.where((t) => !t.isDone).length;
      buf.write(left == 0 ? '\nAll tasks done! Proud of you 💕' : '\n$left task(s) left. Kaya mo yan! 💪');
      return buf.toString().trim();
    }

    // Spending
    if (has(['spend', 'spent', 'budget', 'expense', 'money', 'gastos'])) {
      final isWeek = has(['week']);
      final start = isWeek
          ? now.subtract(Duration(days: now.weekday - 1))
          : DateTime(now.year, now.month, 1);
      final end = isWeek ? start.add(const Duration(days: 7)) : DateTime(now.year, now.month + 1, 1);
      final txns = await db.fetchTransactionsBetween(
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day),
      );
      final spent = txns.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
      final income = txns.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
      final byCat = <String, double>{};
      for (final t in txns.where((t) => t.type == 'expense')) {
        byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
      }
      final top = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return 'This ${isWeek ? 'week' : 'month'} you spent ${peso(spent)}'
          '${income > 0 ? ' and earned ${peso(income)}' : ''}. 💰'
          '${top.isNotEmpty ? '\nBiggest: ${categoryIcon(top.first.key)} ${top.first.key} — ${peso(top.first.value)}' : ''}'
          '\nOpen Budget for the full breakdown 📊';
    }

    // Goals
    if (has(['goal', 'save', 'saving', 'target'])) {
      final goals = await db.fetchGoals();
      if (goals.isEmpty) return 'No goals yet 🎯 Add one in Me → Goals — save ₱20,000, read 5 books, anything!';
      final buf = StringBuffer('Your goals 🎯\n');
      for (final g in goals) {
        buf.writeln('${g.isDone ? '✅' : '🎯'} ${g.title} — ${(g.progress * 100).round()}%');
      }
      return buf.toString().trim();
    }

    // Shopping
    if (has(['shop', 'buy', 'grocery', 'need to get'])) {
      final items = (await db.fetchShopping()).where((i) => !i.isBought).toList();
      if (items.isEmpty) return 'Shopping list is all bought 🛍️ Nothing left to buy!';
      final total = items.fold<double>(0, (s, i) => s + i.estimatedPrice);
      final buf = StringBuffer('Still to buy 🛒 (est. ${peso(total)})\n');
      for (final i in items) {
        buf.writeln('☐ ${i.name} ×${i.quantity}');
      }
      return buf.toString().trim();
    }

    // Mood
    if (has(['mood', 'feel', 'feeling'])) {
      final logs = await db.fetchMoods(days: 7);
      if (logs.isEmpty) return 'No moods logged this week yet 😊 Tap an emoji on the Home tab!';
      final byDay = logs.reversed.map((m) => '${_dayName(m.loggedDate)} ${m.mood}').join(' · ');
      return 'Your mood this week 💭\n$byDay\nOpen Life Statistics for your 90-day trend 📊';
    }

    // Habits / self-care / water
    if (has(['self', 'habit', 'water', 'skincare', 'care'])) {
      final habits = await db.fetchHabitsWithToday();
      if (habits.isEmpty) return 'No self-care habits yet 💧 Add them in Self-Care!';
      final buf = StringBuffer("Today's self-care 🌸\n");
      for (final h in habits) {
        buf.writeln('${h.isDone ? '✅' : '☐'} ${h.icon} ${h.name}: ${h.todayCount}/${h.goalPerDay} ${h.unit}');
      }
      return buf.toString().trim();
    }

    // Journal
    if (has(['journal', 'diary', 'wrote', 'write'])) {
      final entries = await db.fetchJournal();
      if (entries.isEmpty) return 'No journal entries yet 📔 Tonight, write how your day went?';
      final recent = entries.take(3).toList();
      final buf = StringBuffer('Your latest journal entries 📝\n');
      for (final e in recent) {
        buf.writeln('${e.mood} ${shortDate(e.entryDate)} — ${e.title.isEmpty ? '(untitled)' : e.title}');
      }
      buf.write('You have ${entries.length} entr${entries.length == 1 ? 'y' : 'ies'} total. Keep writing, love 💕');
      return buf.toString().trim();
    }

    // Memories / us
    if (has(['memor', 'us', 'together', 'anniversary'])) {
      final profile = await db.fetchProfile();
      final memories = await db.fetchMemories();
      final buf = StringBuffer();
      if (profile?.anniversary != null) {
        final days = DateTime(now.year, now.month, now.day)
            .difference(DateTime(profile!.anniversary!.year, profile.anniversary!.month, profile.anniversary!.day))
            .inDays;
        buf.writeln('❤️ You\'ve been together $days days!');
      }
      if (memories.isNotEmpty) {
        buf.writeln('📸 Latest memory: "${memories.first.title}" (${shortDate(memories.first.memoryDate)})');
      } else {
        buf.writeln('No memories saved yet — add your first one in the Us tab 💕');
      }
      return buf.toString().trim();
    }

    if (has(['hello', 'hi', 'hey', 'kumusta', 'kamusta'])) {
      return '${greeting()}, love! ❤️ Ask me about today, your spending, goals, mood, shopping or self-care 🌸';
    }
    if (has(['thank', 'salamat'])) return 'Anytime, love 💕 I\'m always here.';

    return 'I can help with your day 🌸 Try:\n'
        '• "What do I need to do today?"\n'
        '• "How much did I spend this week?"\n'
        '• "What are my goals?"\n'
        '• "How\'s my mood this week?"\n'
        '• "What do I need to buy?"';
  }

  String _dayName(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ask HerDay 🤖')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _msgs.length,
              itemBuilder: (context, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.fromHer ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    decoration: BoxDecoration(
                      color: m.fromHer ? scheme.primary : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: m.fromHer ? scheme.onPrimary : scheme.onSurface, height: 1.35),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_thinking)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('HerDay is checking… 🌸', style: TextStyle(fontSize: 12)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _suggestions
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Ask HerDay anything…'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _thinking ? null : () => _send(),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
