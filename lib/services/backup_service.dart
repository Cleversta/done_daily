import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_model.dart';
import '../models/goal_model.dart';
import '../models/settings_model.dart';
import '../models/recurring_goal.dart';

const _uuid = Uuid();

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  Future<void> exportData() async {
    final dailyBox = await Hive.openBox<Daily>('daily');
    final settingsBox = await Hive.openBox<AppSettings>('settings');
    final recurringBox = await Hive.openBox<RecurringGoal>('recurring_goals');

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'settings': _settingsToJson(settingsBox.get('app_settings')),
      'recurringGoals': recurringBox.values.map(_recurringToJson).toList(),
      'days': dailyBox.values.map(_dailyToJson).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final file = File('${dir.path}/done_daily_backup_$timestamp.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'DONE:Daily backup',
    );
  }

  /// Returns number of days restored, or -1 if user cancelled, or throws on error.
  Future<int> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return -1;

    final path = result.files.single.path;
    if (path == null) return -1;

    final content = await File(path).readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    final dailyBox = await Hive.openBox<Daily>('daily');
    final recurringBox = await Hive.openBox<RecurringGoal>('recurring_goals');

    // Restore recurring goals
    final recurringList = data['recurringGoals'] as List<dynamic>? ?? [];
    for (final r in recurringList) {
      final goal = RecurringGoal(
        id: r['id'] as String? ?? _uuid.v4(),
        title: r['title'] as String? ?? '',
        isPriority: r['isPriority'] as bool? ?? false,
        days: (r['days'] as List<dynamic>?)?.cast<int>() ?? [],
      );
      await recurringBox.put(goal.id, goal);
    }

    // Restore daily records
    final daysList = data['days'] as List<dynamic>? ?? [];
    for (final d in daysList) {
      final goalsList = (d['goals'] as List<dynamic>? ?? []).map((g) => Goal(
        id: g['id'] as String? ?? _uuid.v4(),
        title: g['title'] as String? ?? '',
        isCompleted: g['isCompleted'] as bool? ?? false,
        isPriority: g['isPriority'] as bool? ?? false,
        recurringTemplateId: g['recurringTemplateId'] as String?,
        createdAt: DateTime.tryParse(g['createdAt'] as String? ?? '') ?? DateTime.now(),
      )).toList();

      final daily = Daily(
        id: d['id'] as String,
        date: DateTime.parse(d['date'] as String),
        goals: goalsList,
        isRestDay: d['isRestDay'] as bool? ?? false,
        reflection: d['reflection'] as String? ?? '',
      );
      await dailyBox.put(daily.id, daily);
    }

    return daysList.length;
  }

  Map<String, dynamic> _settingsToJson(AppSettings? s) {
    if (s == null) return {};
    return {
      'workEndHour': s.workEndHour,
      'workEndMinute': s.workEndMinute,
      'restDays': s.restDays,
      'notificationsEnabled': s.notificationsEnabled,
      'isDarkMode': s.isDarkMode,
    };
  }

  Map<String, dynamic> _recurringToJson(RecurringGoal g) => {
    'id': g.id,
    'title': g.title,
    'isPriority': g.isPriority,
    'days': g.days,
  };

  Map<String, dynamic> _dailyToJson(Daily d) => {
    'id': d.id,
    'date': d.date.toIso8601String(),
    'isRestDay': d.isRestDay,
    'reflection': d.reflection,
    'goals': d.goals.map((g) => {
      'id': g.id,
      'title': g.title,
      'isCompleted': g.isCompleted,
      'isPriority': g.isPriority,
      'recurringTemplateId': g.recurringTemplateId,
      'createdAt': g.createdAt.toIso8601String(),
    }).toList(),
  };
}
