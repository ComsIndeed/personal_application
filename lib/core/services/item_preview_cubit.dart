import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/models/common_note_item.dart';

class ItemPreviewState {
  final CommonNoteItem? hoveredItem;
  final CommonNoteItem? selectedItem;

  const ItemPreviewState({this.hoveredItem, this.selectedItem});

  ItemPreviewState copyWith({
    CommonNoteItem? hoveredItem,
    bool clearHovered = false,
    CommonNoteItem? selectedItem,
    bool clearSelected = false,
  }) {
    return ItemPreviewState(
      hoveredItem: clearHovered ? null : (hoveredItem ?? this.hoveredItem),
      selectedItem: clearSelected ? null : (selectedItem ?? this.selectedItem),
    );
  }

  bool get isActive => hoveredItem != null || selectedItem != null;
  CommonNoteItem? get activeItem => selectedItem ?? hoveredItem;
}

class ItemPreviewCubit extends Cubit<ItemPreviewState> {
  ItemPreviewCubit() : super(const ItemPreviewState());

  Timer? _debounceTimer;

  void setHoveredItem(CommonNoteItem? item) {
    _debounceTimer?.cancel();

    if (item == null) {
      // Clear immediately to keep UI responsive when leaving
      emit(state.copyWith(clearHovered: true));
      return;
    }

    if (state.hoveredItem == item) return;

    // Add a 250ms delay before showing the preview to prevent "laggy" feeling when gliding
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (!isClosed) {
        emit(state.copyWith(hoveredItem: item));
      }
    });
  }

  void setSelectedItem(CommonNoteItem? item) {
    _debounceTimer?.cancel();
    if (state.selectedItem != item) {
      emit(state.copyWith(selectedItem: item, clearSelected: item == null));
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    emit(const ItemPreviewState());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
