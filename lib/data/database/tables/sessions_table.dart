import 'package:drift/drift.dart';
@DataClassName('SessionRow')  // drift 2.31 defaults to 'Session'
class Sessions extends Table {
  TextColumn get id => text()();               // UUID
  TextColumn get peerDeviceId => text()();     // the other device's identity id
  TextColumn get peerNickname => text()();     // last known display nickname
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}
