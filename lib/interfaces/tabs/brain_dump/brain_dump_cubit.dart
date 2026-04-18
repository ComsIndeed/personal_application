import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/services/storage_service.dart';

class BrainDumpCubit extends Cubit<BrainDumpState> {
  final AppDatabase _db;
  final StorageService _storage = StorageService();

  BrainDumpCubit(this._db) : super(BrainDumpState()) {
    _init();
  }

  void _init() {
    _db.select(_db.commonNoteItems)
      ..where((t) => t.category.equals(NoteCategory.braindump.name))
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..watch().listen((items) {
        emit(state.copyWith(items: items));
      });
  }

  void updateText(String text) {
    emit(state.copyWith(text: text));
  }

  void updateFiles(List<PlatformFile> files) {
    emit(state.copyWith(files: files));
  }

  Future<void> sendRaw() async {
    final text = state.text.trim();
    final files = state.files;

    if (text.isEmpty && files.isEmpty) return;

    // 1. Upload assets
    final assetIds = <String>[];
    for (final file in files) {
      final asset = await _storage.import(file, group: 'braindump');
      assetIds.add(asset.id);
    }

    // 2. Create note
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

    // 3. Clear state
    emit(state.copyWith(text: '', files: []));
  }

  void sendProcessed() {}
}

class BrainDumpState {
  // Inputs
  final String text;
  final List<PlatformFile> files;

  // View
  final List<CommonNoteItem> items;

  BrainDumpState({
    this.text = '',
    this.files = const [],
    this.items = const [],
  });

  BrainDumpState copyWith({
    String? text,
    List<PlatformFile>? files,
    List<CommonNoteItem>? items,
  }) {
    return BrainDumpState(
      text: text ?? this.text,
      files: files ?? this.files,
      items: items ?? this.items,
    );
  }
}
