import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/services/tab_header_manager.dart';
import 'package:personal_application/core/widgets/search_header_widget.dart';
import 'package:personal_application/core/widgets/brain_dump_item_widget.dart';
import 'notes_cubit.dart';
import 'notes_input.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Content Area
        Expanded(
          child: BlocBuilder<NotesCubit, NotesState>(
            buildWhen: (previous, current) =>
                previous.items != current.items ||
                previous.pendingItems != current.pendingItems,
            builder: (context, state) {
              if (state.items.isEmpty && state.pendingItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: isDark ? Color(0xFF1E293B) : Colors.black12,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notes yet. Start writing?',
                        style: TextStyle(
                          color: isDark ? Color(0xFF334155) : Colors.black26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final allCount = state.pendingItems.length + state.items.length;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: allCount,
                itemBuilder: (context, index) {
                  if (index < state.pendingItems.length) {
                    return BrainDumpItemWidget(
                      item: state.pendingItems[index],
                      isPending: true,
                    );
                  }
                  return BrainDumpItemWidget(
                    item: state.items[index - state.pendingItems.length],
                  );
                },
              );
            },
          ),
        ),
        // Input Interface
        const NotesInput(),
      ],
    );
  }
}
