import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('upsertSession then watchAllSessions emits the row', () async {
    await db.sessionsDao.upsertSession(SessionsCompanion.insert(
      id: 's1', peerDeviceId: 'dev-9', peerNickname: 'Nadia',
      createdAt: DateTime.utc(2026, 8, 8),
    ));
    final rows = await db.sessionsDao.watchAllSessions().first;
    expect(rows.single.peerNickname, 'Nadia');
    expect(await db.sessionsDao.sessionForPeer('dev-9'), isNotNull);
    expect(await db.sessionsDao.sessionById('s1'), isNotNull);
    expect(await db.sessionsDao.sessionForPeer('dev-8'), isNull);
  });

  test('upsertSession replaces on conflict (same id)', () async {
    await db.sessionsDao.upsertSession(SessionsCompanion.insert(
      id: 's1', peerDeviceId: 'dev-9', peerNickname: 'Nadia',
      createdAt: DateTime.utc(2026, 8, 8),
    ));
    await db.sessionsDao.upsertSession(SessionsCompanion.insert(
      id: 's1', peerDeviceId: 'dev-9', peerNickname: 'Nadia Baru',
      createdAt: DateTime.utc(2026, 8, 8),
    ));
    final rows = await db.sessionsDao.watchAllSessions().first;
    expect(rows.length, 1);
    expect(rows.single.peerNickname, 'Nadia Baru');
  });

  test('deleteSession removes the session', () async {
    await db.sessionsDao.upsertSession(SessionsCompanion.insert(
      id: 's1', peerDeviceId: 'dev-9', peerNickname: 'Nadia',
      createdAt: DateTime.utc(2026, 8, 8),
    ));
    await db.sessionsDao.deleteSession('s1');
    expect(await db.sessionsDao.sessionById('s1'), isNull);
  });
}
