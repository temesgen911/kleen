enum TaskFrequency {
  daily,
  twiceWeekly,
  weekly,
  biWeekly,
  twiceMonthly,
  monthly,
  quarterly;

  String get displayName {
    switch (this) {
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.twiceWeekly:
        return '2x / Week';
      case TaskFrequency.weekly:
        return 'Weekly';
      case TaskFrequency.biWeekly:
        return 'Bi-Weekly';
      case TaskFrequency.twiceMonthly:
        return '2x / Month';
      case TaskFrequency.monthly:
        return 'Monthly';
      case TaskFrequency.quarterly:
        return 'Quarterly';
    }
  }

  int get intervalDays {
    switch (this) {
      case TaskFrequency.daily:
        return 1;
      case TaskFrequency.twiceWeekly:
        return 3;
      case TaskFrequency.weekly:
        return 7;
      case TaskFrequency.biWeekly:
        return 14;
      case TaskFrequency.twiceMonthly:
        return 15;
      case TaskFrequency.monthly:
        return 30;
      case TaskFrequency.quarterly:
        return 90;
    }
  }

  static TaskFrequency parse(String val) {
    final s = val.toLowerCase().strip();
    if (s.contains('bi') || s.contains('every 2') || s.contains('14') || s.contains('2 wks') || s.contains('2 weeks')) {
      return TaskFrequency.biWeekly;
    }
    if ((s.contains('twice') && s.contains('month')) || s.contains('2x/month') || s.contains('2x a month') || s.contains('2 times a month') || s.contains('15')) {
      return TaskFrequency.twiceMonthly;
    }
    if ((s.contains('2') || s.contains('twice')) && (s.contains('week') || s.contains('day')) && !s.contains('month')) {
      return TaskFrequency.twiceWeekly;
    }
    if (s.contains('daily') || s.contains('every day')) {
      return TaskFrequency.daily;
    }
    if (s.contains('month') || s.contains('30')) {
      return TaskFrequency.monthly;
    }
    if (s.contains('quarter') || s.contains('90')) {
      return TaskFrequency.quarterly;
    }
    return TaskFrequency.weekly;
  }
}

extension StringExtension on String {
  String strip() => trim();
}
