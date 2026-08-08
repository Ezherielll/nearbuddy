import 'package:drift/drift.dart' hide isNull;
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

  test('DM message persists `to` and filters by session id', () async {
    await db.messagesDao.insertMessage(MessagesCompanion.insert(
      id: 'dm-1', groupId: 's1', senderId: 'Bimo',
      content: 'pribadi', type: 'text', timestamp: DateTime.utc(2026, 8, 8),
      to: const Value('device-peer-1'),
    ));
    final rows = await db.messagesDao.watchMessages('s1').first;
    expect(rows.single.to, 'device-peer-1');
  });

  test('memberPublicKey is device-scoped across groups', () async {
    await db.groupsDao.upsertMember(MembersCompanion.insert(
      deviceId: 'dev-x', groupId: 'g1',
      nickname: 'Nadia', lastSeen: DateTime.now(),
    ));
    await db.groupsDao.setMemberPublicKey('dev-x', 'g1', 'pub-b64-1');
    expect(await db.groupsDao.memberPublicKey('dev-x'), 'pub-b64-1');
    expect(await db.groupsDao.memberPublicKey('dev-unknown'), isNull);
  });

  test('delivery status lifecycle: pending → delivered via ack', () async {
    await db.messagesDao.insertMessage(MessagesCompanion.insert(
      id: 'dm-2', groupId: 's1', senderId: 'Bimo',
      content: 'pribadi', type: 'text', timestamp: DateTime.utc(2026, 8, 8),
      to: const Value('dev-peer-1'), status: const Value('pending'),
    ));
    expect((await db.messagesDao.messageById('dm-2'))!.status, 'pending');
    await db.messagesDao.markDelivered('dm-2');
    expect((await db.messagesDao.messageById('dm-2'))!.status, 'delivered');
    await db.messagesDao.markFailed('dm-2');
    expect((await db.messagesDao.messageById('dm-2'))!.status, 'failed');
    expect(await db.messagesDao.messageById('unknown-id'), isNull);
  });
}
