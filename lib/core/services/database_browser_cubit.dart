import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncable/syncable.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/services/storage_service.dart';

enum DatabaseRootTab { local, cloud, storage, analytics }

class DatabaseBrowserState extends Equatable {
  final bool isVisible;
  final DatabaseRootTab rootTab;
  final String? selectedTable;
  final String searchQuery;
  final String? sortColumn;
  final bool isAscending;
  final bool isWiping;
  final String? wipeProgressMessage;
  final Map<String, dynamic>? maintenanceResults;

  const DatabaseBrowserState({
    this.isVisible = false,
    this.rootTab = DatabaseRootTab.local,
    this.selectedTable,
    this.searchQuery = '',
    this.sortColumn,
    this.isAscending = true,
    this.isWiping = false,
    this.wipeProgressMessage,
    this.maintenanceResults,
  });

  DatabaseBrowserState copyWith({
    bool? isVisible,
    DatabaseRootTab? rootTab,
    String? selectedTable,
    bool clearTable = false,
    String? searchQuery,
    String? sortColumn,
    bool? isAscending,
    bool clearSort = false,
    bool? isWiping,
    String? wipeProgressMessage,
    Map<String, dynamic>? maintenanceResults,
    bool clearResults = false,
  }) {
    return DatabaseBrowserState(
      isVisible: isVisible ?? this.isVisible,
      rootTab: rootTab ?? this.rootTab,
      selectedTable: clearTable ? null : (selectedTable ?? this.selectedTable),
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumn: clearSort ? null : (sortColumn ?? this.sortColumn),
      isAscending: isAscending ?? this.isAscending,
      isWiping: isWiping ?? this.isWiping,
      wipeProgressMessage: wipeProgressMessage ?? this.wipeProgressMessage,
      maintenanceResults: clearResults
          ? null
          : (maintenanceResults ?? this.maintenanceResults),
    );
  }

  @override
  List<Object?> get props => [
    isVisible,
    rootTab,
    selectedTable,
    searchQuery,
    sortColumn,
    isAscending,
    isWiping,
    wipeProgressMessage,
    maintenanceResults,
  ];
}

class DatabaseBrowserCubit extends Cubit<DatabaseBrowserState> {
  DatabaseBrowserCubit() : super(const DatabaseBrowserState());

  void show() => emit(state.copyWith(isVisible: true));
  void hide() => emit(state.copyWith(isVisible: false));
  void toggle() => emit(state.copyWith(isVisible: !state.isVisible));

  void setRootTab(DatabaseRootTab tab) {
    emit(state.copyWith(rootTab: tab, clearTable: true, clearSort: true));
  }

  void setSelectedTable(String? table) {
    emit(state.copyWith(selectedTable: table, clearSort: true));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setSort(String column) {
    if (state.sortColumn == column) {
      emit(state.copyWith(isAscending: !state.isAscending));
    } else {
      emit(state.copyWith(sortColumn: column, isAscending: true));
    }
  }

  void clear() {
    emit(const DatabaseBrowserState());
  }

  void clearResults() {
    emit(state.copyWith(clearResults: true));
  }

  Future<void> wipeDatabase({
    required SyncableDatabase db,
    bool local = true,
    bool cloud = true,
  }) async {
    emit(
      state.copyWith(
        isWiping: true,
        wipeProgressMessage: 'Preparing database wipe...',
        clearResults: true,
      ),
    );

    final Map<String, List<Map<String, dynamic>>> results = {};
    const tables = ['conversations', 'messages', 'common_note_items'];

    try {
      if (local && db is AppDatabase) {
        emit(state.copyWith(wipeProgressMessage: 'Fetching local rows...'));
        for (final tableName in tables) {
          final table = db.allTables.firstWhere(
            (t) => t.actualTableName == tableName,
          );
          final rows = await (db.select(table)).get();
          results['local_$tableName'] = rows
              .map((r) => (r as dynamic).toJson() as Map<String, dynamic>)
              .toList();
        }

        emit(state.copyWith(wipeProgressMessage: 'Deleting local rows...'));
        await db.wipeLocalData(exclude: const ['asset_items']);
      }

      if (cloud) {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;

        for (final tableName in tables) {
          emit(
            state.copyWith(
              wipeProgressMessage: 'Fetching cloud rows from $tableName...',
            ),
          );
          dynamic query = client.from(tableName).select();
          if (userId != null) query = query.eq('user_id', userId);
          final response = await query;
          results['cloud_$tableName'] = List<Map<String, dynamic>>.from(
            response,
          );

          emit(
            state.copyWith(
              wipeProgressMessage: 'Deleting cloud rows from $tableName...',
            ),
          );
          if (userId != null) {
            await client.from(tableName).delete().eq('user_id', userId);
          } else {
            await client
                .from(tableName)
                .delete()
                .neq('id', '00000000-0000-0000-0000-000000000000');
          }
        }
      }

      emit(
        state.copyWith(
          isWiping: false,
          wipeProgressMessage: 'Wipe complete',
          maintenanceResults: {
            'type': 'database',
            'data': results,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isWiping: false,
          wipeProgressMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> wipeAssets({
    required StorageService storage,
    required SyncableDatabase db,
    bool both = true,
  }) async {
    emit(
      state.copyWith(
        isWiping: true,
        wipeProgressMessage: 'Preparing asset wipe...',
        clearResults: true,
      ),
    );

    try {
      final List<Map<String, dynamic>> assetResults = [];

      // Fetch current assets to track what was there
      if (db is AppDatabase) {
        final currentAssets = await db.select(db.assetItems).get();
        for (var asset in currentAssets) {
          assetResults.add({
            'id': asset.id,
            'displayName': asset.displayName ?? asset.id.substring(0, 8),
            'mimeType': asset.mimeType,
            'recordDeleted': both,
            'cacheCleared': true, // either cleared or record deleted
            'cloudFileDeleted': both && asset.isUploaded,
          });
        }
      }

      if (both) {
        emit(
          state.copyWith(
            wipeProgressMessage: 'Deleting cloud files from B2...',
          ),
        );
        await storage.wipeCloudStorage();

        emit(state.copyWith(wipeProgressMessage: 'Deleting asset records...'));
        if (db is AppDatabase) {
          await (db.delete(db.assetItems)).go();
        }

        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          await client.from('asset_items').delete().eq('user_id', userId);
        } else {
          await client
              .from('asset_items')
              .delete()
              .neq('id', '00000000-0000-0000-0000-000000000000');
        }
        storage.clearMemoryCache();
      } else {
        emit(state.copyWith(wipeProgressMessage: 'Clearing local cache...'));
        await storage.wipeLocalCache();
      }

      emit(
        state.copyWith(
          isWiping: false,
          wipeProgressMessage: 'Asset wipe complete',
          maintenanceResults: {
            'type': 'assets',
            'data': assetResults,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isWiping: false,
          wipeProgressMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }
}
