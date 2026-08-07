import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sessions_table.dart';
part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<AppDatabase> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Stream<List<SessionRow>> watchAllSessions() => (select(sessions)
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
      .watch();

  Future<void> upsertSession(SessionsCompanion entry) =>
      into(sessions).insertOnConflictUpdate(entry);

  Future<SessionRow?> sessionForPeer(String peerDeviceId) =>
      (select(sessions)..where((s) => s.peerDeviceId.equals(peerDeviceId)))
          .getSingleOrNull();

  Future<SessionRow?> sessionById(String id) =>
      (select(sessions)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> deleteSession(String id) =>
      (delete(sessions)..where((s) => s.id.equals(id))).go();
}
