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

  const DatabaseBrowserState({
    this.isVisible = false,
    this.rootTab = DatabaseRootTab.local,
    this.selectedTable,
    this.searchQuery = '',
    this.sortColumn,
    this.isAscending = true,
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
  }) {
    return DatabaseBrowserState(
      isVisible: isVisible ?? this.isVisible,
      rootTab: rootTab ?? this.rootTab,
      selectedTable: clearTable ? null : (selectedTable ?? this.selectedTable),
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumn: clearSort ? null : (sortColumn ?? this.sortColumn),
      isAscending: isAscending ?? this.isAscending,
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

  Future<void> wipeDatabase({
    required SyncableDatabase db,
    bool local = true,
    bool cloud = true,
  }) async {
    const exclude = ['asset_items'];

    if (local) {
      if (db is AppDatabase) {
        await db.wipeLocalData(exclude: exclude);
      }
    }
    if (cloud) {
      final client = Supabase.instance.client;
      final tables = ['conversations', 'messages', 'common_note_items'];
      for (final table in tables) {
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          await client.from(table).delete().eq('user_id', userId);
        } else {
          await client
              .from(table)
              .delete()
              .neq('id', '00000000-0000-0000-0000-000000000000');
        }
      }
    }
    // Refresh the current view
    final currentTable = state.selectedTable;
    emit(state.copyWith(clearTable: true));
    emit(state.copyWith(selectedTable: currentTable));
  }

  Future<void> wipeAssets({
    required StorageService storage,
    required SyncableDatabase db,
    bool both = true,
  }) async {
    if (both) {
      // 1. Wipe Cloud Storage (Files)
      await storage.wipeCloudStorage();

      // 2. Wipe Local Assets Table
      if (db is AppDatabase) {
        await (db.delete(db.assetItems)).go();
      }

      // 3. Wipe Cloud Assets Table
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

      // 4. Clear memory cache
      storage.clearMemoryCache();
    } else {
      // "Only Local Cache" -> just clear cached_bytes, records stay
      await storage.wipeLocalCache();
    }

    // Refresh the current view
    final currentTable = state.selectedTable;
    emit(state.copyWith(clearTable: true));
    emit(state.copyWith(selectedTable: currentTable));
  }
}
