import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/common_note_item.dart';
import '../../../core/services/sprints_service.dart';

class SprintsState extends Equatable {
  final List<CommonNoteItem> tasks;
  final bool isLoading;
  final String? activeTaskId;
  final int timerSeconds;
  final bool isInterrupted;

  const SprintsState({
    this.tasks = const [],
    this.isLoading = true,
    this.activeTaskId,
    this.timerSeconds = 0,
    this.isInterrupted = false,
  });

  SprintsState copyWith({
    List<CommonNoteItem>? tasks,
    bool? isLoading,
    String? activeTaskId,
    bool? isInterrupted,
    int? timerSeconds,
    bool clearActiveTaskId = false,
  }) {
    return SprintsState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      activeTaskId: clearActiveTaskId
          ? null
          : (activeTaskId ?? this.activeTaskId),
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isInterrupted: isInterrupted ?? this.isInterrupted,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    isLoading,
    activeTaskId,
    timerSeconds,
    isInterrupted,
  ];
}

class SprintsCubit extends Cubit<SprintsState> {
  final SprintsService _service = SprintsService();
  StreamSubscription? _subscription;
  Timer? _ticker;

  SprintsCubit() : super(const SprintsState()) {
    _subscription = _service.watchTasks().listen((tasks) {
      emit(state.copyWith(tasks: tasks, isLoading: false));
    });
  }

  void startTask(String taskId) {
    // If there's an existing active task, stop it first?
    // For now, let's just switch.
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    emit(
      state.copyWith(
        activeTaskId: taskId,
        timerSeconds: task.timerSeconds ?? 0,
        isInterrupted: false,
      ),
    );
    _startTicker();
  }

  void toggleInterrupt() {
    emit(state.copyWith(isInterrupted: !state.isInterrupted));
    // Ensure ticker is running if unpausing
    if (!state.isInterrupted) {
      _startTicker();
    }
  }

  void stopTask() {
    _ticker?.cancel();
    if (state.activeTaskId != null) {
      _service.updateTimer(state.activeTaskId!, state.timerSeconds);
    }
    emit(state.copyWith(clearActiveTaskId: true, isInterrupted: false));
  }

  void completeTask(String taskId) {
    if (state.activeTaskId == taskId) {
      stopTask();
    }
    _service.setCompletionStatus(taskId, true);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isInterrupted && state.activeTaskId != null) {
        final newSeconds = state.timerSeconds + 1;
        emit(state.copyWith(timerSeconds: newSeconds));

        // Persist every 10 seconds to avoid too much DB pressure
        if (newSeconds % 10 == 0) {
          _service.updateTimer(state.activeTaskId!, newSeconds);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _ticker?.cancel();
    return super.close();
  }
}
