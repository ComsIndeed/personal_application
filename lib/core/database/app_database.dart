import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/message/media_type.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/models/message/message_role.dart';

import '../tables/asset_items.dart';
import '../tables/conversation_items.dart';
import '../tables/message_items.dart';

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
