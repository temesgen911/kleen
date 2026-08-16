import '../models/cleaning_plan.dart';

/// Abstraction for date/time operations to enable 100% deterministic streak testing.
abstract class DateProvider {
  DateTime now();
  
  /// Returns the current local calendar date (time set to 00:00:00).
  DateTime today() {
    final current = now();
    return DateTime(current.year, current.month, current.day);
  }

  /// Returns the corresponding [WeekDay] for today.
  WeekDay currentWeekDay() {
    final weekdayInt = now().weekday; // 1 (Mon) .. 7 (Sun)
    return WeekDay.values[(weekdayInt - 1) % 7];
  }

  /// Checks if two dates represent the exact same calendar day.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if date [b] is the immediate calendar day after date [a].
  bool isConsecutiveDay(DateTime a, DateTime b) {
    final dayA = DateTime(a.year, a.month, a.day);
    final dayB = DateTime(b.year, b.month, b.day);
    return dayB.difference(dayA).inDays == 1;
  }
}

/// Default system date provider.
class SystemDateProvider extends DateProvider {
  @override
  DateTime now() => DateTime.now();
}

/// Injectable mock date provider for deterministic unit testing.
class MockDateProvider extends DateProvider {
  DateTime _currentDate;

  MockDateProvider(this._currentDate);

  @override
  DateTime now() => _currentDate;

  void setDate(DateTime date) {
    _currentDate = date;
  }

  void advanceDays(int days) {
    _currentDate = _currentDate.add(Duration(days: days));
  }
}
