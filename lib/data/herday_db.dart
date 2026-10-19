import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/format.dart';
import '../models/models.dart';

/// Single data layer for the whole app. Every query is scoped to the
/// signed-in user and double-protected by Supabase Row Level Security.
class HerDayDb {
  HerDayDb._();
  static final HerDayDb instance = HerDayDb._();

  SupabaseClient get _c => Supabase.instance.client;

  String get uid {
    final u = _c.auth.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u.id;
  }

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) f) {
    if (data == null) return [];
    return (data as List)
        .map((e) => f(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------- Profile ----------
  Future<Profile?> fetchProfile() async {
    final data = await _c.from('profiles').select().eq('id', uid).maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> updateProfile(Profile p) async {
    await _c.from('profiles').update(p.toMap()).eq('id', uid);
  }

  Future<void> ensureProfile(String displayName) async {
    final existing = await fetchProfile();
    if (existing == null) {
      await _c.from('profiles').insert({'id': uid, 'display_name': displayName});
    } else if (displayName.isNotEmpty && existing.displayName.isEmpty) {
      existing.displayName = displayName;
      await updateProfile(existing);
    }
  }

  // ---------- Tasks ----------
  Future<List<TaskItem>> fetchTasks() async {
    final data = await _c
        .from('tasks')
        .select()
        .eq('user_id', uid)
        .order('due_date')
        .order('created_at');
    return _mapList(data, TaskItem.fromMap);
  }

  Future<void> addTask({
    required String title,
    String notes = '',
    String category = 'Personal',
    String priority = 'Normal',
    required DateTime dueDate,
    bool isRecurring = false,
  }) async {
    await _c.from('tasks').insert({
      'user_id': uid,
      'title': title,
      'notes': notes,
      'category': category,
      'priority': priority,
      'due_date': dateKey(dueDate),
      'is_recurring': isRecurring,
    });
  }

  Future<void> setTaskDone(TaskItem t, bool done) async {
    await _c.from('tasks').update({
      'is_done': done,
      'completed_at': done ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', t.id);
    // Daily recurring tasks roll over to tomorrow once completed.
    if (done && t.isRecurring) {
      await addTask(
        title: t.title,
        notes: t.notes,
        category: t.category,
        priority: t.priority,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isRecurring: true,
      );
    }
  }

  Future<void> deleteTask(String id) async {
    await _c.from('tasks').delete().eq('id', id);
  }

  // ---------- Calendar events ----------
  Future<List<CalendarEvent>> fetchEvents() async {
    final data = await _c.from('events').select().eq('user_id', uid).order('event_date');
    return _mapList(data, CalendarEvent.fromMap);
  }

  Future<void> addEvent({
    required String title,
    String notes = '',
    required DateTime date,
    String startTime = '',
    String category = 'Personal',
  }) async {
    await _c.from('events').insert({
      'user_id': uid,
      'title': title,
      'notes': notes,
      'event_date': dateKey(date),
      'start_time': startTime,
      'category': category,
    });
  }

  Future<void> deleteEvent(String id) async {
    await _c.from('events').delete().eq('id', id);
  }

  // ---------- Journal ----------
  Future<List<JournalEntry>> fetchJournal() async {
    final data = await _c
        .from('journal_entries')
        .select()
        .eq('user_id', uid)
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false);
    return _mapList(data, JournalEntry.fromMap);
  }

  Future<void> saveJournal({
    String? id,
    required String title,
    required String content,
    required String mood,
    required String tags,
    required DateTime date,
  }) async {
    final values = {
      'title': title,
      'content': content,
      'mood': mood,
      'tags': tags,
      'entry_date': dateKey(date),
    };
    if (id == null) {
      await _c.from('journal_entries').insert({'user_id': uid, ...values});
    } else {
      await _c.from('journal_entries').update(values).eq('id', id);
    }
    // Journaling also logs the day's mood.
    await upsertMood(mood, date);
  }

  Future<void> setJournalFavorite(String id, bool fav) async {
    await _c.from('journal_entries').update({'is_favorite': fav}).eq('id', id);
  }

  Future<void> deleteJournal(String id) async {
    await _c.from('journal_entries').delete().eq('id', id);
  }

  // ---------- Mood ----------
  Future<List<MoodLog>> fetchMoods({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final data = await _c
        .from('moods')
        .select()
        .eq('user_id', uid)
        .gte('logged_date', dateKey(since))
        .order('logged_date', ascending: false);
    return _mapList(data, MoodLog.fromMap);
  }

  Future<void> upsertMood(String mood, DateTime date, {String note = ''}) async {
    await _c.from('moods').upsert(
      {'user_id': uid, 'mood': mood, 'note': note, 'logged_date': dateKey(date)},
      onConflict: 'user_id,logged_date',
    );
  }

  // ---------- Budget / transactions ----------
  Future<List<Txn>> fetchTransactions(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final data = await _c
        .from('transactions')
        .select()
        .eq('user_id', uid)
        .gte('txn_date', dateKey(start))
        .lt('txn_date', dateKey(end))
        .order('txn_date', ascending: false)
        .order('created_at', ascending: false);
    return _mapList(data, Txn.fromMap);
  }

  Future<List<Txn>> fetchTransactionsOn(DateTime day) async {
    final data = await _c
        .from('transactions')
        .select()
        .eq('user_id', uid)
        .eq('txn_date', dateKey(day))
        .order('created_at', ascending: false);
    return _mapList(data, Txn.fromMap);
  }

  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required String type,
    required DateTime date,
  }) async {
    await _c.from('transactions').insert({
      'user_id': uid,
      'title': title,
      'category': category,
      'amount': amount,
      'type': type,
      'txn_date': dateKey(date),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _c.from('transactions').delete().eq('id', id);
  }

  Future<double> fetchBudget(DateTime month) async {
    final data = await _c
        .from('budgets')
        .select()
        .eq('user_id', uid)
        .eq('month', monthKey(month))
        .maybeSingle();
    if (data == null) return 0;
    return (data['amount'] as num?)?.toDouble() ?? 0;
  }

  Future<void> setBudget(DateTime month, double amount) async {
    await _c.from('budgets').upsert(
      {'user_id': uid, 'month': monthKey(month), 'amount': amount},
      onConflict: 'user_id,month',
    );
  }

  // ---------- Goals ----------
  Future<List<Goal>> fetchGoals() async {
    final data = await _c.from('goals').select().eq('user_id', uid).order('created_at');
    return _mapList(data, Goal.fromMap);
  }

  Future<void> addGoal({
    required String title,
    String description = '',
    required double target,
    String unit = '',
    DateTime? deadline,
  }) async {
    await _c.from('goals').insert({
      'user_id': uid,
      'title': title,
      'description': description,
      'target': target,
      'unit': unit,
      'deadline': deadline == null ? null : dateKey(deadline),
    });
  }

  Future<void> setGoalProgress(Goal g, double value) async {
    await _c.from('goals').update({'current_value': value}).eq('id', g.id);
  }

  Future<void> deleteGoal(String id) async {
    await _c.from('goals').delete().eq('id', id);
  }

  // ---------- Shopping ----------
  Future<List<ShoppingItem>> fetchShopping() async {
    final data = await _c
        .from('shopping_items')
        .select()
        .eq('user_id', uid)
        .order('is_bought')
        .order('created_at', ascending: false);
    return _mapList(data, ShoppingItem.fromMap);
  }

  Future<void> addShopping({
    required String name,
    String quantity = '1',
    double estimatedPrice = 0,
    String category = 'Others',
  }) async {
    await _c.from('shopping_items').insert({
      'user_id': uid,
      'name': name,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'category': category,
    });
  }

  Future<void> setShoppingBought(String id, bool bought) async {
    await _c.from('shopping_items').update({'is_bought': bought}).eq('id', id);
  }

  Future<void> deleteShopping(String id) async {
    await _c.from('shopping_items').delete().eq('id', id);
  }

  Future<void> clearBoughtShopping() async {
    await _c.from('shopping_items').delete().eq('user_id', uid).eq('is_bought', true);
  }

  // ---------- Habits / self-care ----------
  Future<List<Habit>> fetchHabitsWithToday() async {
    final habitsData = await _c.from('habits').select().eq('user_id', uid).order('created_at');
    final habits = _mapList(habitsData, Habit.fromMap);
    final logsData = await _c
        .from('habit_logs')
        .select()
        .eq('user_id', uid)
        .eq('log_date', dateKey(DateTime.now()));
    final counts = <String, int>{};
    for (final row in (logsData as List)) {
      final m = Map<String, dynamic>.from(row as Map);
      counts[m['habit_id'] as String] = (m['count'] as num?)?.toInt() ?? 0;
    }
    for (final h in habits) {
      h.todayCount = counts[h.id] ?? 0;
    }
    return habits;
  }

  Future<void> addHabit({
    required String name,
    String icon = '🌸',
    int goalPerDay = 1,
    String unit = 'times',
  }) async {
    await _c.from('habits').insert({
      'user_id': uid,
      'name': name,
      'icon': icon,
      'goal_per_day': goalPerDay,
      'unit': unit,
    });
  }

  Future<void> logHabit(Habit h, int newCount) async {
    await _c.from('habit_logs').upsert(
      {
        'user_id': uid,
        'habit_id': h.id,
        'log_date': dateKey(DateTime.now()),
        'count': newCount,
      },
      onConflict: 'habit_id,log_date',
    );
  }

  Future<void> deleteHabit(String id) async {
    await _c.from('habits').delete().eq('id', id);
  }

  /// First-run defaults so the self-care card never looks empty.
  Future<void> seedDefaultHabitsIfEmpty() async {
    final existing = await _c.from('habits').select('id').eq('user_id', uid).limit(1);
    if ((existing as List).isNotEmpty) return;
    final defaults = [
      {'name': 'Drink water', 'icon': '💧', 'goal_per_day': 8, 'unit': 'glasses'},
      {'name': 'Skincare', 'icon': '🧴', 'goal_per_day': 2, 'unit': 'times'},
      {'name': 'Take vitamins', 'icon': '💊', 'goal_per_day': 1, 'unit': 'times'},
      {'name': 'Move / exercise', 'icon': '🏃', 'goal_per_day': 1, 'unit': 'session'},
      {'name': 'Read', 'icon': '📚', 'goal_per_day': 1, 'unit': 'times'},
    ];
    for (final d in defaults) {
      await _c.from('habits').insert({'user_id': uid, ...d});
    }
  }

  // ---------- Meals ----------
  Future<List<Meal>> fetchMealsOn(DateTime day) async {
    final data = await _c
        .from('meals')
        .select()
        .eq('user_id', uid)
        .eq('meal_date', dateKey(day))
        .order('created_at');
    return _mapList(data, Meal.fromMap);
  }

  Future<void> addMeal({
    required String mealType,
    required String description,
    int? calories,
    required DateTime date,
  }) async {
    await _c.from('meals').insert({
      'user_id': uid,
      'meal_type': mealType,
      'description': description,
      'calories': calories,
      'meal_date': dateKey(date),
    });
  }

  Future<void> deleteMeal(String id) async {
    await _c.from('meals').delete().eq('id', id);
  }

  // ---------- Memories & messages (Us) ----------
  Future<List<Memory>> fetchMemories() async {
    final data = await _c
        .from('memories')
        .select()
        .eq('user_id', uid)
        .order('memory_date', ascending: false);
    return _mapList(data, Memory.fromMap);
  }

  Future<void> addMemory({
    required String title,
    String description = '',
    String imageUrl = '',
    required DateTime date,
  }) async {
    await _c.from('memories').insert({
      'user_id': uid,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'memory_date': dateKey(date),
    });
  }

  Future<void> deleteMemory(String id) async {
    await _c.from('memories').delete().eq('id', id);
  }

  Future<List<LoveMessage>> fetchMessages() async {
    final data = await _c
        .from('messages')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return _mapList(data, LoveMessage.fromMap);
  }

  Future<void> addMessage({required String title, required String body}) async {
    await _c.from('messages').insert({'user_id': uid, 'title': title, 'body': body});
  }

  Future<void> markMessageRead(String id) async {
    await _c.from('messages').update({'is_read': true}).eq('id', id);
  }

  Future<void> deleteMessage(String id) async {
    await _c.from('messages').delete().eq('id', id);
  }

  // ---------- Private vault ----------
  Future<List<VaultNote>> fetchVault() async {
    final data = await _c.from('vault_notes').select().eq('user_id', uid).order('created_at', ascending: false);
    return _mapList(data, VaultNote.fromMap);
  }

  Future<void> saveVault({String? id, required String title, required String content}) async {
    if (id == null) {
      await _c.from('vault_notes').insert({'user_id': uid, 'title': title, 'content': content});
    } else {
      await _c.from('vault_notes').update({'title': title, 'content': content}).eq('id', id);
    }
  }

  Future<void> deleteVault(String id) async {
    await _c.from('vault_notes').delete().eq('id', id);
  }

  // ---------- Dashboard helpers ----------
  Future<int> countDoneTasks() async {
    final data = await _c.from('tasks').select('id').eq('user_id', uid).eq('is_done', true);
    return (data as List).length;
  }

  Future<int> countJournal() async {
    final data = await _c.from('journal_entries').select('id').eq('user_id', uid);
    return (data as List).length;
  }
}
