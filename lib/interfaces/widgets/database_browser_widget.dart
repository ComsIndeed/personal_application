import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/services/database_browser_cubit.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:personal_application/core/services/storage_service.dart';
import 'package:personal_application/core/widgets/asset_preview_widget.dart';
import 'package:personal_application/core/models/asset_item.dart';

class DatabaseBrowserWidget extends StatelessWidget {
  const DatabaseBrowserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final globalVisible = context.watch<WindowOverlayState>().isVisible;

    return BlocBuilder<DatabaseBrowserCubit, DatabaseBrowserState>(
      builder: (context, state) {
        final isVisible = globalVisible && state.isVisible;
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
            offset: isVisible ? Offset.zero : const Offset(-1.2, 0),
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
                child: Column(
                  children: [
                    _DatabaseBrowserTitleBar(state: state),
                    const Divider(height: 1, color: Colors.white10),
                    if (state.rootTab == DatabaseRootTab.local ||
                        state.rootTab == DatabaseRootTab.cloud)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        layoutBuilder: (child, previousChildren) => Stack(
                          alignment: Alignment.topLeft,
                          children: [...previousChildren, ?child],
                        ),
                        child: _DatabaseTableTabSwitcher(
                          key: ValueKey('tables_${state.rootTab}'),
                          state: state,
                        ),
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        layoutBuilder: (child, previousChildren) => Stack(
                          alignment: Alignment.topLeft,
                          children: [...previousChildren, ?child],
                        ),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _DatabaseBrowserContent(
                          key: ValueKey(
                            'content_${state.rootTab}_${state.selectedTable}',
                          ),
                          state: state,
                        ),
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

class _DatabaseTableTabSwitcher extends StatelessWidget {
  final DatabaseBrowserState state;

  const _DatabaseTableTabSwitcher({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    List<String> tables = [];
    if (state.rootTab == DatabaseRootTab.local) {
      final db = context.read<AppDatabase>();
      tables = db.allTables.map((t) => t.actualTableName).toList();
    } else if (state.rootTab == DatabaseRootTab.cloud) {
      tables = [
        'conversations',
        'messages',
        'asset_items',
        'common_note_items',
      ];
    }

    if (tables.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white.withAlpha(2),
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tables.map((table) {
          final isSelected = state.selectedTable == table;
          return Material(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withAlpha(40)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () =>
                  context.read<DatabaseBrowserCubit>().setSelectedTable(table),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.table_rows_rounded,
                      size: 14,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white38,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      table,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DatabaseBrowserTitleBar extends StatelessWidget {
  final DatabaseBrowserState state;

  const _DatabaseBrowserTitleBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseBrowserCubit>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (state.maintenanceResults != null) ...[
            IconButton(
              onPressed: () => cubit.clearResults(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              tooltip: 'Back to Browser',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                backgroundColor: Colors.blueAccent.withAlpha(20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Root Tab Buttons
          Row(
            children: [
              _RootTabIcon(
                icon: Icons.storage_rounded,
                tooltip: 'Local DB',
                isSelected: state.rootTab == DatabaseRootTab.local,
                onTap: () => cubit.setRootTab(DatabaseRootTab.local),
              ),
              const SizedBox(width: 8),
              _RootTabIcon(
                icon: Icons.cloud_queue_rounded,
                tooltip: 'Cloud DB',
                isSelected: state.rootTab == DatabaseRootTab.cloud,
                onTap: () => cubit.setRootTab(DatabaseRootTab.cloud),
              ),
              const SizedBox(width: 8),
              _RootTabIcon(
                icon: Icons.cloud_circle_rounded,
                tooltip: 'Storage',
                isSelected: state.rootTab == DatabaseRootTab.storage,
                onTap: () => cubit.setRootTab(DatabaseRootTab.storage),
              ),
              const SizedBox(width: 8),
              _RootTabIcon(
                icon: Icons.analytics_outlined,
                tooltip: 'Analytics',
                isSelected: state.rootTab == DatabaseRootTab.analytics,
                onTap: () => cubit.setRootTab(DatabaseRootTab.analytics),
              ),
            ],
          ),
          const SizedBox(width: 24),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              children: [
                Text(
                  state.selectedTable ??
                      (state.rootTab == DatabaseRootTab.local
                          ? 'Local'
                          : 'Cloud'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (state.maintenanceResults != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RESULTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
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
          // Hamburger Context Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.menu_rounded,
              size: 20,
              color: Colors.white70,
            ),
            tooltip: 'Maintenance',
            offset: const Offset(0, 40),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10),
            ),
            onSelected: (value) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Confirm Wipe',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  content: Text(
                    value.contains('assets')
                        ? 'This will delete asset records and files. Are you sure?'
                        : 'This will delete database entries (conversations, messages, etc). Are you sure?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white24),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Proceed'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              final storage = StorageService();
              final db = context.read<AppDatabase>();

              if (value == 'wipe_db_both') {
                await cubit.wipeDatabase(db: db, local: true, cloud: true);
              } else if (value == 'wipe_db_local') {
                await cubit.wipeDatabase(db: db, local: true, cloud: false);
              } else if (value == 'wipe_db_cloud') {
                await cubit.wipeDatabase(db: db, local: false, cloud: true);
              } else if (value == 'wipe_assets_both') {
                await cubit.wipeAssets(storage: storage, db: db, both: true);
              } else if (value == 'wipe_assets_local') {
                await cubit.wipeAssets(storage: storage, db: db, both: false);
              }
            },
            itemBuilder: (context) => [
              // --- Database Wipe ---
              PopupMenuItem(
                value: 'wipe_db_both',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      size: 18,
                      color: Colors.redAccent.withAlpha(200),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Wipe Database (No Assets)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                enabled: false,
                height: 24,
                child: Text(
                  'DATABASE OPTIONS',
                  style: TextStyle(
                    color: Colors.white.withAlpha(40),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'wipe_db_local',
                child: Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Text(
                    'Only Local',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'wipe_db_cloud',
                child: Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Text(
                    'Only Cloud',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              // --- Assets Wipe ---
              PopupMenuItem(
                value: 'wipe_assets_both',
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high_rounded,
                      size: 18,
                      color: Colors.blueAccent.withAlpha(200),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Wipe Assets (Full)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                enabled: false,
                height: 24,
                child: Text(
                  'ASSET OPTIONS',
                  style: TextStyle(
                    color: Colors.white.withAlpha(40),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'wipe_assets_local',
                child: Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Text(
                    'Only Local Cache',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => context.read<DatabaseBrowserCubit>().hide(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(40),
              hoverColor: Colors.redAccent.withAlpha(80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseBrowserContent extends StatelessWidget {
  final DatabaseBrowserState state;

  const _DatabaseBrowserContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isWiping) {
      return _DatabaseWipingProgress(state: state);
    }

    if (state.maintenanceResults != null) {
      return _DatabaseMaintenanceResults(state: state);
    }

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
        final rawRows = result.map((r) {
          final map = (r as dynamic).toJson() as Map<String, dynamic>;
          if (r is AssetItem) {
            map['_raw_item'] = r;
          }
          return map;
        }).toList();

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

    final isAssetTable = widget.state.selectedTable == 'asset_items';

    if (isAssetTable) {
      return _buildAssetItemsTable();
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

  Widget _buildAssetItemsTable() {
    return Column(
      children: [
        // Header Row
        Container(
          height: 40,
          color: Colors.white.withAlpha(5),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text(
                  'PREVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  'FILE NAME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(
                width: 80,
                child: Text(
                  'CACHE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(
                width: 80,
                child: Text(
                  'CLOUD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Data Rows
        ..._rows.map((row) {
          final asset =
              row['_raw_item'] as AssetItem? ?? AssetItem.fromJson(row);

          return Column(
            children: [
              _AssetRowWidget(asset: asset),
              const Divider(height: 1, color: Colors.white10),
            ],
          );
        }),
      ],
    );
  }
}

class _AssetRowWidget extends StatefulWidget {
  final AssetItem asset;
  const _AssetRowWidget({required this.asset});

  @override
  State<_AssetRowWidget> createState() => _AssetRowWidgetState();
}

class _AssetRowWidgetState extends State<_AssetRowWidget> {
  bool? _isActuallyOnCloud;
  bool _isChecking = false;

  Future<void> _checkCloud() async {
    if (widget.asset.b2FileName == null) {
      setState(() => _isActuallyOnCloud = false);
      return;
    }

    setState(() => _isChecking = true);
    try {
      // Mocking check for now as StorageService internals are private
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isActuallyOnCloud = widget.asset.isUploaded;
        _isChecking = false;
      });
    } catch (_) {
      setState(() {
        _isActuallyOnCloud = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCache = widget.asset.cachedBytes != null;
    final isUploaded = _isActuallyOnCloud ?? widget.asset.isUploaded;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 1. Preview
          SizedBox(
            width: 60,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasCache
                  ? AssetPreviewWidget(
                      assetId: widget.asset.id,
                      fit: BoxFit.cover,
                    )
                  : Material(
                      color: Colors.white.withAlpha(5),
                      child: InkWell(
                        onTap: () {
                          // Trigger Download
                          StorageService().getBytes(widget.asset);
                        },
                        child: const Center(
                          child: Icon(
                            Icons.download_for_offline_rounded,
                            size: 20,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          // 2. File Name
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.asset.displayName ?? widget.asset.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.asset.mimeType,
                  style: const TextStyle(fontSize: 10, color: Colors.white24),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // 3. Cache
          SizedBox(
            width: 80,
            child: Center(
              child: Icon(
                hasCache
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: hasCache ? Colors.greenAccent : Colors.white10,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 4. Cloud
          SizedBox(
            width: 80,
            child: Center(
              child: _isChecking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    )
                  : InkWell(
                      onTap: _checkCloud,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUploaded
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              size: 16,
                              color: isUploaded
                                  ? Colors.blueAccent
                                  : Colors.orangeAccent.withAlpha(100),
                            ),
                            if (_isActuallyOnCloud == null) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.refresh_rounded,
                                size: 12,
                                color: Colors.white10,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RootTabIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _RootTabIcon({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withAlpha(40)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }
}

class _DatabaseWipingProgress extends StatelessWidget {
  final DatabaseBrowserState state;
  const _DatabaseWipingProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state.wipeProgressMessage ?? 'Executing maintenance...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please do not close the application',
            style: TextStyle(fontSize: 12, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

class _DatabaseMaintenanceResults extends StatelessWidget {
  final DatabaseBrowserState state;
  const _DatabaseMaintenanceResults({required this.state});

  @override
  Widget build(BuildContext context) {
    final results = state.maintenanceResults!;
    final type = results['type'] as String;
    final data = results['data'];

    return Column(
      children: [
        Expanded(
          child: type == 'assets'
              ? _AssetMaintenanceTable(
                  data: List<Map<String, dynamic>>.from(data),
                )
              : _DatabaseMaintenanceTable(
                  data: Map<String, List<Map<String, dynamic>>>.from(data),
                ),
        ),
      ],
    );
  }
}

class _AssetMaintenanceTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _AssetMaintenanceTable({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No assets were affected',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FixedColumnWidth(80),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(100),
        },
        border: TableBorder.all(
          color: Colors.white10,
          width: 1,
          borderRadius: BorderRadius.circular(8),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.white.withAlpha(5)),
            children: ['ASSET', 'RECORD', 'CACHE', 'CLOUD']
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white38,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...data.map((item) {
            final allDeleted =
                item['recordDeleted'] == true &&
                item['cloudFileDeleted'] == true;
            final cacheCleared = item['cacheCleared'] == true;

            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    item['displayName'],
                    style: TextStyle(
                      fontSize: 12,
                      color: allDeleted ? Colors.redAccent : Colors.white70,
                    ),
                  ),
                ),
                _ResultIcon(isDeleted: item['recordDeleted']),
                _ResultIcon(isDeleted: cacheCleared, label: 'CLEARED'),
                _ResultIcon(isDeleted: item['cloudFileDeleted']),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DatabaseMaintenanceTable extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> data;
  const _DatabaseMaintenanceTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final tables = data.keys.toList();
    if (tables.isEmpty) {
      return const Center(
        child: Text(
          'No data was affected',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final tableName = tables[index];
        final rows = data[tableName]!;
        if (rows.isEmpty) return const SizedBox.shrink();

        return ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Row(
            children: [
              Text(
                tableName.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${rows.length} DELETED',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 24,
                  dataRowMaxHeight: 32,
                  columns: rows.first.keys
                      .map(
                        (k) => DataColumn(
                          label: Text(
                            k,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  rows: rows
                      .map(
                        (r) => DataRow(
                          cells: r.values
                              .map(
                                (v) => DataCell(
                                  Text(
                                    v.toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultIcon extends StatelessWidget {
  final bool isDeleted;
  final String label;
  const _ResultIcon({required this.isDeleted, this.label = 'DELETED'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: isDeleted
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              )
            : const Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: Colors.white10,
              ),
      ),
    );
  }
}
