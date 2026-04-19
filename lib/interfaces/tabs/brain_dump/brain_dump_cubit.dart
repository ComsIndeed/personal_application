import 'dart:async';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class BrainDumpCubit extends Cubit<BrainDumpState> {
  final AppDatabase _db;
  final StorageService _storage = StorageService();
  StreamSubscription? _subscription;

  BrainDumpCubit(this._db) : super(BrainDumpState()) {
    _init();
  }

  void _init() {
    _subscription?.cancel();
    _subscription =
        (_db.select(_db.commonNoteItems)
              ..where((t) => t.category.equals(NoteCategory.braindump.name))
              ..where((t) => t.deleted.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .watch()
            .listen((items) {
              emit(state.copyWith(items: items, isLoading: false));
            });
  }

  void refresh() {
    emit(state.copyWith(isLoading: true));
    _init();
  }

  void updateText(String text) {
    emit(state.copyWith(text: text));
  }

  void updateFiles(List<PlatformFile> files) {
    emit(state.copyWith(files: files));
  }

  Future<void> sendRaw() async {
    final text = state.text.trim();
    final files = List<PlatformFile>.from(state.files);

    if (text.isEmpty && files.isEmpty) return;

    // 1. Create a "ghost" item for optimistic UI
    final ghost = CommonNoteItem(
      id: const Uuid().v4(),
      category: NoteCategory.braindump,
      textContent: text.isEmpty ? null : text,
      assetIds: const [], // Will be updated when real record saved
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deleted: false,
    );

    // 2. Immediate UI update
    emit(
      state.copyWith(
        text: '',
        files: [],
        pendingItems: [ghost, ...state.pendingItems],
      ),
    );

    // 3. Process in background
    _processAndSave(ghost.id, text, files);
  }

  Future<void> _processAndSave(
    String ghostId,
    String text,
    List<PlatformFile> files,
  ) async {
    try {
      // Upload assets
      final assetIds = <String>[];
      for (final file in files) {
        final asset = await _storage.import(file, group: 'braindump');
        assetIds.add(asset.id);
      }

      // Create local record
      await _db
          .into(_db.commonNoteItems)
          .insert(
            CommonNoteItemsCompanion.insert(
              category: NoteCategory.braindump,
              textContent: Value(text.isEmpty ? null : text),
              assetIds: Value(assetIds),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      // TODO: Handle error UI? For now just remove ghost
      print('Error saving braindump: $e');
    } finally {
      // Remove ghost item
      final newPending = state.pendingItems
          .where((i) => i.id != ghostId)
          .toList();
      emit(state.copyWith(pendingItems: newPending));
    }
  }

  void sendProcessed() {}

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class BrainDumpState {
  // Inputs
  final String text;
  final List<PlatformFile> files;

  // View
  final List<CommonNoteItem> items;
  final List<CommonNoteItem> pendingItems;

  final bool isLoading;

  BrainDumpState({
    this.text = '',
    this.files = const [],
    this.items = const [],
    this.pendingItems = const [],
    this.isLoading = true,
  });

  BrainDumpState copyWith({
    String? text,
    List<PlatformFile>? files,
    List<CommonNoteItem>? items,
    List<CommonNoteItem>? pendingItems,
    bool? isLoading,
  }) {
    return BrainDumpState(
      text: text ?? this.text,
      files: files ?? this.files,
      items: items ?? this.items,
      pendingItems: pendingItems ?? this.pendingItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
