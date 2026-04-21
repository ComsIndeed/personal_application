// No dependencies here

enum SprintCategory { urgent, approaching, maintenance, fun }

class SprintTask {
  final String id;
  final String title;
  final String description;
  final Duration estimatedDuration;
  final SprintCategory category;
  final DateTime? dueDate;
  final String? platform; // For maintenance tasks
  final List<String> mediaUrls;
  bool isCompleted;
  DateTime? completedAt;

  SprintTask({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedDuration,
    required this.category,
    this.dueDate,
    this.platform,
    this.mediaUrls = const [],
    this.isCompleted = false,
    this.completedAt,
  });
}

class SprintFolder {
  final String name;
  final SprintCategory category;
  final String aiDescription;
  final List<SprintTask> tasks;

  SprintFolder({
    required this.name,
    required this.category,
    required this.aiDescription,
    required this.tasks,
  });

  int get taskCount => tasks.length;

  Duration get totalEstimatedDuration =>
      tasks.fold(Duration.zero, (prev, task) => prev + task.estimatedDuration);
}
