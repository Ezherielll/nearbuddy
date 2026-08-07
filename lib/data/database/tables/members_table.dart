import 'package:drift/drift.dart';
@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get deviceId => text()();           // Nearby endpoint ID
  TextColumn get groupId => text()();
  TextColumn get nickname => text()();
  DateTimeColumn get lastSeen => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {deviceId, groupId};
}
