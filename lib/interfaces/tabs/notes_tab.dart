import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/services/tab_header_manager.dart';
import 'package:personal_application/core/widgets/search_header_widget.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TabHeaderManager>().update(
        actions: [
          SearchHeaderWidget(hintText: 'Search notes...', onTap: () {}),
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
      child: Text('No notes yet.', style: TextStyle(color: Color(0xFF94A3B8))),
    );
  }
}
