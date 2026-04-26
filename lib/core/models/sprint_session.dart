class SprintSession {
  final String id;
  final String folderKey;
  final DateTime startedAt;
  final DateTime? endedAt;

  const SprintSession({
    required this.id,
    required this.folderKey,
    required this.startedAt,
    this.endedAt,
  });
}
