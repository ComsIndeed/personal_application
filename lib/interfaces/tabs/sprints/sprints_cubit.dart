import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/models/common_note_item.dart';
import '../../../core/services/sprints_service.dart';

class SprintsState extends Equatable {
  final List<CommonNoteItem> tasks;
  final bool isLoading;
  final String searchQuery;
  final String sortType; // 'pressure', 'resistance', 'default'

  // Session
  final String? activeSessionId;
  final DateTime? sessionStartedAt;

  // Timer
  final int timerSeconds;
  final bool isInterrupted;

  // Interruption tracking
  final String? activeInterruptionLogId;
  final DateTime? interruptionStartedAt;

  // Log of events in the current session (for the UI log view)
  final List<ActivityLog> sessionLogs;

  // Used to force UI rebuilds during interruptions
  final DateTime? lastTick;

  const SprintsState({
    this.tasks = const [],
    this.isLoading = true,
    this.searchQuery = '',
    this.sortType = 'default',
    this.activeSessionId,
    this.sessionStartedAt,
    this.timerSeconds = 0,
    this.isInterrupted = false,
    this.activeInterruptionLogId,
    this.interruptionStartedAt,
    this.sessionLogs = const [],
    this.lastTick,
  });

  bool get hasActiveSession => activeSessionId != null;

  SprintsState copyWith({
    List<CommonNoteItem>? tasks,
    bool? isLoading,
    String? searchQuery,
    String? sortType,
    String? activeSessionId,
    DateTime? sessionStartedAt,
    int? timerSeconds,
    bool? isInterrupted,
    String? activeInterruptionLogId,
    DateTime? interruptionStartedAt,
    List<ActivityLog>? sessionLogs,
    DateTime? lastTick,
    bool clearSession = false,
    bool clearInterruption = false,
  }) {
    return SprintsState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      activeSessionId: clearSession
          ? null
          : (activeSessionId ?? this.activeSessionId),
      sessionStartedAt: clearSession
          ? null
          : (sessionStartedAt ?? this.sessionStartedAt),
      timerSeconds: clearSession ? 0 : (timerSeconds ?? this.timerSeconds),
      isInterrupted: clearSession
          ? false
          : (isInterrupted ?? this.isInterrupted),
      activeInterruptionLogId: clearInterruption
          ? null
          : (activeInterruptionLogId ?? this.activeInterruptionLogId),
      interruptionStartedAt: clearInterruption
          ? null
          : (interruptionStartedAt ?? this.interruptionStartedAt),
      sessionLogs: clearSession ? const [] : (sessionLogs ?? this.sessionLogs),
      lastTick: lastTick ?? this.lastTick,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    isLoading,
    searchQuery,
    sortType,
    activeSessionId,
    sessionStartedAt,
    timerSeconds,
    isInterrupted,
    activeInterruptionLogId,
    interruptionStartedAt,
    sessionLogs,
    lastTick,
  ];

  // ─── Telemetry ──────────────────────────────────────────────────────────

  int get urgentCount {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return tasks.where((t) {
      if (t.completionStatus == true) return false;
      final isDueSoon =
          t.dueDate != null &&
          (t.dueDate!.isBefore(tomorrow) || t.dueDate!.day == tomorrow.day);
      return isDueSoon && (t.criticality ?? 0) >= 4;
    }).length;
  }

  int get quickCount {
    return tasks
        .where((t) => t.completionStatus != true && (t.resistance ?? 5) <= 2)
        .length;
  }

  int get waitingCount {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return tasks.where((t) {
      if (t.completionStatus == true) return false;
      final isUrgent =
          t.dueDate != null &&
          t.dueDate!.isBefore(tomorrow) &&
          (t.criticality ?? 0) >= 4;
      final isQuick = (t.resistance ?? 5) <= 2;
      return !isUrgent && !isQuick;
    }).length;
  }

  // ─── Filtered Tasks ──────────────────────────────────────────────────────

  List<CommonNoteItem> get filteredTasks {
    var list = tasks.where((t) => t.completionStatus != true).toList();

    // Search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((t) {
        final titleMatch = t.title?.toLowerCase().contains(query) ?? false;
        final contentMatch =
            t.textContent?.toLowerCase().contains(query) ?? false;
        return titleMatch || contentMatch;
      }).toList();
    }

    // Sort
    if (sortType == 'pressure') {
      list.sort((a, b) {
        // Deadlines first
        if (a.dueDate != null && b.dueDate == null) return -1;
        if (a.dueDate == null && b.dueDate != null) return 1;
        if (a.dueDate != null && b.dueDate != null) {
          final cmp = a.dueDate!.compareTo(b.dueDate!);
          if (cmp != 0) return cmp;
        }
        // Then criticality
        return (b.criticality ?? 0).compareTo(a.criticality ?? 0);
      });
    } else if (sortType == 'resistance') {
      list.sort((a, b) {
        final cmp = (a.resistance ?? 5).compareTo(b.resistance ?? 5);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }
}

class SprintsCubit extends Cubit<SprintsState> {
  final SprintsService _service = SprintsService();
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _logsSubscription;
  Timer? _ticker;

  SprintsCubit() : super(const SprintsState()) {
    _tasksSubscription = _service.watchTasks().listen((tasks) {
      emit(state.copyWith(tasks: tasks, isLoading: false));
    });
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void updateSort(String sortType) {
    emit(state.copyWith(sortType: sortType));
  }

  // ─── Sprint Lifecycle ────────────────────────────────────────────────────

  Future<void> startSprint(String folderKey) async {
    if (state.hasActiveSession) return; // already running

    final sessionId = await _service.createSession(folderKey);
    final now = DateTime.now();

    emit(
      state.copyWith(
        activeSessionId: sessionId,
        sessionStartedAt: now,
        timerSeconds: 0,
        isInterrupted: false,
      ),
    );

    _subscribeToLogs(sessionId);
    _startTicker();
  }

  Future<void> pauseSprint() async {
    if (!state.hasActiveSession || state.isInterrupted) return;

    _ticker?.cancel();

    final logId = await _service.startInterruption(
      sessionId: state.activeSessionId,
      elapsedSeconds: state.timerSeconds,
    );

    emit(
      state.copyWith(
        isInterrupted: true,
        activeInterruptionLogId: logId,
        interruptionStartedAt: DateTime.now(),
      ),
    );
  }

  Future<void> resumeSprint() async {
    if (!state.hasActiveSession || !state.isInterrupted) return;

    if (state.activeInterruptionLogId != null) {
      await _service.endInterruption(state.activeInterruptionLogId!);
    }

    emit(state.copyWith(isInterrupted: false, clearInterruption: true));
    _startTicker();
  }

  Future<void> stopSprint() async {
    _ticker?.cancel();
    _logsSubscription?.cancel();

    if (state.activeInterruptionLogId != null) {
      await _service.endInterruption(state.activeInterruptionLogId!);
    }

    if (state.activeSessionId != null) {
      await _service.endSession(state.activeSessionId!);
    }

    emit(state.copyWith(clearSession: true, clearInterruption: true));
  }

  // ─── Task Actions ─────────────────────────────────────────────────────────

  Future<void> completeTask(String taskId) async {
    await _service.setCompletionStatus(taskId, true);
    await _service.logTaskCompletion(
      taskId,
      sessionId: state.activeSessionId,
      elapsedSeconds: state.hasActiveSession ? state.timerSeconds : null,
    );
  }

  Future<void> logUpdate(String taskId, String content) async {
    await _service.logTaskUpdate(
      taskId,
      content,
      sessionId: state.activeSessionId,
      elapsedSeconds: state.hasActiveSession ? state.timerSeconds : null,
    );
  }

  // ─── Internals ────────────────────────────────────────────────────────────

  void _subscribeToLogs(String sessionId) {
    _logsSubscription?.cancel();
    _logsSubscription = _service.watchSessionLogs(sessionId).listen((logs) {
      emit(state.copyWith(sessionLogs: logs));
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.hasActiveSession) {
        if (!state.isInterrupted) {
          emit(
            state.copyWith(
              timerSeconds: state.timerSeconds + 1,
              lastTick: DateTime.now(),
            ),
          );
        } else {
          // Still emit to drive UI updates (like the pause timer)
          emit(state.copyWith(lastTick: DateTime.now()));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    _logsSubscription?.cancel();
    _ticker?.cancel();
    return super.close();
  }
}
