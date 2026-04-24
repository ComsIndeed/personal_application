import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_tab_id.dart';
import '../../core/widgets/interface_container.dart';
import '../../core/widgets/app_tab.dart';
import '../../core/widgets/assistant_state.dart';

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
                            icon: const Icon(Icons.psychology_rounded),
                            label: 'Brain Dump',
                            onTap: () => tabController.animateToIndex(0),
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

  const _NavButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
      ),
    );
  }
}
