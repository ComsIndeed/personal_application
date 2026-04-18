import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncable/syncable.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/asset_item.dart';
import '../models/conversation.dart';
import '../models/message/message.dart';
import '../models/common_note_item.dart';

/// Manages Drift ↔ Supabase record sync for the application's local-first data.
///
/// Call [start] after the user signs in. Call [stop] on sign out.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SyncManager<AppDatabase>? _manager;

  bool get isRunning => _manager != null;

  /// Start syncing records for the current authenticated user.
  /// Safe to call multiple times — no-op if already running.
  void start(AppDatabase db) {
    if (_manager != null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _manager = SyncManager<AppDatabase>(
      localDatabase: db,
      supabaseClient: Supabase.instance.client,
    );

    // 1. Asset Items
    _manager!.registerSyncable<AssetItem>(
      backendTable: 'asset_items',
      fromJson: AssetItem.fromJson,
      companionConstructor:
          ({
            Value<bool> deleted = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
          }) => AssetItemsCompanion(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
            deleted: deleted,
          ),
    );

    // 2. Conversations
    _manager!.registerSyncable<Conversation>(
      backendTable: 'conversations',
      fromJson: Conversation.fromJson,
      companionConstructor:
          ({
            Value<bool> deleted = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
          }) => ConversationsCompanion(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
            deleted: deleted,
          ),
    );

    // 3. Messages
    _manager!.registerSyncable<Message>(
      backendTable: 'messages',
      fromJson: Message.fromJson,
      companionConstructor:
          ({
            Value<bool> deleted = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
          }) => MessagesCompanion(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
            deleted: deleted,
          ),
    );

    // 4. Common Note Items (Brain Dump & Notes)
    _manager!.registerSyncable<CommonNoteItem>(
      backendTable: 'common_note_items',
      fromJson: CommonNoteItem.fromJson,
      companionConstructor:
          ({
            Value<bool> deleted = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
          }) => CommonNoteItemsCompanion(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
            deleted: deleted,
          ),
    );

    _manager!.setUserId(user.id);
    _manager!.enableSync();
  }

  /// Stop syncing and clean up resources.
  void stop() {
    _manager?.disableSync();
    _manager?.dispose();
    _manager = null;
  }
}
