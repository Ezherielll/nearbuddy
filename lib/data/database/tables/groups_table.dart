import 'package:drift/drift.dart';
@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get pin => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isOwner => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}
