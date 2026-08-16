/// Priority level for scheduling a cleaning requirement.
enum TaskPriority {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}

/// Represents the cleaning requirement rules for a specific item (how it should be cleaned,
/// how often, and estimated duration) independent of calendar scheduling.
class CleaningRequirement {
  final String id;
  final String itemId; // Reference to ConfirmedItem.id
  final String action; // e.g. "Wipe", "Vacuum", "Dust", "Mop"
  final int frequencyDays; // e.g. 2, 7, 14
  final int estimatedMinutes;
  final TaskPriority priority;
  final String? instructions;
  final DateTime? lastCleanedDate;

  CleaningRequirement({
    String? id,
    required this.itemId,
    required this.action,
    required this.frequencyDays,
    required this.estimatedMinutes,
    this.priority = TaskPriority.medium,
    this.instructions,
    this.lastCleanedDate,
  }) : id = id ?? 'req_${DateTime.now().millisecondsSinceEpoch}_$itemId';

  String get frequencyLabel {
    if (frequencyDays == 1) return 'Daily';
    return 'Every $frequencyDays days';
  }

  CleaningRequirement copyWith({
    String? id,
    String? itemId,
    String? action,
    int? frequencyDays,
    int? estimatedMinutes,
    TaskPriority? priority,
    String? instructions,
    DateTime? lastCleanedDate,
  }) {
    return CleaningRequirement(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      action: action ?? this.action,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      priority: priority ?? this.priority,
      instructions: instructions ?? this.instructions,
      lastCleanedDate: lastCleanedDate ?? this.lastCleanedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'action': action,
      'frequencyDays': frequencyDays,
      'estimatedMinutes': estimatedMinutes,
      'priority': priority.name,
      'instructions': instructions,
      'lastCleanedDate': lastCleanedDate?.toIso8601String(),
    };
  }

  factory CleaningRequirement.fromJson(Map<String, dynamic> json) {
    return CleaningRequirement(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      action: json['action'] as String,
      frequencyDays: json['frequencyDays'] as int? ?? 7,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 2,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      instructions: json['instructions'] as String?,
      lastCleanedDate: json['lastCleanedDate'] != null
          ? DateTime.tryParse(json['lastCleanedDate'] as String)
          : null,
    );
  }
}
