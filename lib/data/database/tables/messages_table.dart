import 'package:drift/drift.dart';
@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get id => text()();                  // UUID — primary key
  TextColumn get groupId => text()();
  TextColumn get senderId => text()();            // nickname
  TextColumn get content => text()();
  TextColumn get type => text()();               // 'text' | 'location'
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get hopCount => integer().withDefault(const Constant(0))();
  TextColumn get deliveredTo => text().withDefault(const Constant('[]'))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get locationAccuracy => real().nullable()();
  TextColumn get to => text().nullable()();       // DM recipient deviceId; null = group
  TextColumn get status => text().nullable()();   // 'pending'|'sent'|'delivered' (outgoing only)
  @override
  Set<Column> get primaryKey => {id};
}
