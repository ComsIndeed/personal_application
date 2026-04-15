import 'package:flutter/material.dart';

class BrainDumpInput extends StatelessWidget {
  const BrainDumpInput({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0B1120)
                    : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : Colors.black.withAlpha(10),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 22),
                      onPressed: () {},
                      tooltip: 'Add files',
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    Expanded(
                      child: TextField(
                        maxLines: 5,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Dump anything here...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Outlined Button
          _SideButton(
            icon: Icons.auto_awesome_outlined,
            isOutlined: true,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Filled Button
          _SideButton(
            icon: Icons.send_rounded,
            isOutlined: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _SideButton({
    required this.icon,
    required this.isOutlined,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isOutlined) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: theme.colorScheme.primary),
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        // No shadow to avoid "ghostly" overlay effects
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: theme.colorScheme.onPrimary),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}
