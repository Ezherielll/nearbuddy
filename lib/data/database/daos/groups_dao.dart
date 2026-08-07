import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/groups_table.dart';
import '../tables/members_table.dart';
part 'groups_dao.g.dart';

@DriftAccessor(tables: [Groups, Members])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  Stream<List<GroupRow>> watchAllGroups() => select(groups).watch();

  Future<int> insertGroup(GroupsCompanion entry) =>
      into(groups).insert(entry, mode: InsertMode.insertOrReplace);

  Future<GroupRow?> groupById(String groupId) =>
      (select(groups)..where((g) => g.id.equals(groupId))).getSingleOrNull();

  Future<void> deleteGroup(String groupId) =>
      (delete(groups)..where((g) => g.id.equals(groupId))).go();

  Stream<List<MemberRow>> watchMembersInGroup(String groupId) =>
      (select(members)
            ..where((m) => m.groupId.equals(groupId) & m.isActive.equals(true)))
          .watch();

  Future<void> upsertMember(MembersCompanion entry) =>
      into(members).insertOnConflictUpdate(entry);

  Future<void> markMemberInactive(String deviceId, String groupId) =>
      (update(members)
            ..where((m) =>
                m.deviceId.equals(deviceId) & m.groupId.equals(groupId)))
          .write(const MembersCompanion(isActive: Value(false)));

  Future<bool> isNicknameTaken(
      String nickname, String groupId, String ownDeviceId) async {
    final rows = await (select(members)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.nickname.equals(nickname) &
              m.isActive.equals(true) &
              m.deviceId.equals(ownDeviceId).not()))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> setMemberPublicKey(
          String deviceId, String groupId, String pubKeyB64) =>
      (update(members)
            ..where((m) =>
                m.deviceId.equals(deviceId) & m.groupId.equals(groupId)))
          .write(MembersCompanion(publicKey: Value(pubKeyB64)));

  /// Public key is device-scoped (one X25519 keypair per device), so the
  /// groupId does not matter — return the latest known value for the device.
  Future<String?> memberPublicKey(String deviceId) async {
    final row = await (select(members)
          ..where((m) => m.deviceId.equals(deviceId))
          ..limit(1))
        .getSingleOrNull();
    return row?.publicKey;
  }
}
