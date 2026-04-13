import 'package:flutter/material.dart';

class MainNavTabs extends StatelessWidget {
  const MainNavTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavButton(
                index: 0,
                icon: Icons.chat_bubble_rounded,
                label: 'AI',
                isSelected: tabController.index == 0,
                onTap: () => tabController.animateTo(0),
              ),
              const SizedBox(height: 8),
              _NavButton(
                index: 1,
                icon: Icons.check_circle_rounded,
                label: 'Tasks',
                isSelected: tabController.index == 1,
                onTap: () => tabController.animateTo(1),
              ),
              const SizedBox(height: 8),
              _NavButton(
                index: 2,
                icon: Icons.school_rounded,
                label: 'School',
                isSelected: tabController.index == 2,
                onTap: () => tabController.animateTo(2),
              ),
              const SizedBox(height: 8),
              _NavButton(
                index: 3,
                icon: Icons.person_rounded,
                label: 'User',
                isSelected: tabController.index == 3,
                onTap: () => tabController.animateTo(3),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? primaryColor : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}
