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

  void setHoveredItem(CommonNoteItem? item) {
    if (state.hoveredItem != item) {
      emit(state.copyWith(hoveredItem: item, clearHovered: item == null));
    }
  }

  void setSelectedItem(CommonNoteItem? item) {
    if (state.selectedItem != item) {
      emit(state.copyWith(selectedItem: item, clearSelected: item == null));
    }
  }

  void clear() {
    emit(const ItemPreviewState());
  }
}
