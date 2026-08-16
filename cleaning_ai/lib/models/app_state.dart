import 'package:flutter/foundation.dart';
import 'cleaning_plan.dart';
import 'cleaning_streak.dart';
import 'scanner_session.dart';
import '../services/date_provider.dart';
import '../services/notification_service.dart';
import '../services/streak_storage.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  factory AppState() => instance;
  AppState._internal() {
    _init();
  }

  CleaningPlan? _activePlan;
  ScannerSession? _activeSession;
  bool _isFirstArrivalAfterAccept = false;
  
  final Set<String> _completedTaskIds = {};
  final Set<String> _skippedTaskIds = {};

  DateProvider _dateProvider = SystemDateProvider();
  CleaningStreak _streak = CleaningStreak.initial();

  CleaningPlan? get activePlan => _activePlan;
  ScannerSession? get activeSession => _activeSession;
  bool get isFirstArrivalAfterAccept => _isFirstArrivalAfterAccept;
  Set<String> get completedTaskIds => _completedTaskIds;
  Set<String> get skippedTaskIds => _skippedTaskIds;
  DateProvider get dateProvider => _dateProvider;
  CleaningStreak get streak => _streak;

  void setDateProvider(DateProvider provider) {
    _dateProvider = provider;
    notifyListeners();
  }

  Future<void> _init() async {
    _streak = await StreakStorage.loadStreak();
    notifyListeners();
  }

  bool isTaskCompleted(String taskId) => _completedTaskIds.contains(taskId);
  bool isTaskSkipped(String taskId) => _skippedTaskIds.contains(taskId);

  void completeTask(String taskId) {
    _skippedTaskIds.remove(taskId);
    _completedTaskIds.add(taskId);
    _activePlan?.setTaskStatus(taskId, TaskStatus.completed);
    notifyListeners();
  }

  void skipTask(String taskId) {
    _completedTaskIds.remove(taskId);
    _skippedTaskIds.add(taskId);
    _activePlan?.setTaskStatus(taskId, TaskStatus.skipped);
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    if (_completedTaskIds.contains(taskId)) {
      _completedTaskIds.remove(taskId);
      _activePlan?.setTaskStatus(taskId, TaskStatus.pending);
    } else {
      _skippedTaskIds.remove(taskId);
      _completedTaskIds.add(taskId);
      _activePlan?.setTaskStatus(taskId, TaskStatus.completed);
    }
    notifyListeners();
  }

  /// Evaluates today's completed daily plan, updates streak, and persists.
  Future<CleaningStreak> completeDailyPlan() async {
    final today = _dateProvider.now();
    final wasInitial = _streak.currentStreak == 0 && _streak.totalCompletedDays == 0;
    
    final updatedStreak = _streak.registerCompletedDay(
      completionDate: today,
      plan: _activePlan,
      dateProvider: _dateProvider,
    );

    _streak = updatedStreak;
    await StreakStorage.saveStreak(_streak);

    if (wasInitial && updatedStreak.isFirstStreak) {
      NotificationService.instance.sendFirstStreakNotification();
    } else if (updatedStreak.currentStreak > 1) {
      NotificationService.instance.sendContinuingStreakNotification(updatedStreak.currentStreak);
    }

    notifyListeners();
    return _streak;
  }

  void setActivePlan(CleaningPlan plan, {ScannerSession? session}) {
    _activePlan = plan;
    if (session != null) {
      _activeSession = session;
    }
    _isFirstArrivalAfterAccept = true;
    _completedTaskIds.clear();
    _skippedTaskIds.clear();
    notifyListeners();
  }

  void consumeFirstArrival() {
    _isFirstArrivalAfterAccept = false;
  }

  void resetAll() {
    _activePlan = null;
    _activeSession = null;
    _isFirstArrivalAfterAccept = false;
    _completedTaskIds.clear();
    _skippedTaskIds.clear();
    _streak = CleaningStreak.initial();
    StreakStorage.clearStreak();
    notifyListeners();
  }
}
