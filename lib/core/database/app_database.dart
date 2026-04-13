import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../tables/conversation_items.dart';
import '../tables/message_items.dart';
import '../tables/asset_items.dart';
import '../models/message_models.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Conversations, Messages, AssetItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));

    if (Platform.isAndroid) {
      // await applyWorkaroundToOpenSqlite3OnOldAndroidDevices();
    }

    return NativeDatabase.createInBackground(file);
  });
}
