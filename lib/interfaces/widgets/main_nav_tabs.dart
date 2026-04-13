import 'package:flutter/material.dart';

class MainNavTabs extends StatelessWidget {
  const MainNavTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    final theme = Theme.of(context);

    const double buttonSize = 44;
    const double spacing = 8;
    const double padding = 8;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListenableBuilder(
        listenable: tabController,
        builder: (context, _) {
          return Stack(
            children: [
              // Sliding Indicator Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                top: padding + (tabController.index * (buttonSize + spacing)),
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
                      icon: Icons.auto_awesome_rounded,
                      label: 'Assistant',
                      onTap: () => tabController.animateTo(0),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 1,
                      icon: Icons.bolt_rounded,
                      label: 'Sprints',
                      onTap: () => tabController.animateTo(1),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 2,
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      onTap: () => tabController.animateTo(2),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 3,
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      onTap: () => tabController.animateTo(3),
                    ),
                    const SizedBox(height: spacing),
                    _NavButton(
                      index: 4,
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () => tabController.animateTo(4),
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
  final IconData icon;
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
    final tabController = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final isSelected = tabController.index == index;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? theme.primaryColor : theme.iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}
