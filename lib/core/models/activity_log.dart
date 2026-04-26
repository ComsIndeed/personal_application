enum ActivityType { taskCompletion, taskUpdate, interruption }

class ActivityLog {
  final String id;
  final ActivityType activityType;
  final DateTime loggedAt;

  // Session link
  final String? sessionId;
  final int? elapsedSeconds;

  // taskCompletion + taskUpdate
  final String? taskId;

  // taskUpdate
  final String? updateContent;

  // interruption
  final DateTime? pausedAt;
  final DateTime? resumedAt;

  const ActivityLog({
    required this.id,
    required this.activityType,
    required this.loggedAt,
    this.sessionId,
    this.elapsedSeconds,
    this.taskId,
    this.updateContent,
    this.pausedAt,
    this.resumedAt,
  });
}
