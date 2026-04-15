import 'package:flutter/material.dart';
import 'brain_dump_input.dart';

class BrainDumpTab extends StatefulWidget {
  const BrainDumpTab({super.key});

  @override
  State<BrainDumpTab> createState() => _BrainDumpTabState();
}

class _BrainDumpTabState extends State<BrainDumpTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Content Area (Clean)
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 64,
                  color: isDark ? Color(0xFF1E293B) : Colors.black12,
                ),
                SizedBox(height: 16),
                Text(
                  'Ready for a brain dump?',
                  style: TextStyle(
                    color: isDark ? Color(0xFF334155) : Colors.black26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Input Interface
        const BrainDumpInput(),
      ],
    );
  }
}
