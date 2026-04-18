import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/services/tab_header_manager.dart';

class TodoTab extends StatefulWidget {
  const TodoTab({super.key});

  @override
  State<TodoTab> createState() => _TodoTabState();
}

class _TodoTabState extends State<TodoTab> {
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
                      'Search sprints...',
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
    return const Center(
      child: Text(
        'No active sprints.',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
