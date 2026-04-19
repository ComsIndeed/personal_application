import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

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
}
