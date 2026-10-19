import '../core/format.dart';

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
String _s(dynamic v) => (v as String?) ?? '';

class Profile {
  final String id;
  String displayName;
  String bio;
  String partnerName;
  DateTime? anniversary;
  String theme;
  double dailyBudget;

  Profile({
    required this.id,
    this.displayName = '',
    this.bio = '',
    this.partnerName = '',
    this.anniversary,
    this.theme = 'sakura',
    this.dailyBudget = 500,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: _s(m['id']),
        displayName: _s(m['display_name']),
        bio: _s(m['bio']),
        partnerName: _s(m['partner_name']),
        anniversary:
            (m['anniversary'] as String?)?.isEmpty ?? true ? null : parseDate(m['anniversary'] as String?),
        theme: m['theme'] as String? ?? 'sakura',
        dailyBudget: _d(m['daily_budget']) == 0 ? 500 : _d(m['daily_budget']),
      );

  Map<String, dynamic> toMap() => {
        'display_name': displayName,
        'bio': bio,
        'partner_name': partnerName,
        'anniversary': anniversary == null ? null : dateKey(anniversary!),
        'theme': theme,
        'daily_budget': dailyBudget,
      };
}

class TaskItem {
  final String id;
  String title;
  String notes;
  String category;
  String priority;
  DateTime dueDate;
  bool isDone;
  bool isRecurring;

  TaskItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.category = 'Personal',
    this.priority = 'Normal',
    required this.dueDate,
    this.isDone = false,
    this.isRecurring = false,
  });

  factory TaskItem.fromMap(Map<String, dynamic> m) => TaskItem(
        id: _s(m['id']),
        title: _s(m['title']),
        notes: _s(m['notes']),
        category: _s(m['category']).isEmpty ? 'Personal' : _s(m['category']),
        priority: _s(m['priority']).isEmpty ? 'Normal' : _s(m['priority']),
        dueDate: parseDate(m['due_date'] as String?),
        isDone: m['is_done'] as bool? ?? false,
        isRecurring: m['is_recurring'] as bool? ?? false,
      );
}

class CalendarEvent {
  final String id;
  String title;
  String notes;
  DateTime eventDate;
  String startTime;
  String category;

  CalendarEvent({
    required this.id,
    required this.title,
    this.notes = '',
    required this.eventDate,
    this.startTime = '',
    this.category = 'Personal',
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> m) => CalendarEvent(
        id: _s(m['id']),
        title: _s(m['title']),
        notes: _s(m['notes']),
        eventDate: parseDate(m['event_date'] as String?),
        startTime: _s(m['start_time']),
        category: _s(m['category']).isEmpty ? 'Personal' : _s(m['category']),
      );
}

class JournalEntry {
  final String id;
  String title;
  String content;
  String mood;
  String tags;
  bool isFavorite;
  DateTime entryDate;

  JournalEntry({
    required this.id,
    this.title = '',
    this.content = '',
    this.mood = '🙂',
    this.tags = '',
    this.isFavorite = false,
    required this.entryDate,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
        id: _s(m['id']),
        title: _s(m['title']),
        content: _s(m['content']),
        mood: _s(m['mood']).isEmpty ? '🙂' : _s(m['mood']),
        tags: _s(m['tags']),
        isFavorite: m['is_favorite'] as bool? ?? false,
        entryDate: parseDate(m['entry_date'] as String?),
      );
}

class MoodLog {
  final String mood;
  final DateTime loggedDate;
  MoodLog({required this.mood, required this.loggedDate});

  factory MoodLog.fromMap(Map<String, dynamic> m) => MoodLog(
        mood: _s(m['mood']).isEmpty ? '🙂' : _s(m['mood']),
        loggedDate: parseDate(m['logged_date'] as String?),
      );
}

class Txn {
  final String id;
  String title;
  String category;
  double amount;
  String type; // income | expense
  DateTime txnDate;

  Txn({
    required this.id,
    this.title = '',
    this.category = 'Others',
    this.amount = 0,
    this.type = 'expense',
    required this.txnDate,
  });

  factory Txn.fromMap(Map<String, dynamic> m) => Txn(
        id: _s(m['id']),
        title: _s(m['title']),
        category: _s(m['category']).isEmpty ? 'Others' : _s(m['category']),
        amount: _d(m['amount']),
        type: _s(m['type']).isEmpty ? 'expense' : _s(m['type']),
        txnDate: parseDate(m['txn_date'] as String?),
      );
}

class Goal {
  final String id;
  String title;
  String description;
  double target;
  double currentValue;
  String unit;
  DateTime? deadline;

  Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.target = 1,
    this.currentValue = 0,
    this.unit = '',
    this.deadline,
  });

  double get progress => target <= 0 ? 0 : (currentValue / target).clamp(0, 1).toDouble();
  bool get isDone => target > 0 && currentValue >= target;

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: _s(m['id']),
        title: _s(m['title']),
        description: _s(m['description']),
        target: _d(m['target']) == 0 ? 1 : _d(m['target']),
        currentValue: _d(m['current_value']),
        unit: _s(m['unit']),
        deadline: (m['deadline'] as String?) == null ? null : parseDate(m['deadline'] as String?),
      );
}

class ShoppingItem {
  final String id;
  String name;
  String quantity;
  double estimatedPrice;
  String category;
  bool isBought;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = '1',
    this.estimatedPrice = 0,
    this.category = 'Others',
    this.isBought = false,
  });

  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
        id: _s(m['id']),
        name: _s(m['name']),
        quantity: _s(m['quantity']).isEmpty ? '1' : _s(m['quantity']),
        estimatedPrice: _d(m['estimated_price']),
        category: _s(m['category']).isEmpty ? 'Others' : _s(m['category']),
        isBought: m['is_bought'] as bool? ?? false,
      );
}

class Habit {
  final String id;
  String name;
  String icon;
  int goalPerDay;
  String unit;
  int todayCount;

  Habit({
    required this.id,
    required this.name,
    this.icon = '🌸',
    this.goalPerDay = 1,
    this.unit = 'times',
    this.todayCount = 0,
  });

  double get progress => goalPerDay <= 0 ? 0 : (todayCount / goalPerDay).clamp(0, 1).toDouble();
  bool get isDone => todayCount >= goalPerDay;

  factory Habit.fromMap(Map<String, dynamic> m) => Habit(
        id: _s(m['id']),
        name: _s(m['name']),
        icon: _s(m['icon']).isEmpty ? '🌸' : _s(m['icon']),
        goalPerDay: _i(m['goal_per_day']) == 0 ? 1 : _i(m['goal_per_day']),
        unit: _s(m['unit']).isEmpty ? 'times' : _s(m['unit']),
      );
}

class Meal {
  final String id;
  String mealType;
  String description;
  int? calories;
  DateTime mealDate;

  Meal({
    required this.id,
    this.mealType = 'Lunch',
    this.description = '',
    this.calories,
    required this.mealDate,
  });

  factory Meal.fromMap(Map<String, dynamic> m) => Meal(
        id: _s(m['id']),
        mealType: _s(m['meal_type']).isEmpty ? 'Lunch' : _s(m['meal_type']),
        description: _s(m['description']),
        calories: (m['calories'] as num?)?.toInt(),
        mealDate: parseDate(m['meal_date'] as String?),
      );
}

class Memory {
  final String id;
  String title;
  String description;
  String imageUrl;
  DateTime memoryDate;

  Memory({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    required this.memoryDate,
  });

  factory Memory.fromMap(Map<String, dynamic> m) => Memory(
        id: _s(m['id']),
        title: _s(m['title']),
        description: _s(m['description']),
        imageUrl: _s(m['image_url']),
        memoryDate: parseDate(m['memory_date'] as String?),
      );
}

class LoveMessage {
  final String id;
  String title;
  String body;
  bool isRead;
  DateTime createdAt;

  LoveMessage({
    required this.id,
    this.title = '💌 A message for you',
    this.body = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory LoveMessage.fromMap(Map<String, dynamic> m) => LoveMessage(
        id: _s(m['id']),
        title: _s(m['title']),
        body: _s(m['body']),
        isRead: m['is_read'] as bool? ?? false,
        createdAt: parseDate(m['created_at'] as String?),
      );
}

class VaultNote {
  final String id;
  String title;
  String content;

  VaultNote({required this.id, this.title = '', this.content = ''});

  factory VaultNote.fromMap(Map<String, dynamic> m) => VaultNote(
        id: _s(m['id']),
        title: _s(m['title']),
        content: _s(m['content']),
      );
}
