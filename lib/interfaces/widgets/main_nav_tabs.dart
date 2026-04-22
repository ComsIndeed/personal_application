import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_tab_id.dart';
import '../../core/widgets/app_tab.dart';

class MainNavTabs extends StatelessWidget {
  const MainNavTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = context.watch<AppTabController<AppTabId>>();
    final theme = Theme.of(context);

    const double buttonSize = 44;
    const double spacing = 8;
    const double padding = 8;

    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(vertical: spacing),
      child: ListenableBuilder(
        listenable: tabController,
        builder: (context, _) {
          return Stack(
            children: [
              // Sliding Indicator Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                top:
                    padding +
                    (tabController.currentIndex * (buttonSize + spacing)),
                left: padding,
                right: padding,
                height: buttonSize,
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
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 3,
                      icon: const Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                      onTap: () => tabController.animateToIndex(3),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 4,
                      icon: const Icon(Icons.build_circle_rounded),
                      label: 'Utilities',
                      onTap: () => tabController.animateToIndex(4),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 5,
                      icon: const Icon(Icons.settings_rounded),
                      label: 'Settings',
                      onTap: () => tabController.animateToIndex(5),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 6,
                      icon: const FaIcon(FontAwesomeIcons.diamond),
                      label: 'Assistant',
                      onTap: () => tabController.animateToIndex(6),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
