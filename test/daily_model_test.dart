import 'package:done_daily/models/daily_model.dart';
import 'package:done_daily/models/goal_model.dart';
import 'package:flutter_test/flutter_test.dart';

Daily _daily({List<Goal> goals = const []}) =>
    Daily(id: '2026-01-01', date: DateTime(2026, 1, 1), goals: goals);

Goal _goal({bool isCompleted = false}) =>
    Goal(id: 'g1', title: 'Ship it', isCompleted: isCompleted, createdAt: DateTime(2026, 1, 1));

void main() {
  group('Daily equality', () {
    test('differs when focusMinutes changes', () {
      final base = _daily();
      expect(base.copyWith(focusMinutes: 25), isNot(equals(base)));
    });

    test('differs when tomorrowNote changes', () {
      final base = _daily();
      expect(base.copyWith(tomorrowNote: 'call the bank'), isNot(equals(base)));
    });
  });

  group('Daily copyWith', () {
    test('clears tomorrowNote when requested', () {
      final withNote = _daily().copyWith(tomorrowNote: 'call the bank');
      expect(withNote.copyWith(clearTomorrowNote: true).tomorrowNote, isNull);
    });

    test('clears notes when requested', () {
      final withNotes = _daily().copyWith(notes: 'scratch');
      expect(withNotes.copyWith(clearNotes: true).notes, isNull);
    });

    test('keeps existing values when nothing is passed', () {
      final original = _daily(goals: [_goal()]).copyWith(focusMinutes: 10, notes: 'scratch');
      final copy = original.copyWith();
      expect(copy, equals(original));
      expect(copy.notes, 'scratch');
      expect(copy.focusMinutes, 10);
    });
  });

  group('Daily progress', () {
    test('completionRatio is 0 without goals', () {
      expect(_daily().completionRatio, 0);
      expect(_daily().allGoalsCompleted, isFalse);
    });

    test('counts completed goals', () {
      final daily = _daily(goals: [_goal(isCompleted: true), _goal()]);
      expect(daily.completedGoalsCount, 1);
      expect(daily.completionRatio, 0.5);
      expect(daily.allGoalsCompleted, isFalse);
    });
  });
}
