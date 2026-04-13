import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../models/message_models.dart';

class AssetItems extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  BlobColumn get data => blob()();
  TextColumn get mediaType => textEnum<MediaType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
