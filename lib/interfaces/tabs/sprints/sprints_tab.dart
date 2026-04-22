import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/common_note_item.dart';
import '../../../core/models/message/enums.dart';
import '../../../core/services/tab_header_manager.dart';
import 'sprints_cubit.dart';

class SprintsTab extends StatefulWidget {
  const SprintsTab({super.key});

  @override
  State<SprintsTab> createState() => _SprintsTabState();
}

class _SprintsTabState extends State<SprintsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TaskType? _selectedFolderType;

  @override
  void initState() {
    super.initState();
    _updateHeader();
  }

  void _updateHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final title = _selectedFolderType != null
          ? _selectedFolderType!.name.toUpperCase()
          : 'Sprints';

      context.read<TabHeaderManager>().update(
        title: title,
        onBack: _selectedFolderType != null
            ? () {
                setState(() {
                  _selectedFolderType = null;
                });
                _updateHeader();
              }
            : null,
        tabIndex: 2, // Sprints is index 2
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<SprintsCubit, SprintsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Map tasks to folders
        final folders = <TaskType, List<CommonNoteItem>>{};
        for (var type in TaskType.values) {
          folders[type] = state.tasks.where((t) => t.priority == type).toList();
        }

        return Container(
          color: theme.scaffoldBackgroundColor,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: state.activeTaskId != null
                ? _buildTimerView(context, state, isDark)
                : _selectedFolderType == null
                ? _buildFolderGrid(context, folders, isDark)
                : _buildFolderContents(
                    context,
                    state,
                    _selectedFolderType!,
                    folders[_selectedFolderType!] ?? [],
                    isDark,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFolderGrid(
    BuildContext context,
    Map<TaskType, List<CommonNoteItem>> folders,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      children: TaskType.values.map((type) {
        final tasks = folders[type] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SprintFolderTile(
            type: type,
            tasks: tasks,
            isDark: isDark,
            onTap: () {
              setState(() {
                _selectedFolderType = type;
              });
              _updateHeader();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFolderContents(
    BuildContext context,
    SprintsState state,
    TaskType type,
    List<CommonNoteItem> tasks,
    bool isDark,
  ) {
    return Column(
      children: [
        if (type != TaskType.fun && tasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Start the first incomplete task, or just start the working session logic
                  final firstIncomplete = tasks
                      .where((t) => !(t.completionStatus ?? false))
                      .firstOrNull;
                  if (firstIncomplete != null) {
                    context.read<SprintsCubit>().startTask(firstIncomplete.id);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(type),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(type).withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Start Working',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: type == TaskType.admin || type == TaskType.uncategorized
              ? _buildMaintenanceList(context, tasks, isDark)
              : _buildNormalList(context, tasks, isDark),
        ),
      ],
    );
  }

  Widget _buildNormalList(
    BuildContext context,
    List<CommonNoteItem> tasks,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _SprintTaskTile(
          task: task,
          isDark: isDark,
          onStart: () => context.read<SprintsCubit>().startTask(task.id),
        );
      },
    );
  }

  Widget _buildMaintenanceList(
    BuildContext context,
    List<CommonNoteItem> tasks,
    bool isDark,
  ) {
    final grouped = <String, List<CommonNoteItem>>{};
    for (var task in tasks) {
      final g = task.group ?? 'Other';
      grouped.putIfAbsent(g, () => []).add(task);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _getGroupIconStatic(entry.key),
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map(
              (task) => _SprintTaskTile(
                task: task,
                isDark: isDark,
                onStart: () => context.read<SprintsCubit>().startTask(task.id),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  IconData _getGroupIconStatic(String group) {
    switch (group.toLowerCase()) {
      case 'messenger':
        return Icons.messenger_outline_rounded;
      case 'email':
      case 'gmail':
        return Icons.email_outlined;
      case 'facebook':
        return Icons.facebook_outlined;
      case 'school':
        return Icons.book_outlined;
      case 'google docs':
        return Icons.description_outlined;
      case 'canva':
        return Icons.palette_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildTimerView(
    BuildContext context,
    SprintsState state,
    bool isDark,
  ) {
    final activeTask = state.tasks.firstWhere(
      (t) => t.id == state.activeTaskId,
    );
    final minutes = state.timerSeconds ~/ 60;
    final seconds = state.timerSeconds % 60;
    final timeStr =
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: state.isInterrupted
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                if (state.isInterrupted)
                  const Text(
                    'SESSION INTERRUPTED',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TimerControlButton(
                      onPressed: () =>
                          context.read<SprintsCubit>().toggleInterrupt(),
                      icon: state.isInterrupted
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: state.isInterrupted ? 'Resume' : 'Interrupt',
                      color: state.isInterrupted
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 20),
                    _TimerControlButton(
                      onPressed: () => context.read<SprintsCubit>().stopTask(),
                      icon: Icons.stop_rounded,
                      label: 'Finish Session',
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'ACTIVE SPRINT TASK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 16),
                _SprintTaskTile(
                  task: activeTask,
                  isDark: isDark,
                  onStart: () {}, // Already active
                  active: true,
                  onComplete: () =>
                      context.read<SprintsCubit>().completeTask(activeTask.id),
                ),
                // Other tasks in the same folder could be shown here if needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SprintFolderTile extends StatelessWidget {
  final TaskType type;
  final List<CommonNoteItem> tasks;
  final bool isDark;
  final VoidCallback onTap;

  const _SprintFolderTile({
    required this.type,
    required this.tasks,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(type);
    final incompleteCount = tasks
        .where((t) => !(t.completionStatus ?? false))
        .length;
    final totalEstSeconds = tasks.fold<int>(
      0,
      (sum, t) => sum + (t.estTime ?? 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 30 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(20), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_getCategoryIcon(type), size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        // Compact Timer Row below Title
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: color.withAlpha(150),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDurationShort(
                                Duration(seconds: totalEstSeconds),
                              ),
                              style: TextStyle(
                                color: color.withAlpha(150),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Task Count
                  Text(
                    '$incompleteCount tasks left',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withAlpha(40)
                          : Colors.black.withAlpha(40),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Media Stack
                  _buildMediaStack(
                    tasks.expand((t) => t.assetIds).toList(),
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // AI Description style rundown (mocking it for now or pulling from context)
              Text(
                _getMockRundown(type),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaStack(List<String> assetIds, Color color) {
    if (assetIds.isEmpty) return const SizedBox.shrink();
    final count = assetIds.length.clamp(0, 3);
    return SizedBox(
      height: 24,
      width: 24 + (count - 1) * 14.0,
      child: Stack(
        children: assetIds.take(3).toList().asMap().entries.map((e) {
          return Positioned(
            left: e.key * 14.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(100), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  "https://jzxfhtthknwegozofkvg.supabase.co/storage/v1/object/public/assets/${e.value}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white10,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 10,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getMockRundown(TaskType type) {
    switch (type) {
      case TaskType.urgent:
        return "Critical blockers. Real-time issues. High priority tasks requiring immediate attention.";
      case TaskType.approaching:
        return "Upcoming deadlines. Next-action items. Items that need to stay on your radar.";
      case TaskType.admin:
        return "Maintenance and operations. System upkeep. Email clearing. Logistics.";
      case TaskType.fun:
        return "Exploration and play. Low pressure tasks. Creative experiments.";
      case TaskType.uncategorized:
        return "Tasks awaiting classification. Brain dump overflows.";
    }
  }
}

class _SprintTaskTile extends StatelessWidget {
  final CommonNoteItem task;
  final bool isDark;
  final VoidCallback onStart;
  final bool active;
  final VoidCallback? onComplete;

  const _SprintTaskTile({
    required this.task,
    required this.isDark,
    required this.onStart,
    this.active = false,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.completionStatus ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active
            ? (isDark ? Colors.blue.withAlpha(30) : Colors.blue.withAlpha(10))
            : (isDark
                  ? Colors.white.withAlpha(10)
                  : Colors.black.withAlpha(10)),
        borderRadius: BorderRadius.circular(16),
        border: active ? Border.all(color: Colors.blue.withAlpha(50)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getGroupColorStatic(task.group),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getGroupIconStatic(task.group),
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title ?? task.textContent ?? "Untitled Task",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? (isDark ? Colors.white38 : Colors.black38)
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Text(
                  task.textContent ?? "No description",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted && !active)
            IconButton(
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                size: 28,
                color: Colors.blueAccent,
              ),
              onPressed: onStart,
            ),
          if (active)
            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
        ],
      ),
    );
  }

  Color _getGroupColorStatic(String? group) {
    if (group == null) return Colors.grey;
    switch (group.toLowerCase()) {
      case 'messenger':
        return const Color(0xFF00B2FF);
      case 'email':
      case 'gmail':
        return const Color(0xFFEA4335);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'school':
        return const Color(0xFF4CAF50);
      case 'google docs':
        return const Color(0xFF4285F4);
      case 'canva':
        return const Color(0xFF8B3DFF);
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getGroupIconStatic(String? group) {
    if (group == null) return Icons.blur_on_rounded;
    switch (group.toLowerCase()) {
      case 'messenger':
        return Icons.messenger_rounded;
      case 'email':
      case 'gmail':
        return Icons.email_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'school':
        return Icons.book_rounded;
      case 'google docs':
        return Icons.description_rounded;
      case 'canva':
        return Icons.palette_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _TimerControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _TimerControlButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 32, color: color),
          style: IconButton.styleFrom(
            backgroundColor: color.withAlpha(25),
            padding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

Color _getCategoryColor(TaskType type) {
  switch (type) {
    case TaskType.urgent:
      return Colors.redAccent;
    case TaskType.approaching:
      return Colors.orangeAccent;
    case TaskType.admin:
      return Colors.blueAccent;
    case TaskType.fun:
      return Colors.purpleAccent;
    case TaskType.uncategorized:
      return Colors.grey;
  }
}

IconData _getCategoryIcon(TaskType type) {
  switch (type) {
    case TaskType.urgent:
      return Icons.warning_amber_rounded;
    case TaskType.approaching:
      return Icons.access_time_rounded;
    case TaskType.admin:
      return Icons.build_rounded;
    case TaskType.fun:
      return Icons.palette_rounded;
    case TaskType.uncategorized:
      return Icons.category_outlined;
  }
}

String _formatDurationShort(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  return '${d.inMinutes}m';
}
