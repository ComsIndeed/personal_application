import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_tab_id.dart';
import '../../core/widgets/interface_container.dart';
import '../../core/widgets/app_tab.dart';
import '../../core/widgets/assistant_state.dart';
import '../../core/models/message/enums.dart';
import '../tabs/brain_dump/brain_dump_cubit.dart';
import '../tabs/sprints/sprints_cubit.dart';

class MainNavTabs extends StatelessWidget {
  const MainNavTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = context.watch<AppTabController<AppTabId>>();
    final theme = Theme.of(context);

    const double buttonSize = 44;
    const double spacing = 8;
    const double padding = 8;

    return GlassContainer(
      width: 60,
      borderRadius: BorderRadius.circular(30), // Circular ends
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ), // Replaced spacing with hardcoded 8
        child: ListenableBuilder(
          listenable: tabController,
          builder: (context, _) {
            final assistantState = context.watch<AssistantState>();
            final currentId = tabController.currentId;
            final isAssistantOpen = assistantState.openIds.contains(currentId);

            final brainDumpState = context.watch<BrainDumpCubit>().state;
            final sprintsState = context.watch<SprintsCubit>().state;

            final hasBrainDumpItems =
                brainDumpState.items.isNotEmpty ||
                brainDumpState.pendingItems.isNotEmpty;
            final hasUrgentSprints = sprintsState.tasks.any(
              (t) =>
                  t.priority == TaskType.important &&
                  (t.completionStatus != true),
            );

            int? buttonIndex;
            switch (currentId) {
              case AppTabId.brainDump:
                buttonIndex = 0;
                break;
              case AppTabId.notes:
                buttonIndex = 1;
                break;
              case AppTabId.sprints:
                buttonIndex = 2;
                break;
              default:
                buttonIndex = null;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    // Sliding Indicator Pill
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      top: buttonIndex == null
                          ? 0
                          : padding + (buttonIndex * (buttonSize + spacing)),
                      left: padding,
                      right: padding,
                      height: buttonIndex == null ? 0 : buttonSize,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: buttonIndex == null || isAssistantOpen ? 0 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Button Icons
                    Padding(
                      padding: const EdgeInsets.all(padding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NavButton(
                            index: 0,
                            icon: const Icon(Icons.lightbulb_rounded),
                            label: 'Brain Dump',
                            onTap: () => tabController.animateToIndex(0),
                            isPulsing: hasBrainDumpItems,
                            pulsingColor: const Color(0xFFFF4500), // Orange Red
                          ),
                          const SizedBox(height: spacing),
                          _NavButton(
                            index: 1,
                            icon: const Icon(Icons.notes_rounded),
                            label: 'Notes',
                            onTap: () => tabController.animateToIndex(1),
                          ),
                          const SizedBox(height: spacing),
                          _NavButton(
                            index: 2,
                            icon: const Icon(Icons.bolt_rounded),
                            label: 'Sprints',
                            onTap: () => tabController.animateToIndex(2),
                            isPulsing: hasUrgentSprints,
                            pulsingColor: Colors.yellowAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final int index;
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool isPulsing;
  final Color pulsingColor;

  const _NavButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPulsing = false,
    this.pulsingColor = Colors.orangeAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _PulsingGlow(
          isActive: isPulsing,
          color: pulsingColor,
          child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
        ),
      ),
    );
  }
}

class _PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool isActive;

  const _PulsingGlow({
    required this.child,
    required this.color,
    this.isActive = false,
  });

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = TweenSequence<double>([
      // First pulse
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 150,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 150,
      ),
      // Short gap
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 150),
      // Second pulse
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 150,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 150,
      ),
      // Long gap (matching the length of the pulse sequence)
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 500),
    ]).animate(_controller);

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_PulsingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final double value = _glowAnimation.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (value > 0.01)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6 * value),
                  blurRadius: 18 * value,
                  spreadRadius: 2 * value,
                ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
