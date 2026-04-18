import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/services/tab_header_manager.dart';
import 'brain_dump_input.dart';

class BrainDumpTab extends StatefulWidget {
  const BrainDumpTab({super.key});

  @override
  State<BrainDumpTab> createState() => _BrainDumpTabState();
}

class _BrainDumpTabState extends State<BrainDumpTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TabHeaderManager>().update(
        actions: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: Colors.white38),
                    SizedBox(width: 8),
                    Text(
                      'Search dump...',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 12),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              onPressed: () {},
              tooltip: 'Filter',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      );
    });
  }

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
