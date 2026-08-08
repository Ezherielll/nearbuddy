import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/messages_table.dart';
part 'messages_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessagesDao extends DatabaseAccessor<AppDatabase> with _$MessagesDaoMixin {
  MessagesDao(super.db);

  Stream<List<MessageRow>> watchMessages(String groupId) =>
      (select(messages)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch();

  Future<int> insertMessage(MessagesCompanion entry) =>
      into(messages).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<int> deleteOlderThan(DateTime cutoff) =>
      (delete(messages)
            ..where((m) => m.timestamp.isSmallerThan(Variable(cutoff))))
          .go();

  Future<MessageRow?> messageById(String id) =>
      (select(messages)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<void> markDelivered(String id) => (update(messages)
        ..where((m) => m.id.equals(id)))
      .write(const MessagesCompanion(status: Value('delivered')));

  Future<void> markFailed(String id) => (update(messages)
        ..where((m) => m.id.equals(id)))
      .write(const MessagesCompanion(status: Value('failed')));
}
