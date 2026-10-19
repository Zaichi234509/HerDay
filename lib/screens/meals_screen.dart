import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/herday_db.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  late Future<List<Meal>> _future;
  DateTime _day = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = HerDayDb.instance.fetchMealsOn(_day);
  }

  void _reload() => setState(() => _future = HerDayDb.instance.fetchMealsOn(_day));

  void _shift(int days) {
    setState(() => _day = _day.add(Duration(days: days)));
    _reload();
  }

  Future<void> _add() async {
    final desc = TextEditingController();
    final calories = TextEditingController();
    String type = 'Lunch';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Log a Meal 🍱'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Meal'),
                  items: mealTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text('${mealIcons[mealTypes.indexOf(t)]} $t')))
                      .toList(),
                  onChanged: (v) => setLocal(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: desc,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'What did she eat?', hintText: 'Egg + rice'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories (optional)'),
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
    if (saved != true || desc.text.trim().isEmpty) return;
    try {
      await HerDayDb.instance.addMeal(
        mealType: type,
        description: desc.text.trim(),
        calories: int.tryParse(calories.text.trim()),
        date: _day,
      );
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String _iconFor(String type) {
    final i = mealTypes.indexOf(type);
    return i >= 0 ? mealIcons[i] : '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meals 🍱')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(-1)),
                Expanded(
                  child: Text(
                    isSameDay(_day, DateTime.now()) ? 'Today' : shortDate(_day),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(1)),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<List<Meal>>(
              future: _future,
              onRetry: _reload,
              builder: (meals) {
                if (meals.isEmpty) {
                  return const EmptyState(
                    emoji: '🍱',
                    title: 'No meals logged',
                    subtitle: "Don't forget to eat today, love ❤️",
                  );
                }
                final totalCal = meals.fold<int>(0, (s, m) => s + (m.calories ?? 0));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    if (totalCal > 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text('🔥 Approx. $totalCal kcal today',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ...mealTypes.map((type) {
                      final ofType = meals.where((m) => m.mealType == type).toList();
                      if (ofType.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle('${_iconFor(type)} $type'),
                          ...ofType.map((m) => Dismissible(
                                key: ValueKey(m.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                      color: Colors.red.shade300, borderRadius: BorderRadius.circular(20)),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) async {
                                  try {
                                    await HerDayDb.instance.deleteMeal(m.id);
                                    _reload();
                                  } catch (e) {
                                    if (mounted) showError(context, e);
                                  }
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text(m.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    trailing: m.calories != null ? Text('${m.calories} kcal') : null,
                                  ),
                                ),
                              )),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
