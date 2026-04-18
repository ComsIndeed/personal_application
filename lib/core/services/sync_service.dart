import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncable/syncable.dart';

import '../database/app_database.dart';
import '../models/asset_item.dart';

/// Manages the [SyncManager] lifecycle for syncing asset records
/// between the local Drift DB and Supabase.
///
/// Call [start] after the user signs in, [stop] on sign out.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SyncManager<AssetItem>? _manager;

  bool get isRunning => _manager != null;

  /// Start syncing [AssetItems] for the current authenticated user.
  ///
  /// Safe to call multiple times — no-op if already running.
  void start() {
    if (_manager != null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final db = AppDatabase();

    _manager = SyncManager<AssetItem>(
      userId: user.id,
      supabaseClient: Supabase.instance.client,
      table: db.assetItems,
      tableName: 'asset_items',
      database: db,
      fromJson: AssetItem.fromJson,
    );

    _manager!.startSync();
  }

  /// Stop syncing and clean up.
  void stop() {
    _manager?.stopSync();
    _manager = null;
  }
}
