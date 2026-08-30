import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cleaning_plan.dart';
import '../models/cleaning_streak.dart';
import '../models/scanner_session.dart';
import '../models/task_completion.dart';
import '../models/task_frequency.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  factory LocalDbService() => instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'kleenai_local.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plan_tasks (
            id TEXT PRIMARY KEY,
            source_item_id TEXT,
            source_item_name TEXT,
            room_name TEXT,
            category TEXT,
            cleaning_action TEXT,
            frequency TEXT,
            estimated_minutes INTEGER,
            scheduled_day TEXT,
            status TEXT,
            ai_tip TEXT,
            week_number INTEGER,
            updated_at TEXT,
            is_dirty INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE task_completions (
            id TEXT PRIMARY KEY,
            task_id TEXT,
            task_name TEXT,
            room_name TEXT,
            scheduled_day TEXT,
            completed_at TEXT,
            actual_duration_seconds INTEGER,
            status TEXT,
            is_dirty INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE streak_data (
            id INTEGER PRIMARY KEY,
            current_streak INTEGER,
            longest_streak INTEGER,
            last_completed_date TEXT,
            total_completed_days INTEGER,
            completed_dates_json TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT,
            entity_id TEXT,
            action TEXT,
            payload_json TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // --- Tasks Operations ---

  Future<List<PlanTask>> loadTasks() async {
    final db = await database;
    final rows = await db.query('plan_tasks');
    return rows.map((row) {
      final sourceItem = ReviewItem(
        id: row['source_item_id'] as String? ?? row['id'] as String,
        name: row['source_item_name'] as String? ?? 'Cleaning Activity',
        roomName: row['room_name'] as String? ?? 'General',
        category: _parseCategory(row['category'] as String?),
        cleaningAction: row['cleaning_action'] as String? ?? 'Clean',
        frequency: row['frequency'] as String? ?? 'Weekly',
        isConfirmed: true,
      );

      final dayStr = row['scheduled_day'] as String? ?? 'monday';
      final day = WeekDay.values.firstWhere(
        (d) => d.name.toLowerCase() == dayStr.toLowerCase(),
        orElse: () => WeekDay.monday,
      );

      final statusStr = row['status'] as String? ?? 'pending';
      final status = TaskStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
        orElse: () => TaskStatus.pending,
      );

      return PlanTask(
        id: row['id'] as String,
        sourceItem: sourceItem,
        estimatedMinutes: row['estimated_minutes'] as int? ?? 15,
        scheduledDay: day,
        status: status,
        frequency: TaskFrequency.parse(row['frequency'] as String? ?? 'Weekly'),
        aiTip: row['ai_tip'] as String?,
        weekNumber: row['week_number'] as int? ?? 1,
      );
    }).toList();
  }

  ItemCategory _parseCategory(String? catStr) {
    if (catStr == null) return ItemCategory.other;
    return ItemCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == catStr.toLowerCase(),
      orElse: () => ItemCategory.other,
    );
  }

  Future<void> saveTasks(List<PlanTask> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        'plan_tasks',
        {
          'id': task.id,
          'source_item_id': task.sourceItem.id,
          'source_item_name': task.sourceItem.name,
          'room_name': task.roomName,
          'category': task.sourceItem.category.name,
          'cleaning_action': task.sourceItem.cleaningAction,
          'frequency': task.frequency.displayName,
          'estimated_minutes': task.estimatedMinutes,
          'scheduled_day': task.scheduledDay.name,
          'status': task.status.name,
          'ai_tip': task.aiTip,
          'week_number': task.weekNumber,
          'updated_at': DateTime.now().toIso8601String(),
          'is_dirty': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveSingleTask(PlanTask task) async {
    final db = await database;
    final payload = {
      'id': task.id,
      'source_item_id': task.sourceItem.id,
      'source_item_name': task.sourceItem.name,
      'room_name': task.roomName,
      'category': task.sourceItem.category.name,
      'cleaning_action': task.sourceItem.cleaningAction,
      'frequency': task.frequency.displayName,
      'estimated_minutes': task.estimatedMinutes,
      'scheduled_day': task.scheduledDay.name,
      'status': task.status.name,
      'ai_tip': task.aiTip,
      'week_number': task.weekNumber,
      'updated_at': DateTime.now().toIso8601String(),
      'is_dirty': 1,
    };

    await db.insert('plan_tasks', payload, conflictAlgorithm: ConflictAlgorithm.replace);

    await enqueueSync('task', task.id, 'upsert', jsonEncode(payload));
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete('plan_tasks', where: 'id = ?', whereArgs: [taskId]);
    await enqueueSync('task', taskId, 'delete', jsonEncode({'id': taskId}));
  }

  Future<void> clearAllTasks() async {
    final db = await database;
    await db.delete('plan_tasks');
  }

  // --- Completions Operations ---

  Future<void> saveCompletion(TaskCompletion completion) async {
    final db = await database;
    final payload = {
      'id': 'comp_${completion.taskId}_${completion.completedAt.millisecondsSinceEpoch}',
      'task_id': completion.taskId,
      'task_name': completion.taskName,
      'room_name': completion.roomName,
      'scheduled_day': completion.scheduledDay.name,
      'completed_at': completion.completedAt.toIso8601String(),
      'actual_duration_seconds': completion.actualDuration?.inSeconds,
      'status': completion.status.name,
      'is_dirty': 1,
    };
    await db.insert('task_completions', payload, conflictAlgorithm: ConflictAlgorithm.replace);
    await enqueueSync('completion', payload['id'] as String, 'upsert', jsonEncode(payload));
  }

  Future<List<TaskCompletion>> loadCompletions() async {
    final db = await database;
    final rows = await db.query('task_completions');
    return rows.map((r) {
      final dayStr = r['scheduled_day'] as String? ?? 'monday';
      final day = WeekDay.values.firstWhere(
        (d) => d.name.toLowerCase() == dayStr.toLowerCase(),
        orElse: () => WeekDay.monday,
      );
      final statusStr = r['status'] as String? ?? 'completed';
      final status = TaskStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
        orElse: () => TaskStatus.completed,
      );
      final durSec = r['actual_duration_seconds'] as int?;

      return TaskCompletion(
        taskId: r['task_id'] as String,
        taskName: r['task_name'] as String? ?? 'Task',
        roomName: r['room_name'] as String? ?? 'Room',
        scheduledDay: day,
        completedAt: DateTime.tryParse(r['completed_at'] as String? ?? '') ?? DateTime.now(),
        actualDuration: durSec != null ? Duration(seconds: durSec) : null,
        status: status,
      );
    }).toList();
  }

  // --- Streak Operations ---

  Future<CleaningStreak> loadStreak() async {
    final db = await database;
    final rows = await db.query('streak_data', where: 'id = 1');
    if (rows.isEmpty) return CleaningStreak.initial();
    final row = rows.first;

    final datesJson = row['completed_dates_json'] as String?;
    List<DateTime> completedDates = [];
    if (datesJson != null) {
      try {
        final list = jsonDecode(datesJson) as List;
        completedDates = list.map((e) => DateTime.parse(e as String)).toList();
      } catch (_) {}
    }

    return CleaningStreak(
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      lastCompletedDate: row['last_completed_date'] != null
          ? DateTime.tryParse(row['last_completed_date'] as String)
          : null,
      totalCompletedDays: row['total_completed_days'] as int? ?? 0,
      completedDates: completedDates,
    );
  }

  Future<void> saveStreak(CleaningStreak streak) async {
    final db = await database;
    final payload = {
      'id': 1,
      'current_streak': streak.currentStreak,
      'longest_streak': streak.longestStreak,
      'last_completed_date': streak.lastCompletedDate?.toIso8601String(),
      'total_completed_days': streak.totalCompletedDays,
      'completed_dates_json': jsonEncode(streak.completedDates.map((d) => d.toIso8601String()).toList()),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await db.insert('streak_data', payload, conflictAlgorithm: ConflictAlgorithm.replace);
    await enqueueSync('streak', '1', 'upsert', jsonEncode(payload));
  }

  // --- Sync Queue Operations ---

  Future<void> enqueueSync(String entityType, String entityId, String action, String payloadJson) async {
    final db = await database;
    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'payload_json': payloadJson,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'id ASC');
  }

  Future<void> removeSyncItem(int queueId) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
  }
}
