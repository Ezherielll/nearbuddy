import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import 'tables/messages_table.dart';
import 'tables/groups_table.dart';
import 'tables/members_table.dart';
import 'daos/messages_dao.dart';
import 'daos/groups_dao.dart';
part 'app_database.g.dart';

@DriftDatabase(tables: [Messages, Groups, Members], daos: [MessagesDao, GroupsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() =>
      driftDatabase(name: AppConfig.databaseName);
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final messagesDaoProvider = Provider<MessagesDao>(
    (ref) => ref.watch(appDatabaseProvider).messagesDao);

final groupsDaoProvider = Provider<GroupsDao>(
    (ref) => ref.watch(appDatabaseProvider).groupsDao);
