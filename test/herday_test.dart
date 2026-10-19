import 'package:flutter_test/flutter_test.dart';
import 'package:herday/core/format.dart';
import 'package:herday/core/theme.dart';
import 'package:herday/models/models.dart';

void main() {
  group('format helpers', () {
    test('peso formats Philippine pesos', () {
      expect(peso(1250), '₱1,250');
      expect(peso(0), '₱0');
    });

    test('dateKey and monthKey are zero-padded', () {
      final d = DateTime(2026, 10, 5);
      expect(dateKey(d), '2026-10-05');
      expect(monthKey(d), '2026-10');
    });

    test('isSameDay compares calendar days', () {
      expect(isSameDay(DateTime(2026, 10, 19, 9), DateTime(2026, 10, 19, 22)), isTrue);
      expect(isSameDay(DateTime(2026, 10, 19), DateTime(2026, 10, 20)), isFalse);
    });
  });

  group('models', () {
    test('Goal progress clamps to 0..1', () {
      final g = Goal.fromMap({
        'id': '1',
        'title': 'Save',
        'target': 20000,
        'current_value': 25000,
      });
      expect(g.progress, 1.0);
      expect(g.isDone, isTrue);
    });

    test('TaskItem parses Supabase row', () {
      final t = TaskItem.fromMap({
        'id': 'abc',
        'title': 'Buy shampoo',
        'due_date': '2026-10-19',
        'is_done': true,
        'category': 'Shopping',
      });
      expect(t.title, 'Buy shampoo');
      expect(t.isDone, isTrue);
      expect(t.category, 'Shopping');
    });
  });

  group('themes', () {
    test('all six HerDay themes build', () {
      for (final o in HerDayThemes.options) {
        expect(HerDayThemes.build(o.name), isNotNull);
      }
      expect(HerDayThemes.options.length, 6);
    });
  });
}
