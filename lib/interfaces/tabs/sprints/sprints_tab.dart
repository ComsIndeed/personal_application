import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/common_note_item.dart';
import '../../../core/models/message/enums.dart';
import '../../../core/constants/app_tab_id.dart';
import '../../../core/widgets/app_tab.dart';
import 'package:personal_application/core/widgets/sprint_task_item_widget.dart';
import 'package:personal_application/interfaces/tabs/sprints/sprints_cubit.dart';
import 'package:personal_application/interfaces/tabs/sprints/widgets/sprint_timer_widget.dart';

class SprintsTab extends StatefulWidget {
  const SprintsTab({super.key});

  @override
  State<SprintsTab> createState() => _SprintsTabState();
}

class _SprintsTabState extends State<SprintsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  dynamic _selectedFolderKey;

  @override
  void initState() {
    super.initState();
    _updateHeader();
  }

  void _updateHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final title = _selectedFolderKey != null
          ? (_selectedFolderKey as String).toUpperCase()
          : 'Sprints';

      context.read<AppTabController<AppTabId>>().updateHeader(
        title: title,
        onBack: _selectedFolderKey != null
            ? () {
                setState(() {
                  _selectedFolderKey = null;
                });
                _updateHeader();
              }
            : null,
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

        // Map tasks to folders (UI categories)
        final folders = <String, List<CommonNoteItem>>{
          'urgent': state.tasks
              .where((t) => t.priority == TaskType.important && t.isUrgent)
              .toList(),
          'approaching': state.tasks
              .where((t) => t.priority == TaskType.important && !t.isUrgent)
              .toList(),
          'admin': state.tasks
              .where((t) => t.priority == TaskType.admin)
              .toList(),
          'fun': state.tasks.where((t) => t.priority == TaskType.fun).toList(),
          'uncategorized': state.tasks
              .where((t) => t.priority == TaskType.uncategorized)
              .toList(),
        };

        const folderKeys = [
          'urgent',
          'approaching',
          'admin',
          'fun',
          'uncategorized',
        ];

        return Container(
          color: Colors.transparent,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _selectedFolderKey == null
                ? _buildFolderGrid(context, folders, folderKeys, isDark)
                : _buildFolderContents(
                    context,
                    state,
                    _selectedFolderKey as String,
                    folders[_selectedFolderKey] ?? [],
                    isDark,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFolderGrid(
    BuildContext context,
    Map<String, List<CommonNoteItem>> folders,
    List<String> folderKeys,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      children: folderKeys.map((key) {
        final tasks = folders[key] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SprintFolderTile(
            folderKey: key,
            tasks: tasks,
            isDark: isDark,
            onTap: () {
              setState(() {
                _selectedFolderKey = key;
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
    String folderKey,
    List<CommonNoteItem> tasks,
    bool isDark,
  ) {
    return Column(
      children: [
        if (folderKey != 'fun')
          SprintTimerWidget(folderKey: folderKey, tasks: tasks, isDark: isDark),
        Expanded(
          child: folderKey == 'admin' || folderKey == 'uncategorized'
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
        return SprintTaskItemWidget(
          task: task,
          isDark: isDark,
          onStart: () => context.read<SprintsCubit>().startTask(task.id),
          onComplete: () => context.read<SprintsCubit>().completeTask(task.id),
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
              (task) => SprintTaskItemWidget(
                task: task,
                isDark: isDark,
                onStart: () => context.read<SprintsCubit>().startTask(task.id),
                onComplete: () =>
                    context.read<SprintsCubit>().completeTask(task.id),
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
}

class _SprintFolderTile extends StatelessWidget {
  const _SprintFolderTile({
    required this.folderKey,
    required this.tasks,
    required this.isDark,
    required this.onTap,
  });

  final String folderKey;
  final List<CommonNoteItem> tasks;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _getFolderColor(folderKey);
    final incompleteCount = tasks
        .where((t) => !(t.completionStatus ?? false))
        .length;
    final totalEstSeconds = tasks.fold<int>(
      0,
      (sum, t) => sum + (t.estTime ?? 0),
    );
    final isEmpty = tasks.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isEmpty
                ? color.withAlpha(isDark ? 12 : 8)
                : color.withAlpha(isDark ? 30 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEmpty ? color.withAlpha(25) : color.withAlpha(50),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getFolderIcon(folderKey),
                    size: 24,
                    color: isEmpty ? color.withAlpha(100) : color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folderKey.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: isEmpty ? color.withAlpha(100) : color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: isEmpty ? 0.3 : 1.0,
                    child: _buildMediaStack(
                      tasks.expand((t) => t.assetIds).toList(),
                      color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getFolderRundown(folderKey),
                style: TextStyle(
                  fontSize: 14,
                  color: isEmpty
                      ? color.withAlpha(80)
                      : (isDark ? Colors.white70 : Colors.black87),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Bottom row with strong timer and task info
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: isEmpty ? color.withAlpha(60) : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDurationShort(Duration(seconds: totalEstSeconds)),
                    style: TextStyle(
                      color: isEmpty ? color.withAlpha(60) : color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    height: 15,
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? color.withAlpha(40)
                          : color.withAlpha(60),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Text(
                    '$incompleteCount TASKS',
                    style: TextStyle(
                      color: isEmpty
                          ? color.withAlpha(60)
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
      height: 32,
      width: 32 + (count - 1) * 18.0,
      child: Stack(
        children: assetIds.take(3).toList().asMap().entries.map((e) {
          return Positioned(
            left: e.key * 18.0,
            child: Container(
              width: 32,
              height: 32,
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
}

Color _getFolderColor(String key) {
  switch (key) {
    case 'urgent':
      return Colors.redAccent;
    case 'approaching':
      return Colors.orangeAccent;
    case 'admin':
      return Colors.blueAccent;
    case 'fun':
      return Colors.purpleAccent;
    default:
      return Colors.grey;
  }
}

IconData _getFolderIcon(String key) {
  switch (key) {
    case 'urgent':
      return Icons.warning_amber_rounded;
    case 'approaching':
      return Icons.access_time_rounded;
    case 'admin':
      return Icons.build_rounded;
    case 'fun':
      return Icons.palette_rounded;
    default:
      return Icons.category_outlined;
  }
}

String _getFolderRundown(String key) {
  switch (key) {
    case 'urgent':
      return "Critical blockers. Real-time issues. High priority tasks requiring immediate attention.";
    case 'approaching':
      return "Upcoming deadlines. Next-action items. Items that need to stay on your radar.";
    case 'admin':
      return "Maintenance and operations. System upkeep. Email clearing. Logistics.";
    case 'fun':
      return "Exploration and play. Low pressure tasks. Creative experiments.";
    default:
      return "Tasks awaiting classification. Brain dump overflows.";
  }
}

String _formatDurationShort(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  return '${d.inMinutes}m';
}
