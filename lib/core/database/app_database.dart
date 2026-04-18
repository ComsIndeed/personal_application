import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncable/syncable.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/models/asset_item.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/models/conversation.dart';
import 'package:personal_application/core/models/message/message.dart';

import 'package:personal_application/core/tables/asset_items.dart';
import 'package:personal_application/core/tables/conversation_items.dart';
import 'package:personal_application/core/tables/message_items.dart';
import 'package:personal_application/core/tables/common_note_items.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Conversations, Messages, AssetItems, CommonNoteItems])
class AppDatabase extends _$AppDatabase with SyncableDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_v2.db'));

    if (Platform.isAndroid) {
      // await applyWorkaroundToOpenSqlite3OnOldAndroidDevices();
    }

    return NativeDatabase.createInBackground(file);
  });
}
