import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/common_note_item.dart';
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

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone A: Telemetry
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          _TelemetryCard(
                            label: 'Urgent',
                            count: state.urgentCount,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 16),
                          _TelemetryCard(
                            label: 'Quick',
                            count: state.quickCount,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 16),
                          _TelemetryCard(
                            label: 'Waiting',
                            count: state.waitingCount,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                    ),

                    // Zone B: Folders
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _GeneratorCard(
                              label: 'Deep Work',
                              icon: Icons.psychology_rounded,
                              onTap: () {
                                setState(
                                  () => _selectedFolderKey = 'deep_work',
                                );
                                _updateHeader();
                              },
                              color: Colors.purpleAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GeneratorCard(
                              label: 'Urgent',
                              icon: Icons.bolt_rounded,
                              onTap: () {
                                setState(() => _selectedFolderKey = 'triage');
                                _updateHeader();
                              },
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GeneratorCard(
                              label: 'Quick',
                              icon: Icons.flash_on_rounded,
                              onTap: () {
                                setState(() => _selectedFolderKey = 'momentum');
                                _updateHeader();
                              },
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ];
          },
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _selectedFolderKey != null
                ? _buildFolderContents(
                    context,
                    state,
                    _selectedFolderKey as String,
                    _getTasksForGenerator(
                      _selectedFolderKey as String,
                      state.filteredTasks,
                    ),
                    isDark,
                  )
                : _buildGlobalPool(context, state, isDark),
          ),
        );
      },
    );
  }

  List<CommonNoteItem> _getTasksForGenerator(
    String key,
    List<CommonNoteItem> all,
  ) {
    if (key == 'momentum') {
      final sorted = List<CommonNoteItem>.from(all)
        ..sort((a, b) => (a.resistance ?? 5).compareTo(b.resistance ?? 5));
      return sorted.take(3).toList();
    }
    if (key == 'triage') {
      final sorted = List<CommonNoteItem>.from(all)
        ..sort((a, b) {
          if (a.dueDate != null && b.dueDate == null) return -1;
          if (a.dueDate == null && b.dueDate != null) return 1;
          return (b.criticality ?? 0).compareTo(a.criticality ?? 0);
        });
      return sorted.take(5).toList();
    }
    if (key == 'deep_work') {
      return all
          .where((t) => (t.resistance ?? 0) >= 4 && (t.criticality ?? 0) >= 4)
          .toList();
    }
    return all;
  }

  Widget _buildGlobalPool(
    BuildContext context,
    SprintsState state,
    bool isDark,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) =>
                      context.read<SprintsCubit>().updateSearch(val),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search brain dump tasks...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                onTap: () {
                  // Show Sort Selector
                  _showSortOptions(context, state);
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildNormalList(context, state.filteredTasks, isDark)),
      ],
    );
  }

  void _showSortOptions(BuildContext context, SprintsState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SortOptionTile(
                label: 'Newest First',
                icon: Icons.new_releases_rounded,
                isSelected: state.sortType == 'default',
                onTap: () {
                  context.read<SprintsCubit>().updateSort('default');
                  Navigator.pop(context);
                },
              ),
              _SortOptionTile(
                label: 'High Pressure',
                icon: Icons.emergency_rounded,
                isSelected: state.sortType == 'pressure',
                onTap: () {
                  context.read<SprintsCubit>().updateSort('pressure');
                  Navigator.pop(context);
                },
              ),
              _SortOptionTile(
                label: 'Low Resistance',
                icon: Icons.flash_on_rounded,
                isSelected: state.sortType == 'resistance',
                onTap: () {
                  context.read<SprintsCubit>().updateSort('resistance');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
      cacheExtent: 1000,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return SprintTaskItemWidget(
          task: task,
          isDark: isDark,
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

    final flattenedItems = <dynamic>[];
    for (var entry in grouped.entries) {
      flattenedItems.add(entry.key); // Header string
      flattenedItems.addAll(entry.value); // Task items
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      cacheExtent: 1000,
      itemCount: flattenedItems.length,
      itemBuilder: (context, index) {
        final item = flattenedItems[index];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  _getGroupIconStatic(item),
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 8),
                Text(
                  item.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        } else {
          final task = item as CommonNoteItem;
          return SprintTaskItemWidget(
            task: task,
            isDark: isDark,
            onComplete: () =>
                context.read<SprintsCubit>().completeTask(task.id),
          );
        }
      },
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

class _TelemetryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TelemetryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toLowerCase(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

class _GeneratorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _GeneratorCard({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 30 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(50), width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.filter_list_rounded, size: 20),
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.redAccent
        : (Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black87);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              color: Colors.redAccent,
              size: 20,
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
