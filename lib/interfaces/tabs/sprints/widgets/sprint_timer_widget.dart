import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/activity_log.dart';
import '../../../../core/models/common_note_item.dart';
import '../sprints_cubit.dart';

class SprintTimerWidget extends StatefulWidget {
  final String folderKey;
  final List<CommonNoteItem> tasks;
  final bool isDark;

  const SprintTimerWidget({
    super.key,
    required this.folderKey,
    required this.tasks,
    required this.isDark,
  });

  @override
  State<SprintTimerWidget> createState() => _SprintTimerWidgetState();
}

class _SprintTimerWidgetState extends State<SprintTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _handleStateChange(SprintsState state) {
    final isActive = state.hasActiveSession;

    if (isActive && _expandController.status == AnimationStatus.dismissed) {
      _expandController.forward();
    } else if (!isActive &&
        _expandController.status == AnimationStatus.completed) {
      _expandController.reverse();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Color _getFolderColor() {
    switch (widget.folderKey) {
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

  @override
  Widget build(BuildContext context) {
    final baseColor = _getFolderColor();

    return BlocConsumer<SprintsCubit, SprintsState>(
      listener: (context, state) => _handleStateChange(state),
      builder: (context, state) {
        final isActive = state.hasActiveSession;
        final shape = RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(
            color: isActive
                ? (widget.isDark ? Colors.white12 : Colors.black12)
                : Colors.transparent,
            width: 1,
          ),
        );

        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final color = Color.lerp(
              baseColor,
              widget.isDark ? Colors.grey[900] : Colors.white,
              _expandAnimation.value,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: ShapeDecoration(color: color, shape: shape),
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: shape,
                    onTap: isActive
                        ? null
                        : () => context.read<SprintsCubit>().startSprint(
                            widget.folderKey,
                          ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopContent(context, state, isActive, baseColor),
                        if (_expandAnimation.value > 0)
                          SizeTransition(
                            sizeFactor: _expandAnimation,
                            child: _buildExpandedContent(
                              context,
                              state,
                              baseColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopContent(
    BuildContext context,
    SprintsState state,
    bool isActive,
    Color baseColor,
  ) {
    return Container(
      height: 64 + (16 * _expandAnimation.value),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isActive) ...[
            const Icon(Icons.play_arrow_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Start Working',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            _buildWheelTimer(state.timerSeconds),
            const Spacer(),
            _buildControls(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildWheelTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DigitWheel(value: minutes ~/ 10, isDark: widget.isDark),
        _DigitWheel(value: minutes % 10, isDark: widget.isDark),
        Text(
          ':',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: widget.isDark ? Colors.white : Colors.black,
          ),
        ),
        _DigitWheel(value: seconds ~/ 10, isDark: widget.isDark),
        _DigitWheel(value: seconds % 10, isDark: widget.isDark),
      ],
    );
  }

  Widget _buildControls(BuildContext context, SprintsState state) {
    final cubit = context.read<SprintsCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          onPressed: state.isInterrupted
              ? () => cubit.resumeSprint()
              : () => cubit.pauseSprint(),
          icon: state.isInterrupted
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          color: state.isInterrupted ? Colors.greenAccent : Colors.orangeAccent,
          isDark: widget.isDark,
        ),
        const SizedBox(width: 12),
        _CircleButton(
          onPressed: () => cubit.stopSprint(),
          icon: Icons.stop_rounded,
          color: Colors.redAccent,
          isDark: widget.isDark,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    SprintsState state,
    Color baseColor,
  ) {
    return Opacity(
      opacity: _expandAnimation.value,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildLogs(state), const SizedBox(height: 16)],
        ),
      ),
    );
  }

  Widget _buildLogs(SprintsState state) {
    final timeFmt = DateFormat('h:mm a');

    // Recompute pause duration from authoritative state timestamp
    Duration currentPauseDuration = Duration.zero;
    if (state.isInterrupted && state.interruptionStartedAt != null) {
      currentPauseDuration = DateTime.now().difference(
        state.interruptionStartedAt!,
      );
    }
    final pauseMins = currentPauseDuration.inMinutes;
    final pauseSecs = currentPauseDuration.inSeconds % 60;
    final pauseStr =
        '${pauseMins.toString().padLeft(2, '0')}:${pauseSecs.toString().padLeft(2, '0')}';

    // Build display items: real DB logs first, then live interruption on top if active
    final items = <_LogItem>[
      for (final log in state.sessionLogs)
        if (log.id != state.activeInterruptionLogId)
          _LogItem.fromActivityLog(log, timeFmt),
      if (state.isInterrupted)
        _LogItem(
          id: 'live_interruption',
          title: 'Interrupted',
          subtitle: pauseStr,
          isInterruption: true,
          isLiveInterruption: true,
        ),
    ];

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No activity yet',
          style: TextStyle(
            fontSize: 12,
            color: widget.isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        final isLive = item.isLiveInterruption;

        final dotColor = item.isInterruption
            ? (isLive
                  ? Colors.orangeAccent
                  : Colors.orangeAccent.withAlpha(150))
            : (widget.isDark ? Colors.white24 : Colors.black12);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                    child: item.isInterruption
                        ? Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: widget.isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isLive ? 15 : null,
                          color: item.isInterruption
                              ? Colors.orangeAccent
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isLive) ...[
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isLive ? FontWeight.bold : null,
                              color: item.isInterruption
                                  ? (isLive
                                        ? Colors.orangeAccent
                                        : Colors.orangeAccent.withAlpha(180))
                                  : (widget.isDark
                                        ? Colors.white38
                                        : Colors.black38),
                              fontFamily: item.isInterruption
                                  ? 'monospace'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Helper model for log display ───────────────────────────────────────────

class _LogItem {
  final String id;
  final String title;
  final String subtitle;
  final bool isInterruption;
  final bool isLiveInterruption;

  const _LogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.isInterruption = false,
    this.isLiveInterruption = false,
  });

  factory _LogItem.fromActivityLog(ActivityLog log, DateFormat fmt) {
    final time = fmt.format(log.loggedAt);
    switch (log.activityType) {
      case ActivityType.taskCompletion:
        return _LogItem(id: log.id, title: 'Task completed', subtitle: time);
      case ActivityType.taskUpdate:
        return _LogItem(
          id: log.id,
          title: log.updateContent ?? 'Note',
          subtitle: time,
        );
      case ActivityType.interruption:
        final resumed = log.resumedAt;
        final paused = log.pausedAt;
        String sub;
        if (resumed != null && paused != null) {
          final dur = resumed.difference(paused);
          final m = dur.inMinutes.toString().padLeft(2, '0');
          final s = (dur.inSeconds % 60).toString().padLeft(2, '0');
          sub = 'Paused for $m:$s';
        } else {
          sub = fmt.format(paused ?? log.loggedAt);
        }
        return _LogItem(
          id: log.id,
          title: 'Interrupted',
          subtitle: sub,
          isInterruption: true,
        );
    }
  }
}

class _DigitWheel extends StatelessWidget {
  final int value;
  final bool isDark;

  const _DigitWheel({required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.2, 0.8, 1.0],
        ).createShader(rect);
      },
      child: Container(
        width: 32,
        height: 50,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final inAnimation =
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: const Offset(0.0, 0.0),
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                );

            final outAnimation =
                Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: const Offset(0.0, 0.0),
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInBack),
                );

            return ClipRect(
              child: SlideTransition(
                position: child.key == ValueKey(value)
                    ? inAnimation
                    : outAnimation,
                child: child,
              ),
            );
          },
          child: Center(
            key: ValueKey(value),
            child: Text(
              '$value',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _CircleButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(isDark ? 30 : 20),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
