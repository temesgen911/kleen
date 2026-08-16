import 'cleaning_plan.dart' show TaskStatus, WeekDay;

/// Historical audit record of a cleaning task execution.
class TaskCompletion {
  final String id;
  final String taskId;
  final String taskName;
  final String roomName;
  final WeekDay scheduledDay;
  final DateTime completedAt;
  final Duration? actualDuration;
  final TaskStatus status;

  TaskCompletion({
    String? id,
    required this.taskId,
    required this.taskName,
    required this.roomName,
    required this.scheduledDay,
    DateTime? completedAt,
    this.actualDuration,
    this.status = TaskStatus.completed,
  })  : id = id ?? 'comp_${DateTime.now().millisecondsSinceEpoch}_$taskId',
        completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskName': taskName,
      'roomName': roomName,
      'scheduledDay': scheduledDay.name,
      'completedAt': completedAt.toIso8601String(),
      'actualDurationMs': actualDuration?.inMilliseconds,
      'status': status.name,
    };
  }

  factory TaskCompletion.fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String? ?? 'Task',
      roomName: json['roomName'] as String? ?? 'Room',
      scheduledDay: WeekDay.values.firstWhere(
        (w) => w.name == json['scheduledDay'],
        orElse: () => WeekDay.monday,
      ),
      completedAt: DateTime.parse(json['completedAt'] as String),
      actualDuration: json['actualDurationMs'] != null
          ? Duration(milliseconds: json['actualDurationMs'] as int)
          : null,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.completed,
      ),
    );
  }
}
