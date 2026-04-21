import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/models/sprint_models.dart';
import 'package:personal_application/core/services/tab_header_manager.dart';
import 'package:personal_application/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SprintsTab extends StatefulWidget {
  const SprintsTab({super.key});

  @override
  State<SprintsTab> createState() => _SprintsTabState();
}

class _SprintsTabState extends State<SprintsTab>
    with AutomaticKeepAliveClientMixin {
  SprintFolder? _selectedFolder;
  bool _isWorking = false;
  DateTime? _workStartTime;
  Timer? _stopwatchTimer;
  Duration _elapsedTime = Duration.zero;
  bool _isInterrupted = false;
  Duration _interruptedTime = Duration.zero;
  final List<Map<String, dynamic>> _workLogs = [];

  final List<SprintFolder> _folders = [
    SprintFolder(
      name: 'Urgent',
      category: SprintCategory.urgent,
      aiDescription:
          'Critical infrastructure patch for the cloud storage sync. High priority as connection leaks are impacting 5% of active users. Rundown: Verify Supabase pool settings, implement periodic heartbeats, and re-enable failed request retry logic.',
      tasks: [
        SprintTask(
          id: 'u1',
          title: 'Fix critical database leak',
          description:
              'Investigate and patch the connection pool exhaustion issue.',
          estimatedDuration: const Duration(hours: 2),
          category: SprintCategory.urgent,
          dueDate: DateTime.now().add(const Duration(hours: 5)),
          mediaUrls: [
            'https://picsum.photos/seed/db1/200',
            'https://picsum.photos/seed/db2/200',
          ],
        ),
        SprintTask(
          id: 'u2',
          title: 'Deploy security patches',
          description: 'Update all dependencies to latest stable versions.',
          estimatedDuration: const Duration(hours: 2, minutes: 30),
          category: SprintCategory.urgent,
          dueDate: DateTime.now().add(const Duration(hours: 12)),
          mediaUrls: ['https://picsum.photos/seed/sec1/200'],
        ),
      ],
    ),
    SprintFolder(
      name: 'Approaching',
      category: SprintCategory.approaching,
      aiDescription:
          'The dashboard v2 release is due in 48h. Rundown: Finalize the responsive grid layout, sync charts with live analytics data, and polish the hover transitions on the navigation sidebar.',
      tasks: [
        SprintTask(
          id: 'a1',
          title: 'Finish UI Mockups',
          description: 'Complete the high-fidelity designs for the dashboard.',
          estimatedDuration: const Duration(hours: 3),
          category: SprintCategory.approaching,
          dueDate: DateTime.now().add(const Duration(days: 1, hours: 4)),
          mediaUrls: [
            'https://picsum.photos/seed/ui1/200',
            'https://picsum.photos/seed/ui2/200',
            'https://picsum.photos/seed/ui3/200',
          ],
        ),
        SprintTask(
          id: 'a2',
          title: 'API Integration',
          description:
              'Connect the frontend widgets to the new Supabase endpoints.',
          estimatedDuration: const Duration(hours: 5),
          category: SprintCategory.approaching,
          dueDate: DateTime.now().add(const Duration(days: 2)),
        ),
      ],
    ),
    SprintFolder(
      name: 'Maintenance',
      category: SprintCategory.maintenance,
      aiDescription:
          'Routine platform upkeep across Admin and Support. Rundown: Clearing the daily support queue, archiving legacy deployment logs, and verifying the weekly billing reconciliation for the team.',
      tasks: [
        SprintTask(
          id: 'm1',
          title: 'Reply to support emails',
          description: 'Clear the inbox of pending technical support queries.',
          estimatedDuration: const Duration(minutes: 45),
          category: SprintCategory.maintenance,
          platform: 'Email',
          mediaUrls: ['https://logo.clearbit.com/gmail.com'],
        ),
        SprintTask(
          id: 'm2',
          title: 'Archive old logs',
          description: 'Run scripts to move 2025 logs to cold storage.',
          estimatedDuration: const Duration(minutes: 20),
          category: SprintCategory.maintenance,
          platform: 'Server',
          mediaUrls: ['https://logo.clearbit.com/aws.amazon.com'],
        ),
        SprintTask(
          id: 'm3',
          title: 'Update billing info',
          description:
              'Refresh the AWS payment method for the new fiscal year.',
          estimatedDuration: const Duration(minutes: 15),
          category: SprintCategory.maintenance,
          platform: 'Admin',
          mediaUrls: ['https://logo.clearbit.com/stripe.com'],
        ),
        SprintTask(
          id: 'm4',
          title: 'Draft weekly newsletter',
          description: 'Prepare the content for Friday\'s release.',
          estimatedDuration: const Duration(hours: 1, minutes: 30),
          category: SprintCategory.maintenance,
          platform: 'Email',
          mediaUrls: ['https://logo.clearbit.com/mailchimp.com'],
        ),
      ],
    ),
    SprintFolder(
      name: 'Fun',
      category: SprintCategory.fun,
      aiDescription:
          'Creative exploration of the new animation engine. Rundown: Experimenting with fluid UI transitions, building a prototype for the voice-interaction layer, and sketching new themes.',
      tasks: [
        SprintTask(
          id: 'f1',
          title: 'Experiment with Canvas API',
          description: 'Create some generative art patterns.',
          estimatedDuration: const Duration(hours: 2),
          category: SprintCategory.fun,
          mediaUrls: [
            'https://picsum.photos/seed/art1/200',
            'https://picsum.photos/seed/art2/200',
          ],
        ),
        SprintTask(
          id: 'f2',
          title: 'Read "Atomic Habits"',
          description: 'Finish the last 3 chapters.',
          estimatedDuration: const Duration(hours: 1),
          mediaUrls: ['https://picsum.photos/seed/book1/200'],
          category: SprintCategory.fun,
        ),
      ],
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateHeader();
  }

  void _updateHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TabHeaderManager>().update(
        title: _selectedFolder != null ? _selectedFolder!.name : 'Sprints',
        leading: _selectedFolder != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedFolder = null;
                  });
                  _updateHeader();
                },
              )
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

  void _startWorking() {
    setState(() {
      _isWorking = true;
      _workStartTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _interruptedTime = Duration.zero;
      _isInterrupted = false;
      _workLogs.clear();
      _workLogs.add({
        'task': 'Session Started',
        'time': _workStartTime!,
        'duration': Duration.zero,
      });
    });

    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (!_isInterrupted) {
          _elapsedTime += const Duration(seconds: 1);
        } else {
          _interruptedTime += const Duration(seconds: 1);
        }
      });
    });
  }

  void _stopWorking() {
    _stopwatchTimer?.cancel();
    setState(() {
      _isWorking = false;
    });
  }

  void _toggleInterrupted() {
    setState(() {
      _isInterrupted = !_isInterrupted;
    });
  }

  void _logTaskDone(SprintTask task) {
    setState(() {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
      _workLogs.add({
        'task': task.title,
        'time': DateTime.now(),
        'duration': _elapsedTime,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isWorking
            ? _buildTimerView()
            : _selectedFolder == null
            ? _buildFolderGrid()
            : _buildFolderContents(),
      ),
    );
  }

  Widget _buildFolderGrid() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: _folders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return _SprintFolderTile(
          folder: folder,
          onTap: () {
            setState(() {
              _selectedFolder = folder;
            });
            _updateHeader();
          },
        );
      },
    );
  }

  Widget _buildFolderContents() {
    final folder = _selectedFolder!;

    return Column(
      children: [
        if (folder.category != SprintCategory.fun)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startWorking,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
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
          child: folder.category == SprintCategory.maintenance
              ? _buildMaintenanceList()
              : _buildNormalList(),
        ),
      ],
    );
  }

  Widget _buildNormalList() {
    final folder = _selectedFolder!;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: folder.tasks.length,
      itemBuilder: (context, index) {
        final task = folder.tasks[index];
        return _SprintTaskTile(
          task: task,
          isUrgent: folder.category == SprintCategory.urgent,
          isApproaching: folder.category == SprintCategory.approaching,
        );
      },
    );
  }

  Widget _buildMaintenanceList() {
    final folder = _selectedFolder!;
    // Group tasks by platform
    final grouped = <String, List<SprintTask>>{};
    for (var task in folder.tasks) {
      final p = task.platform ?? 'Other';
      grouped.putIfAbsent(p, () => []).add(task);
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
                    _getPlatformIcon(entry.key),
                    size: 16,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((task) => _SprintTaskTile(task: task)),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'server':
        return Icons.dns_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildTimerView() {
    final folder = _selectedFolder!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  _formatDuration(_elapsedTime),
                  style: GoogleFonts.ebGaramond(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: _isInterrupted ? Colors.white24 : Colors.white,
                  ),
                ),
                if (_isInterrupted)
                  Text(
                    'Interrupted: ${_formatDuration(_interruptedTime)}',
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TimerControlButton(
                      onPressed: _toggleInterrupted,
                      icon: _isInterrupted
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: _isInterrupted ? 'Resume' : 'Interrupt',
                      color: _isInterrupted
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 20),
                    _TimerControlButton(
                      onPressed: _stopWorking,
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
                  'ACTIVE SPRINT TASKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 16),
                ...folder.tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: task.isCompleted
                        ? const SizedBox.shrink()
                        : ListTile(
                            title: Text(
                              task.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(task.description),
                            trailing: ElevatedButton(
                              onPressed: () => _logTaskDone(task),
                              child: const Text('Done'),
                            ),
                            tileColor: Colors.white.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                  ),
                ),
                if (_workLogs.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'COMPLETED LOGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._workLogs.map(
                    (log) => ListTile(
                      dense: true,
                      title: Text(log['task'] as String),
                      subtitle: Text(
                        'Completed at ${DateFormat('HH:mm:ss').format(log['time'] as DateTime)}',
                      ),
                      trailing: Text(
                        _formatDuration(log['duration'] as Duration),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}

class _SprintFolderTile extends StatelessWidget {
  final SprintFolder folder;
  final VoidCallback onTap;

  const _SprintFolderTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(folder.category);

    // Collect all media URLs from tasks
    final mediaUrls = folder.tasks.expand((t) => t.mediaUrls).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(folder.category),
                        size: 20,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        folder.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${folder.taskCount} TASKS',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                folder.aiDescription,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    _formatDurationShort(folder.totalEstimatedDuration),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Media stack in bottom right
                  if (mediaUrls.isNotEmpty)
                    SizedBox(
                      height: 28,
                      width: 28 + (mediaUrls.length.clamp(0, 4) - 1) * 16.0,
                      child: Stack(
                        children: mediaUrls
                            .take(4)
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                              return Positioned(
                                left: e.key * 16.0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      e.value,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.white10,
                                                child: const Icon(
                                                  Icons.image_outlined,
                                                  size: 12,
                                                  color: Colors.white24,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  if (mediaUrls.isEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.image_outlined,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(SprintCategory category) {
    switch (category) {
      case SprintCategory.urgent:
        return Colors.redAccent;
      case SprintCategory.approaching:
        return Colors.orangeAccent;
      case SprintCategory.maintenance:
        return Colors.blueAccent;
      case SprintCategory.fun:
        return Colors.purpleAccent;
    }
  }

  IconData _getCategoryIcon(SprintCategory category) {
    switch (category) {
      case SprintCategory.urgent:
        return Icons.warning_amber_rounded;
      case SprintCategory.approaching:
        return Icons.access_time_rounded;
      case SprintCategory.maintenance:
        return Icons.build_rounded;
      case SprintCategory.fun:
        return Icons.palette_rounded;
    }
  }

  String _formatDurationShort(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _SprintTaskTile extends StatefulWidget {
  final SprintTask task;
  final bool isUrgent;
  final bool isApproaching;

  const _SprintTaskTile({
    required this.task,
    this.isUrgent = false,
    this.isApproaching = false,
  });

  @override
  State<_SprintTaskTile> createState() => _SprintTaskTileState();
}

class _SprintTaskTileState extends State<_SprintTaskTile> {
  Timer? _countdownTimer;
  late Duration _timeLeft;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.isUrgent && widget.task.dueDate != null) {
      _timeLeft = widget.task.dueDate!.difference(DateTime.now());
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _timeLeft = widget.task.dueDate!.difference(DateTime.now());
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isUrgent
              ? Colors.red.withValues(alpha: _isHovered ? 0.08 : 0.05)
              : Colors.white.withValues(alpha: _isHovered ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isUrgent
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ),
                    ),
                    if (widget.task.dueDate != null && !widget.isUrgent)
                      Text(
                        _getRemainingDaysText(widget.task.dueDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    const SizedBox(width: 80), // Space for hover buttons
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.description,
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
                if (widget.isUrgent && widget.task.dueDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_rounded,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCountdown(_timeLeft),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const Text(
                        ' REMAINING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (_isHovered)
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    _HoverAction(
                      icon: Icons.edit_rounded,
                      onTap: () {},
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 8),
                    _HoverAction(
                      icon: Icons.more_horiz_rounded,
                      onTap: () {},
                      tooltip: 'More',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRemainingDaysText(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays > 0) return '${diff.inDays} days left';
    return '${diff.inHours} hours left';
  }

  String _formatCountdown(Duration d) {
    bool negative = d.isNegative;
    d = d.abs();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "${negative ? '-' : ''}$hours:$minutes:$seconds";
  }
}

class _HoverAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HoverAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white70),
          ),
        ),
      ),
    );
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
            backgroundColor: color.withValues(alpha: 0.1),
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
