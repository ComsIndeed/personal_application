import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/models/common_note_item.dart';
import '../../../core/services/sprints_service.dart';

class SprintsState extends Equatable {
  final List<CommonNoteItem> tasks;
  final bool isLoading;

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

  const SprintsState({
    this.tasks = const [],
    this.isLoading = true,
    this.activeSessionId,
    this.sessionStartedAt,
    this.timerSeconds = 0,
    this.isInterrupted = false,
    this.activeInterruptionLogId,
    this.interruptionStartedAt,
    this.sessionLogs = const [],
  });

  bool get hasActiveSession => activeSessionId != null;

  SprintsState copyWith({
    List<CommonNoteItem>? tasks,
    bool? isLoading,
    String? activeSessionId,
    DateTime? sessionStartedAt,
    int? timerSeconds,
    bool? isInterrupted,
    String? activeInterruptionLogId,
    DateTime? interruptionStartedAt,
    List<ActivityLog>? sessionLogs,
    bool clearSession = false,
    bool clearInterruption = false,
  }) {
    return SprintsState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
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
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    isLoading,
    activeSessionId,
    sessionStartedAt,
    timerSeconds,
    isInterrupted,
    activeInterruptionLogId,
    interruptionStartedAt,
    sessionLogs,
  ];
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
      if (!state.isInterrupted && state.hasActiveSession) {
        emit(state.copyWith(timerSeconds: state.timerSeconds + 1));
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
