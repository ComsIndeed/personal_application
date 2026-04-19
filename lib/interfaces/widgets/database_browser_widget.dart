import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/services/database_browser_cubit.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DatabaseBrowserWidget extends StatelessWidget {
  const DatabaseBrowserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseBrowserCubit, DatabaseBrowserState>(
      builder: (context, state) {
        final isVisible = state.isVisible;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        EdgeInsets effectivePadding = const EdgeInsets.all(16.0);
        if (!kIsWeb && Platform.isWindows) {
          if (MediaQuery.of(context).padding.bottom == 0) {
            effectivePadding = effectivePadding.copyWith(
              bottom: effectivePadding.bottom + 48,
            );
          }
        }

        return Positioned(
          left: 16,
          top: 16,
          bottom: effectivePadding.bottom,
          child: AnimatedSlide(
            offset: isVisible ? Offset.zero : const Offset(-1.1, 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.48,
                constraints: const BoxConstraints(minWidth: 550, maxWidth: 850),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 80 : 40),
                      blurRadius: 32,
                      offset: const Offset(8, 0),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    _DatabaseBrowserSidebar(state: state),
                    Expanded(
                      child: Column(
                        children: [
                          _DatabaseBrowserTitleBar(state: state),
                          const Divider(height: 1, color: Colors.white10),
                          Expanded(
                            child: _DatabaseBrowserContent(state: state),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatabaseBrowserSidebar extends StatelessWidget {
  final DatabaseBrowserState state;

  const _DatabaseBrowserSidebar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white.withAlpha(2),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildRootTabs(context),
          const Divider(
            height: 32,
            indent: 20,
            endIndent: 20,
            color: Colors.white10,
          ),
          Expanded(child: _buildTableList(context)),
        ],
      ),
    );
  }

  Widget _buildRootTabs(BuildContext context) {
    final cubit = context.read<DatabaseBrowserCubit>();
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.storage_rounded,
          label: 'Local Database',
          isSelected: state.rootTab == DatabaseRootTab.local,
          onTap: () => cubit.setRootTab(DatabaseRootTab.local),
        ),
        _SidebarItem(
          icon: Icons.cloud_queue_rounded,
          label: 'Cloud Database',
          isSelected: state.rootTab == DatabaseRootTab.cloud,
          onTap: () => cubit.setRootTab(DatabaseRootTab.cloud),
        ),
        _SidebarItem(
          icon: Icons.cloud_circle_rounded,
          label: 'Cloud Storage',
          isSelected: state.rootTab == DatabaseRootTab.storage,
          onTap: () => cubit.setRootTab(DatabaseRootTab.storage),
        ),
        _SidebarItem(
          icon: Icons.analytics_outlined,
          label: 'Analytics',
          isSelected: state.rootTab == DatabaseRootTab.analytics,
          onTap: () => cubit.setRootTab(DatabaseRootTab.analytics),
        ),
      ],
    );
  }

  Widget _buildTableList(BuildContext context) {
    if (state.rootTab == DatabaseRootTab.local) {
      final db = context.read<AppDatabase>();
      final tables = db.allTables.map((t) => t.actualTableName).toList();
      return ListView.builder(
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          return _TableListItem(
            name: table,
            isSelected: state.selectedTable == table,
            onTap: () =>
                context.read<DatabaseBrowserCubit>().setSelectedTable(table),
          );
        },
      );
    } else if (state.rootTab == DatabaseRootTab.cloud) {
      // Just hardcode the same tables for now as we know they are synced
      final tables = [
        'conversations',
        'messages',
        'asset_items',
        'common_note_items',
      ];
      return ListView.builder(
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          return _TableListItem(
            name: table,
            isSelected: state.selectedTable == table,
            onTap: () =>
                context.read<DatabaseBrowserCubit>().setSelectedTable(table),
          );
        },
      );
    }
    return const Center(
      child: Text(
        'Placeholder',
        style: TextStyle(color: Colors.white24, fontSize: 12),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white24,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.comfortable,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _TableListItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _TableListItem({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? Colors.white.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withAlpha(5),
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatabaseBrowserTitleBar extends StatelessWidget {
  final DatabaseBrowserState state;

  const _DatabaseBrowserTitleBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.selectedTable ?? 'Select a Table',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (state.selectedTable != null)
                  Text(
                    '${state.rootTab == DatabaseRootTab.local ? 'Local' : 'Cloud'} Database System',
                    style: const TextStyle(fontSize: 12, color: Colors.white24),
                  ),
              ],
            ),
          ),
          // Search Placeholder
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 14, color: Colors.white24),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Search rows...',
                      style: TextStyle(color: Colors.white10, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => context.read<DatabaseBrowserCubit>().hide(),
            style: IconButton.styleFrom(hoverColor: Colors.red.withAlpha(20)),
          ),
        ],
      ),
    );
  }
}

class _DatabaseBrowserContent extends StatelessWidget {
  final DatabaseBrowserState state;

  const _DatabaseBrowserContent({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.rootTab == DatabaseRootTab.storage ||
        state.rootTab == DatabaseRootTab.analytics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.rootTab == DatabaseRootTab.storage
                  ? Icons.cloud_circle_rounded
                  : Icons.analytics_outlined,
              size: 64,
              color: Colors.white10,
            ),
            const SizedBox(height: 16),
            Text(
              '${state.rootTab == DatabaseRootTab.storage ? 'Cloud Storage' : 'Analytics'} Coming Soon',
              style: const TextStyle(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    if (state.selectedTable == null) {
      return const Center(
        child: Text(
          'Select a table to view data',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    return _DatabaseTableView(state: state);
  }
}

class _DatabaseTableView extends StatefulWidget {
  final DatabaseBrowserState state;

  const _DatabaseTableView({required this.state});

  @override
  State<_DatabaseTableView> createState() => _DatabaseTableViewState();
}

class _DatabaseTableViewState extends State<_DatabaseTableView> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(_DatabaseTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedTable != widget.state.selectedTable ||
        oldWidget.state.rootTab != widget.state.rootTab ||
        oldWidget.state.sortColumn != widget.state.sortColumn ||
        oldWidget.state.isAscending != widget.state.isAscending) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.state.rootTab == DatabaseRootTab.local) {
        final db = context.read<AppDatabase>();
        final table = db.allTables.firstWhere(
          (t) => t.actualTableName == widget.state.selectedTable,
        );

        final query = db.select(table);
        final result = await query.get();
        final rawRows = result
            .map((r) => (r as dynamic).toJson() as Map<String, dynamic>)
            .toList();

        // Manual sorting
        if (widget.state.sortColumn != null) {
          final sortCol = widget.state.sortColumn!;
          rawRows.sort((a, b) {
            final valA = a[sortCol];
            final valB = b[sortCol];
            if (valA == null || valB == null) return 0;
            if (valA is Comparable && valB is Comparable) {
              return widget.state.isAscending
                  ? valA.compareTo(valB)
                  : valB.compareTo(valA);
            }
            return 0;
          });
        }

        setState(() {
          _rows = rawRows;
          _isLoading = false;
        });
      } else {
        // Cloud data from Supabase
        final response = await Supabase.instance.client
            .from(widget.state.selectedTable!)
            .select();

        final rawRows = List<Map<String, dynamic>>.from(response);

        // Manual sorting
        if (widget.state.sortColumn != null) {
          final sortCol = widget.state.sortColumn!;
          rawRows.sort((a, b) {
            final valA = a[sortCol];
            final valB = b[sortCol];
            if (valA == null || valB == null) return 0;
            if (valA is Comparable && valB is Comparable) {
              return widget.state.isAscending
                  ? valA.compareTo(valB)
                  : valB.compareTo(valA);
            }
            return 0;
          });
        }

        setState(() {
          _rows = rawRows;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show skeletonized table
      return Skeletonizer(
        enabled: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              columns: List.generate(
                4,
                (i) => DataColumn(
                  label: SizedBox(width: 100, child: Text('COLUMN $i')),
                ),
              ),
              rows: List.generate(
                12,
                (i) => DataRow(
                  cells: List.generate(
                    4,
                    (j) => const DataCell(
                      SizedBox(width: 100, child: Text('DATA')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No data found in this table',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    final columns = _rows.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          horizontalMargin: 20,
          columnSpacing: 30,
          headingRowColor: WidgetStateProperty.all(Colors.white.withAlpha(5)),
          columns: columns.map((col) {
            final isSorting = widget.state.sortColumn == col;
            return DataColumn(
              onSort: (_, _) =>
                  context.read<DatabaseBrowserCubit>().setSort(col),
              label: Container(
                height: 40,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      col.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: isSorting
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white38,
                      ),
                    ),
                    if (isSorting)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          widget.state.isAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          rows: _rows.map((row) {
            return DataRow(
              cells: columns.map((col) {
                final value = row[col];
                return DataCell(_buildCellValue(col, value));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCellValue(String column, dynamic value) {
    if (value == null) {
      return const Text(
        'NULL',
        style: TextStyle(
          color: Colors.white10,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Special case for foreign keys (naming convention: ends with _id)
    if (column.endsWith('_id') && value is String && value.length > 20) {
      // Look for table mapping
      String? targetTable;
      if (column == 'conversation_id') targetTable = 'conversations';

      if (targetTable != null) {
        return ElevatedButton.icon(
          onPressed: () {
            context.read<DatabaseBrowserCubit>().setSelectedTable(targetTable);
          },
          icon: const Icon(Icons.table_chart_rounded, size: 14),
          label: Text(
            value.toString().substring(0, 8),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(20),
            foregroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }

    String displayValue = value.toString();
    Color textColor = Colors.white70;

    // Format JSON
    if (value is Map || (value is String && value.startsWith('{'))) {
      textColor = Colors.greenAccent.withAlpha(200);
      if (value is String && value.length > 30) {
        displayValue = '{ ... }';
      }
    }

    // Format Dates
    if (column.toLowerCase().contains('time') ||
        column.toLowerCase().contains('date') ||
        column.toLowerCase().contains('at')) {
      try {
        DateTime? dt;
        if (value is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(value);
        } else if (value is String) {
          dt = DateTime.tryParse(value);
        }
        if (dt != null) {
          displayValue = DateFormat('MMM dd, yyyy HH:mm').format(dt.toLocal());
          textColor = Colors.blueAccent.withAlpha(220);
        }
      } catch (_) {}
    }

    return Tooltip(
      message: value.toString(),
      waitDuration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      textStyle: const TextStyle(
        fontSize: 12,
        color: Colors.white70,
        height: 1.4,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Text(
          displayValue,
          style: TextStyle(fontSize: 13, color: textColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
