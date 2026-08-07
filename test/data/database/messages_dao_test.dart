import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('insertMessage then watchMessages emits the row', () async {
    await db.messagesDao.insertMessage(MessagesCompanion.insert(
      id: 'msg-1', groupId: 'g1', senderId: 'Bimo',
      content: 'Halo', type: 'text', timestamp: DateTime.utc(2026, 8, 7),
    ));
    final rows = await db.messagesDao.watchMessages('g1').first;
    expect(rows.length, 1);
    expect(rows.first.content, 'Halo');
  });

  test('deleteOlderThan removes only old messages', () async {
    await db.messagesDao.insertMessage(MessagesCompanion.insert(
      id: 'old', groupId: 'g1', senderId: 'A', content: 'old',
      type: 'text', timestamp: DateTime.utc(2026, 1, 1),
    ));
    await db.messagesDao.insertMessage(MessagesCompanion.insert(
      id: 'new', groupId: 'g1', senderId: 'B', content: 'new',
      type: 'text', timestamp: DateTime.utc(2026, 8, 7),
    ));
    final count = await db.messagesDao.deleteOlderThan(DateTime.utc(2026, 8, 1));
    expect(count, 1);
    final remaining = await db.messagesDao.watchMessages('g1').first;
    expect(remaining.first.id, 'new');
  });

  test('isNicknameTaken true when active member has same name', () async {
    await db.groupsDao.upsertMember(MembersCompanion.insert(
      deviceId: 'other', groupId: 'g1',
      nickname: 'Bimo', lastSeen: DateTime.now(),
    ));
    expect(await db.groupsDao.isNicknameTaken('Bimo', 'g1', 'me'), isTrue);
    expect(await db.groupsDao.isNicknameTaken('Bimo', 'g1', 'other'), isFalse);
  });
}
