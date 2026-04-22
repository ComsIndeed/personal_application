import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/constants/app_tab_id.dart';
import 'package:personal_application/core/widgets/app_tab.dart';
import 'package:personal_application/core/widgets/search_header_widget.dart';
import 'package:personal_application/core/widgets/brain_dump_item_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'notes_cubit.dart';
import 'notes_input.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppTabController<AppTabId>>().updateHeader(
        actions: [
          Expanded(
            child: SearchHeaderWidget(
              hintText: 'Search notes...',
              onTap: () {},
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
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Content Area
        Expanded(
          child: BlocBuilder<NotesCubit, NotesState>(
            buildWhen: (previous, current) =>
                previous.items != current.items ||
                previous.pendingItems != current.pendingItems ||
                previous.isLoading != current.isLoading,
            builder: (context, state) {
              if (state.isLoading) {
                return Skeletonizer(
                  enabled: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: 5,
                    itemBuilder: (context, index) => BrainDumpItemWidget(
                      item: CommonNoteItem(
                        id: 'skeleton-$index',
                        category: TabCategory.notes,
                        textContent:
                            'This is a long skeleton text content to simulate a real note item loading state with enough density.',
                        assetIds: const [],
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        deleted: false,
                      ),
                    ),
                  ),
                );
              }

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
                  final Widget child;
                  if (index < state.pendingItems.length) {
                    child = BrainDumpItemWidget(
                      item: state.pendingItems[index],
                      isPending: true,
                    );
                  } else {
                    child = BrainDumpItemWidget(
                      item: state.items[index - state.pendingItems.length],
                    );
                  }

                  return child
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 400.ms,
                        delay: (index * 50).ms,
                        curve: Curves.easeOutCubic,
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
