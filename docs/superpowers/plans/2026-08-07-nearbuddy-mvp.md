# NearBuddy MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> ⚠️ **SUPERSEDED (2026-08-07):** Tasks 1–5 are DONE and authoritative. **Tasks 6–10 are REPLACED** by `docs/superpowers/plans/2026-08-07-nearbuddy-mvp-v2.md` (v2 Tasks 11–15) — the plaintext wire format, PIN-in-advertisement-name handling, and "no encryption" constraint below are **DEAD**. Do NOT implement Tasks 6–10 from this file.

| v1 Task (DO NOT implement) | v2 replacement |
|---|---|
| Task 6: Home Screen + Group Create/Join | v2 Task 11 (Home + Create/Join + SAS verification) |
| Task 7: Chat + Multi-Hop Relay | v2 Task 12 (Group chat E2EE + relay-without-decrypt) |
| Task 8: Location Ping | v2 Task 14 |
| Task 9: Settings Screen | v2 Task 15 (settings part) |
| Task 10: Build Flavors | v2 Task 15 (flavors part) |

**Goal:** Build the NearBuddy MVP — an offline-first, peer-to-peer Flutter app (Android) for group chat, location sharing, and multi-hop mesh relay using Google Nearby Connections, with no internet or cellular required.

**Architecture:** Clean architecture with feature/domain/data layers. Drift (SQLite) for local persistence. `PeerDiscoveryService` abstraction wrapping `nearby_connections` package. Flood routing with UUID-based deduplication for multi-hop relay (max 3 hops, TTL 10s).

**Tech Stack:**
- Flutter 3.44.x (Android-only MVP, minSdk 23)
- `nearby_connections` ^4.x
- `drift` ^2.18 + `drift_flutter` ^0.2 (SQLite ORM with codegen)
- `shared_preferences` ^2.3 (nickname, disclaimer, language)
- `geolocator` ^12.0 (GPS capture)
- `flutter_localizations` + `intl` ^0.20.2 (bilingual ID/EN; 0.19 not allowed — Flutter 3.44 pins intl 0.20.2)
- `uuid` ^4.4, `permission_handler` ^11.3, `battery_plus` ^6.0
- `go_router` ^14.3, `url_launcher` ^6.3, `flutter_riverpod` ^2.5
- `shadcn_ui` ^0.56 (UI component library; replaces Material scaffolds/buttons/inputs in all screens)

## Global Constraints

- Android minSdk: 23 (Android 6.0); targetSdk: 34
- **No network calls, no Firebase, no cloud dependency of any kind**
- All data stays on-device only
- Max group size: 30 devices; max relay hops: 3; relay TTL: 10 seconds
- Message max length: 500 characters
- Message retention: 7 days, then auto-deleted by Drift cleanup job
- Nickname: 3–20 characters, unique within a group session (validated on join)
- Bilingual: Indonesian (default) + English via ARB files
- Disclaimer shown once on first launch; `hasAcceptedDisclaimer` stored in SharedPreferences
- `FeatureFlags` class gates premium features (all `false` in v1)
- `PeerDiscoveryService` is an abstract interface; `NearbyConnectionsService` is the concrete Android impl
- **DO NOT add**: flutter_map, SOS feature, voice messaging, cloud integration — all out of scope v1
- **UI must use `shadcn_ui`** (`ShadApp` wrapper, `ShadButton`, `ShadInput`, `ShadDialog`, etc.). Material widgets stay only as the host widget tree (`Scaffold`/`AppBar`) via `ShadApp.custom` + `MaterialApp.router`. All `FilledButton`/`TextField`/`AlertDialog` seen in task snippets are Material placeholders — convert them per the [UI Policy (shadcn_ui)](#ui-policy-shadcn_ui) below.
- **Build flavors `dev` + `prod`** (Task 10): `productFlavors` in Gradle (applicationId `.dev` suffix, app label "NearBuddy Dev") + `--dart-define=FLAVOR` consumed by `AppConfig` (DB name `nearbuddy_db_dev`, Nearby service ID `com.nearbuddy.dev.<gid>` for dev). **After Task 10, every `flutter run`/`build` MUST pass `--flavor <name> --dart-define=FLAVOR=<name>`** — plain commands fail once `productFlavors` exists. Use `scripts/flavor.ps1`.

---

## UI Policy (shadcn_ui)

Every screen is built with `shadcn_ui` (^0.56). Setup in Task 1 (`ShadApp.custom` + `MaterialApp.router`). The snippets below use Material widgets as placeholders — substitute the Shad* equivalents:

| Task snippet (Material) | Use instead (shadcn_ui) |
|---|---|
| `FilledButton`, `ElevatedButton` | `ShadButton` (`variant: ShadButtonVariant.outline/ghost` as needed) |
| `TextButton` | `ShadButton` with `variant: ShadButtonVariant.ghost` |
| `TextField` (single line) | `ShadInput` |
| `TextField` (multiline / chat composer) | `ShadTextarea` |
| `AlertDialog` | `ShadDialog` |
| `Switch` / `SwitchListTile` | `ShadSwitch` (with `ShadListItem` + `trailing`) |
| `DropdownButton` | `ShadSelect` + `ShadOption` |
| `SnackBar` | `ShadToaster.of(context).show(ShadToast(...))` |
| `IconButton` | `ShadIconButton` |
| `Card` | `ShadCard` |
| `CircularProgressIndicator` | `ShadProgress` (indeterminate) |
| Material `Icons.*` | `LucideIcons.*` (re-exported by `shadcn_ui`; e.g. `LucideIcons.mapPin`, `LucideIcons.settings`) |

Rules:
- Keep `Scaffold`, `AppBar`, `SafeArea`, `ListView`, `Row`/`Column` — these are host widgets and are not replaced by shadcn.
- Read theme via `ShadTheme.of(context)` (e.g. `theme.textTheme.muted`) instead of `Theme.of(...).textTheme`.
- Brand color: use `ShadGreenColorScheme` (light + dark) wired in Task 1; the old `ColorScheme.fromSeed(0xFF1E6B4A)` is dropped.
- Widget tests must wrap screens in `ShadApp` (not bare `MaterialApp`) so `ShadTheme` is available — see Task 4 Step 1 wrapper; the existing `AppLocalizations` delegates are passed through `localizationsDelegates`.

---

## File Structure Overview

```
lib/
├── main.dart                                   # Entry point, provider overrides
├── app.dart                                    # MaterialApp.router + i18n setup
├── core/
│   ├── constants.dart                          # AppConstants (maxHops, TTL, limits)
│   ├── feature_flags.dart                      # FeatureFlags (all false in v1)
│   ├── app_config.dart                         # AppConfig — flavor-driven (FLAVOR dart-define): db name, service ID prefix
│   ├── router.dart                             # GoRouter with redirect logic
│   └── utils/
│       ├── uuid_generator.dart                 # Thin wrapper around uuid package
│       ├── battery_monitor.dart               # BatteryMonitor + lowBatteryProvider
│       └── permission_handler_service.dart    # Runtime permission requests
├── l10n/
│   ├── app_id.arb                             # Indonesian strings (template)
│   └── app_en.arb                             # English strings
├── data/
│   ├── database/
│   │   ├── app_database.dart                  # @DriftDatabase class + Riverpod providers
│   │   ├── tables/
│   │   │   ├── messages_table.dart
│   │   │   ├── groups_table.dart
│   │   │   └── members_table.dart
│   │   └── daos/
│   │       ├── messages_dao.dart
│   │       └── groups_dao.dart
│   └── preferences/
│       └── app_preferences.dart               # SharedPreferences wrapper
├── domain/
│   ├── models/
│   │   ├── message.dart                       # Message + MessageType enum + wire JSON
│   │   └── group_session.dart
│   └── services/
│       └── peer_discovery_service.dart        # Abstract interface
├── infrastructure/
│   └── nearby/
│       └── nearby_connections_service.dart    # Concrete impl using nearby_connections pkg
└── features/
    ├── onboarding/
    │   ├── disclaimer_screen.dart
    │   └── nickname_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   └── home_controller.dart               # nearbyGroupsProvider (StateNotifier)
    ├── group/
    │   ├── create_group_screen.dart
    │   ├── join_group_screen.dart
    │   └── group_controller.dart              # currentGroupProvider, groupControllerProvider
    ├── chat/
    │   ├── chat_screen.dart
    │   ├── chat_controller.dart               # chatControllerProvider, relay logic
    │   └── widgets/
    │       ├── message_bubble.dart
    │       └── location_ping_card.dart
    └── settings/
        └── settings_screen.dart
test/
├── data/database/messages_dao_test.dart
├── domain/services/relay_dedup_test.dart
└── features/
    ├── onboarding/disclaimer_screen_test.dart
    └── chat/chat_controller_test.dart
```

---

## Task 1: Project Scaffold + pubspec + Constants

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `l10n.yaml`
- Create: `lib/core/constants.dart`, `lib/core/feature_flags.dart`, `lib/core/router.dart`
- Modify: `android/app/build.gradle.kts` (minSdk 23 — Flutter 3.44 template is Kotlin DSL, not Groovy `build.gradle`), `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: `AppConstants`, `FeatureFlags`, placeholder `appRouter` — all available to downstream tasks

**Status: DONE (2026-08-07)** — all 13 steps complete; build & analyze pass. Forced deviations: `intl` ^0.20.2 (SDK-pinned), `AppPreferences` + ARB files + `gen-l10n` pulled forward from Task 3 (required by `main.dart`/`app.dart`), template `test/widget_test.dart` deleted, `ShadThemeData` is non-const.

- [x] **Step 1: flutter create**
  ```bash
  flutter create --org com.nearbuddy --project-name nearbuddy --platforms android .
  ```

- [x] **Step 2: Replace pubspec.yaml**
  ```yaml
  name: nearbuddy
  description: Offline group chat using Nearby Connections.
  version: 1.0.0+1
  environment:
    sdk: ">=3.0.0 <4.0.0"
    flutter: ">=3.16.0"
  dependencies:
    flutter:
      sdk: flutter
    flutter_localizations:
      sdk: flutter
    intl: ^0.20.2
    nearby_connections: ^4.0.0
    drift: ^2.18.0
    drift_flutter: ^0.2.2
    shared_preferences: ^2.3.2
    geolocator: ^12.0.0
    uuid: ^4.4.2
    permission_handler: ^11.3.1
    battery_plus: ^6.0.1
    go_router: ^14.3.0
    url_launcher: ^6.3.0
    riverpod: ^2.5.1
    flutter_riverpod: ^2.5.1
    shadcn_ui: ^0.56.1
  dev_dependencies:
    flutter_test:
      sdk: flutter
    build_runner: ^2.4.12
    drift_dev: ^2.18.0
    mockito: ^5.4.4
    flutter_lints: ^4.0.0
  flutter:
    uses-material-design: true
    generate: true
  ```

- [x] **Step 3: flutter pub get** — verify no errors

- [x] **Step 4: Create lib/core/constants.dart**
  ```dart
  abstract final class AppConstants {
    static const int maxHops = 3;
    static const int relayTtlSeconds = 10;
    static const int maxGroupSize = 30;
    static const int maxMessageLength = 500;
    static const int messageRetentionDays = 7;
    static const int nicknameLengthMin = 3;
    static const int nicknameLengthMax = 20;
    static const int pinLengthMin = 4;
    static const int pinLengthMax = 6;
    static const int relayDeduplicationCacheSeconds = 30;
    static const int lowBatteryThresholdPercent = 20;
  }
  ```

- [x] **Step 5: Create lib/core/feature_flags.dart**
  ```dart
  abstract final class FeatureFlags {
    /// SOS Broadcast — premium v1.1+
    static const bool sosEnabled = false;
    /// Offline map with pre-cached tiles — premium v1.1+
    static const bool offlineMapEnabled = false;
    /// Group size > 30 devices — premium v1.1+
    static const bool extendedGroupSize = false;
    /// Message retention > 7 days — premium v1.1+
    static const bool extendedRetention = false;
  }
  ```

- [x] **Step 6: Set minSdk 23 in android/app/build.gradle**

  In `android { defaultConfig { ... } }` block:
  ```groovy
  minSdkVersion 23
  targetSdkVersion 34
  ```

- [x] **Step 7: Add permissions to android/app/src/main/AndroidManifest.xml**

  Add `xmlns:tools="http://schemas.android.com/tools"` to `<manifest>` tag.
  Inside `<manifest>`, before `<application>`:
  ```xml
  <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
      android:usesPermissionFlags="neverForLocation" tools:targetApi="s" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
  <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
      android:usesPermissionFlags="neverForLocation" tools:targetApi="tiramisu" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```

- [x] **Step 8: Create lib/main.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'data/preferences/app_preferences.dart';
  import 'app.dart';
  import 'core/router.dart';

  final appPreferencesProvider = Provider<AppPreferences>((_) => throw UnimplementedError());
  final localeProvider = StateProvider<Locale>((ref) =>
      Locale(ref.watch(appPreferencesProvider).languageCode));

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await AppPreferences.create();
    runApp(ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      child: const NearBuddyApp(),
    ));
  }
  ```

- [x] **Step 9: Create lib/app.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_localizations/flutter_localizations.dart';
  import 'l10n/app_localizations.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shadcn_ui/shadcn_ui.dart';
  import 'core/router.dart';
  import 'main.dart';

  class NearBuddyApp extends ConsumerWidget {
    const NearBuddyApp({super.key});
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final locale = ref.watch(localeProvider);
      return ShadApp.custom(
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: const ShadGreenColorScheme.light(),
        ),
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadGreenColorScheme.dark(),
        ),
        themeMode: ThemeMode.system,
        appBuilder: (context) {
          return MaterialApp.router(
            title: 'NearBuddy',
            routerConfig: appRouter,
            theme: Theme.of(context),
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalShadLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            builder: (context, child) => ShadAppBuilder(child: child!),
          );
        },
      );
    }
  }
  ```

  Notes: `ShadApp.custom` is required because we use GoRouter (`MaterialApp.router` per shadcn interop guide). `GlobalShadLocalizations.delegate` must be added alongside the Material delegates. `ShadAppBuilder` wires shadcn's theme/builder into the Material tree. The green color scheme replaces the old `ColorScheme.fromSeed(seedColor: 0xFF1E6B4A)` theme. `ShadThemeData` is NOT a const constructor in 0.56.x — only the color scheme itself is `const`.

- [x] **Step 10: Create placeholder lib/core/router.dart**
  ```dart
  import 'package:go_router/go_router.dart';
  import 'package:flutter/material.dart';

  late final GoRouter appRouter;

  GoRouter buildRouter(dynamic prefs) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(
          body: Center(child: Text('NearBuddy — scaffold')))),
    ],
  );
  ```

  Update `main()` to initialize `appRouter = buildRouter(prefs);` before `runApp`.

- [x] **Step 11: Create l10n.yaml at project root**
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_id.arb
  output-localization-file: app_localizations.dart
  ```

- [x] **Step 12: Verify debug build**
  ```bash
  flutter build apk --debug
  ```
  Expected: BUILD SUCCESSFUL

- [x] **Step 13: Commit**
  ```bash
  git init && git add . && git commit -m "feat: scaffold project — dependencies, constants, feature flags, Android permissions"
  ```

---

## Task 2: Drift Database Schema + DAOs

**Files:**
- Create: `lib/data/database/tables/messages_table.dart`
- Create: `lib/data/database/tables/groups_table.dart`
- Create: `lib/data/database/tables/members_table.dart`
- Create: `lib/data/database/daos/messages_dao.dart`
- Create: `lib/data/database/daos/groups_dao.dart`
- Create: `lib/data/database/app_database.dart`
- Create: `test/data/database/messages_dao_test.dart`

**Interfaces:**
- Produces:
  - `appDatabaseProvider`, `messagesDaoProvider`, `groupsDaoProvider` (Riverpod)
  - `MessagesDao.watchMessages(String groupId)` → `Stream<List<MessageRow>>`
  - `MessagesDao.insertMessage(MessagesCompanion)` → `Future<int>` (insertOrIgnore)
  - `MessagesDao.deleteOlderThan(DateTime cutoff)` → `Future<int>`
  - `GroupsDao.insertGroup(GroupsCompanion)` → `Future<int>`
  - `GroupsDao.watchAllGroups()` → `Stream<List<GroupRow>>`
  - `GroupsDao.upsertMember(MembersCompanion)` → `Future<void>`
  - `GroupsDao.watchMembersInGroup(String groupId)` → `Stream<List<MemberRow>>`
  - `GroupsDao.isNicknameTaken(String nickname, String groupId, String ownDeviceId)` → `Future<bool>`

**Status: DONE (2026-08-07)** — all 10 steps complete; tests pass, analyze clean, commit `78f4f8d`. Deviations: (1) each table file needs `@DataClassName('MessageRow'|'GroupRow'|'MemberRow')` — drift 2.31 generates `Message`/`Group`/`Member` by default; (2) `AppConfig` (Task 10 file) pulled forward because the flavor-updated `app_database.dart` snippet references it; (3) `--delete-conflicting-outputs` is removed in build_runner 2.15 (warning, harmless); (4) test imports only `app_database.dart` — companion types are exported by `app_database.g.dart`; (5) `AppDatabase.forTesting(super.e)` satisfies `use_super_parameters` lint.

- [x] **Step 1: Create tables/messages_table.dart**
  ```dart
  import 'package:drift/drift.dart';
  @DataClassName('MessageRow')  // drift 2.31 defaults to 'Message'
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
    @override
    Set<Column> get primaryKey => {id};
  }
  ```

- [x] **Step 2: Create tables/groups_table.dart**
  ```dart
  import 'package:drift/drift.dart';
  @DataClassName('GroupRow')  // drift 2.31 defaults to 'Group'
  class Groups extends Table {
    TextColumn get id => text()();
    TextColumn get name => text()();
    TextColumn get pin => text().nullable()();
    DateTimeColumn get createdAt => dateTime()();
    BoolColumn get isOwner => boolean().withDefault(const Constant(false))();
    @override
    Set<Column> get primaryKey => {id};
  }
  ```

- [x] **Step 3: Create tables/members_table.dart**
  ```dart
  import 'package:drift/drift.dart';
  @DataClassName('MemberRow')  // drift 2.31 defaults to 'Member'
  class Members extends Table {
    TextColumn get deviceId => text()();           // Nearby endpoint ID
    TextColumn get groupId => text()();
    TextColumn get nickname => text()();
    DateTimeColumn get lastSeen => dateTime()();
    BoolColumn get isActive => boolean().withDefault(const Constant(true))();
    @override
    Set<Column> get primaryKey => {deviceId, groupId};
  }
  ```

- [x] **Step 4: Create daos/messages_dao.dart**
  ```dart
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
  }
  ```

- [x] **Step 5: Create daos/groups_dao.dart**
  ```dart
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
  }
  ```

- [x] **Step 6: Create app_database.dart**
  ```dart
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
    AppDatabase.forTesting(QueryExecutor e) : super(e);

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
  ```

- [x] **Step 7: Run Drift code generation**
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
  Expected: `app_database.g.dart`, `messages_dao.g.dart`, `groups_dao.g.dart` created.

- [x] **Step 8: Write failing test**
  Create `test/data/database/messages_dao_test.dart`:
  ```dart
  import 'package:drift/native.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:nearbuddy/data/database/app_database.dart';
  import 'package:nearbuddy/data/database/tables/messages_table.dart';

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
  ```

- [x] **Step 9: Run tests — expect PASS**
  ```bash
  flutter test test/data/database/messages_dao_test.dart -v
  ```

- [x] **Step 10: Commit**
  ```bash
  git add . && git commit -m "feat: Drift schema (Messages/Groups/Members), DAOs, and passing database tests"
  ```

---

## Task 3: i18n + AppPreferences + PermissionHandlerService

**Files:**
- Create: `lib/data/preferences/app_preferences.dart`
- Create: `lib/core/utils/permission_handler_service.dart`
- Create: `lib/l10n/app_id.arb`, `lib/l10n/app_en.arb`

**Interfaces:**
- Produces:
  - `AppPreferences.create()` → `Future<AppPreferences>`
  - `AppPreferences.{nickname, hasAcceptedDisclaimer, languageCode}` getters + setters
  - `PermissionHandlerService.requestNearbyPermissions()` → `Future<bool>`
  - `PermissionHandlerService.requestLocationPermission()` → `Future<bool>`
  - `AppLocalizations` generated from ARB files — all string keys available in Tasks 4–9

**Status: DONE (2026-08-07)** — build passes, analyze clean, commit `35f3be5`. Steps 1/3/4/5 were completed early in Task 1 (pulled forward because `main.dart`/`app.dart` need `AppPreferences` + `AppLocalizations`); Step 2 (`permission_handler_service.dart`) created here with imports fixed to the top of the file (plan snippet placed them mid-file). Generated l10n lives in `lib/l10n/` (see Task 3 Step 5 note).

- [x] **Step 1: Create lib/data/preferences/app_preferences.dart**
  ```dart
  import 'package:shared_preferences/shared_preferences.dart';

  class AppPreferences {
    static const _kNick = 'nickname';
    static const _kDisclaimer = 'hasAcceptedDisclaimer';
    static const _kLang = 'languageCode';

    final SharedPreferences _p;
    AppPreferences(this._p);

    static Future<AppPreferences> create() async =>
        AppPreferences(await SharedPreferences.getInstance());

    String? get nickname => _p.getString(_kNick);
    Future<void> setNickname(String v) => _p.setString(_kNick, v);

    bool get hasAcceptedDisclaimer => _p.getBool(_kDisclaimer) ?? false;
    Future<void> acceptDisclaimer() => _p.setBool(_kDisclaimer, true);

    String get languageCode => _p.getString(_kLang) ?? 'id';
    Future<void> setLanguageCode(String c) => _p.setString(_kLang, c);
  }
  ```

- [x] **Step 2: Create lib/core/utils/permission_handler_service.dart**
  ```dart
  import 'package:permission_handler/permission_handler.dart';

  class PermissionHandlerService {
    Future<bool> requestNearbyPermissions() async {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((s) => s.isGranted || s.isLimited);
    }

    Future<bool> requestLocationPermission() async {
      final s = await Permission.locationWhenInUse.request();
      return s.isGranted || s.isLimited;
    }
  }

  // Riverpod provider — used by ChatController
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  final permissionHandlerServiceProvider =
      Provider<PermissionHandlerService>((_) => PermissionHandlerService());
  ```

- [x] **Step 3: Create lib/l10n/app_id.arb**
  ```json
  {
    "@@locale": "id",
    "appName": "NearBuddy",
    "disclaimerTitle": "Pemberitahuan Penting",
    "disclaimerBody": "NearBuddy adalah alat komunikasi komunitas, bukan pengganti layanan darurat resmi. Jangan andalkan aplikasi ini sebagai satu-satunya alat dalam situasi darurat.",
    "disclaimerAccept": "Saya Mengerti",
    "nicknameTitle": "Siapa namamu?",
    "nicknameHint": "Masukkan nickname (3-20 karakter)",
    "nicknameError": "Nickname harus 3-20 karakter",
    "continueLabel": "Lanjut",
    "createGroup": "Buat Grup",
    "joinGroup": "Gabung Grup",
    "groupName": "Nama Grup",
    "groupPin": "PIN Grup (opsional)",
    "nearbyGroups": "Grup di Sekitar",
    "noNearbyGroups": "Tidak ada grup ditemukan. Buat grup baru atau tunggu.",
    "send": "Kirim",
    "sendLocation": "Kirim Lokasi Saya",
    "sendLocationConfirm": "Kirim koordinat lokasi Anda sekarang?",
    "locationPingLabel": "Lokasi",
    "openInMaps": "Buka di Maps",
    "memberCount": "{count} anggota",
    "@memberCount": { "placeholders": { "count": { "type": "int" } } },
    "messageSent": "Terkirim",
    "messageDelivered": "Diterima",
    "lowBatteryMode": "Mode Hemat Aktif",
    "permissionRequired": "Izin Diperlukan",
    "permissionExplanation": "NearBuddy memerlukan izin Bluetooth dan Lokasi untuk menemukan perangkat di sekitar.",
    "grantPermission": "Berikan Izin",
    "nicknameInUse": "Nickname sudah dipakai anggota lain. Pilih nama lain.",
    "settings": "Pengaturan",
    "language": "Bahasa",
    "changeNickname": "Ganti Nickname",
    "leaveGroup": "Keluar dari Grup",
    "members": "Anggota"
  }
  ```

- [x] **Step 4: Create lib/l10n/app_en.arb**
  ```json
  {
    "@@locale": "en",
    "appName": "NearBuddy",
    "disclaimerTitle": "Important Notice",
    "disclaimerBody": "NearBuddy is a community communication tool, not a substitute for official emergency services. Do not rely on this app as your sole tool in emergency situations.",
    "disclaimerAccept": "I Understand",
    "nicknameTitle": "What is your name?",
    "nicknameHint": "Enter nickname (3-20 characters)",
    "nicknameError": "Nickname must be 3-20 characters",
    "continueLabel": "Continue",
    "createGroup": "Create Group",
    "joinGroup": "Join Group",
    "groupName": "Group Name",
    "groupPin": "Group PIN (optional)",
    "nearbyGroups": "Nearby Groups",
    "noNearbyGroups": "No groups found. Create one or wait.",
    "send": "Send",
    "sendLocation": "Send My Location",
    "sendLocationConfirm": "Send your current coordinates now?",
    "locationPingLabel": "Location",
    "openInMaps": "Open in Maps",
    "memberCount": "{count} member(s)",
    "@memberCount": { "placeholders": { "count": { "type": "int" } } },
    "messageSent": "Sent",
    "messageDelivered": "Delivered",
    "lowBatteryMode": "Power Saver Active",
    "permissionRequired": "Permission Required",
    "permissionExplanation": "NearBuddy needs Bluetooth and Location permissions to discover nearby devices.",
    "grantPermission": "Grant Permission",
    "nicknameInUse": "Nickname already taken. Please choose another.",
    "settings": "Settings",
    "language": "Language",
    "changeNickname": "Change Nickname",
    "leaveGroup": "Leave Group",
    "members": "Members"
  }
  ```

- [x] **Step 5: Run flutter gen-l10n**
  ```bash
  flutter gen-l10n
  ```
  Expected: `lib/l10n/app_localizations.dart` (+ `_id.dart`, `_en.dart`) generated. NOTE: Flutter 3.44 removed `synthetic-package` — generated files land in `arb-dir` and are imported via `import 'l10n/app_localizations.dart';` (NOT `package:flutter_gen/...`).

- [x] **Step 6: Build verify**
  ```bash
  flutter build apk --debug
  ```
  Expected: BUILD SUCCESSFUL

- [x] **Step 7: Commit**
  ```bash
  git add . && git commit -m "feat: i18n (ID/EN ARBs), AppPreferences, PermissionHandlerService"
  ```

---

## Task 4: Onboarding Screens (Disclaimer + Nickname)

**Files:**
- Create: `lib/features/onboarding/disclaimer_screen.dart`
- Create: `lib/features/onboarding/nickname_screen.dart`
- Modify: `lib/core/router.dart` (add all routes + redirect logic)
- Create: `test/features/onboarding/disclaimer_screen_test.dart`

**Interfaces:**
- Consumes: `appPreferencesProvider`, `AppLocalizations`, `go_router`
- Produces: GoRouter routes `/disclaimer`, `/nickname`, `/home`; redirect: no-disclaimer → `/disclaimer`; no-nickname → `/nickname`; else → `/home`

**Status: DONE (2026-08-07)** — test passes, analyze clean, full suite 4/4, commit `04548bb`. Deviations per UI Policy: screens use shadcn widgets — `ShadButton`, `ShadInputFormField` (validator + `AutovalidateMode.always`; shadcn 0.56 has NO `onFieldSubmitted` and uses Flutter's `AutovalidateMode`, not `ShadAutovalidateMode`), `LucideIcons.triangleAlert`, `ShadTheme.of(context).textTheme.h2/p` (non-nullable — no `?.`). Nickname screen uses `ShadForm` + `formKey` (saveAndValidate → prefs → `/home`) instead of a manual controller.

- [x] **Step 1: Write failing test**
  Create `test/features/onboarding/disclaimer_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:shadcn_ui/shadcn_ui.dart';
  import 'package:nearbuddy/data/preferences/app_preferences.dart';
  import 'package:nearbuddy/main.dart';
  import 'package:nearbuddy/features/onboarding/disclaimer_screen.dart';

  Future<AppPreferences> mockPrefs({bool accepted = false}) async {
    SharedPreferences.setMockInitialValues({'hasAcceptedDisclaimer': accepted});
    return AppPreferences.create();
  }

  // Must use ShadApp (not MaterialApp) so ShadTheme is available to shadcn widgets.
  Widget wrap(Widget child, AppPreferences prefs) => ProviderScope(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
    child: ShadApp(
      theme: const ShadThemeData(
        brightness: Brightness.light,
        colorScheme: ShadGreenColorScheme.light(),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('id')],
      home: child,
    ),
  );

  void main() {
    testWidgets('DisclaimerScreen shows title and accept button', (tester) async {
      final prefs = await mockPrefs();
      await tester.pumpWidget(wrap(const DisclaimerScreen(), prefs));
      await tester.pumpAndSettle();
      expect(find.text('Pemberitahuan Penting'), findsOneWidget);
      expect(find.text('Saya Mengerti'), findsOneWidget);
    });
  }
  ```
  Run: `flutter test test/features/onboarding/disclaimer_screen_test.dart`
  Expected: FAIL (DisclaimerScreen not found)

- [x] **Step 2: Create lib/features/onboarding/disclaimer_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import 'package:go_router/go_router.dart';
  import '../../main.dart';

  class DisclaimerScreen extends ConsumerWidget {
    const DisclaimerScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final l10n = AppLocalizations.of(context)!;
      final prefs = ref.read(appPreferencesProvider);
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 72, color: Color(0xFFF5A623)),
                const SizedBox(height: 24),
                Text(l10n.disclaimerTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(l10n.disclaimerBody,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () async {
                    await prefs.acceptDisclaimer();
                    if (context.mounted) context.go('/nickname');
                  },
                  child: Text(l10n.disclaimerAccept),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
  ```

- [x] **Step 3: Create lib/features/onboarding/nickname_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import 'package:go_router/go_router.dart';
  import '../../core/constants.dart';
  import '../../main.dart';

  class NicknameScreen extends ConsumerStatefulWidget {
    const NicknameScreen({super.key});
    @override
    ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
  }

  class _NicknameScreenState extends ConsumerState<NicknameScreen> {
    final _ctrl = TextEditingController();
    String? _error;

    @override
    void dispose() { _ctrl.dispose(); super.dispose(); }

    Future<void> _submit() async {
      final val = _ctrl.text.trim();
      final l10n = AppLocalizations.of(context)!;
      if (val.length < AppConstants.nicknameLengthMin ||
          val.length > AppConstants.nicknameLengthMax) {
        setState(() => _error = l10n.nicknameError);
        return;
      }
      await ref.read(appPreferencesProvider).setNickname(val);
      if (mounted) context.go('/home');
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.nicknameTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _ctrl,
                  maxLength: AppConstants.nicknameLengthMax,
                  decoration: InputDecoration(
                      hintText: l10n.nicknameHint,
                      errorText: _error,
                      border: const OutlineInputBorder()),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _submit, child: Text(l10n.continueLabel)),
              ],
            ),
          ),
        ),
      );
    }
  }
  ```

- [x] **Step 4: Update lib/core/router.dart with all routes + redirect**
  ```dart
  import 'package:go_router/go_router.dart';
  import 'package:flutter/material.dart';
  import '../features/onboarding/disclaimer_screen.dart';
  import '../features/onboarding/nickname_screen.dart';

  late final GoRouter appRouter;

  GoRouter buildRouter(dynamic prefs) => GoRouter(
    initialLocation: _initialRoute(prefs),
    routes: [
      GoRoute(path: '/disclaimer', builder: (_, __) => const DisclaimerScreen()),
      GoRoute(path: '/nickname',   builder: (_, __) => const NicknameScreen()),
      // Stub routes — replaced with real widgets in Tasks 6-9:
      GoRoute(path: '/home',         builder: (_, __) => const Scaffold(body: Center(child: Text('Home')))),
      GoRoute(path: '/chat/:groupId', builder: (_, s) => Scaffold(body: Center(child: Text('Chat: ${s.pathParameters["groupId"]}')))),
      GoRoute(path: '/settings',     builder: (_, __) => const Scaffold(body: Center(child: Text('Settings')))),
      GoRoute(path: '/create-group', builder: (_, __) => const Scaffold(body: Center(child: Text('Create Group')))),
    ],
  );

  String _initialRoute(dynamic prefs) {
    if (!prefs.hasAcceptedDisclaimer) return '/disclaimer';
    if (prefs.nickname == null) return '/nickname';
    return '/home';
  }
  ```

- [x] **Step 5: Run disclaimer test — expect PASS**
  ```bash
  flutter test test/features/onboarding/disclaimer_screen_test.dart -v
  ```

- [x] **Step 6: Commit**
  ```bash
  git add . && git commit -m "feat: onboarding — disclaimer and nickname screens with GoRouter redirect"
  ```

---

## Task 5: PeerDiscoveryService + NearbyConnectionsService + BatteryMonitor

**Files:**
- Create: `lib/core/utils/uuid_generator.dart`
- Create: `lib/core/utils/battery_monitor.dart` (with Riverpod providers)
- Create: `lib/domain/services/peer_discovery_service.dart`
- Create: `lib/infrastructure/nearby/nearby_connections_service.dart`
- Create: `test/domain/services/relay_dedup_test.dart`

**Interfaces:**
- Produces:
  - `UuidGenerator.generate()` → `String` (UUID v4)
  - `BatteryMonitor.batteryLevelStream` → `Stream<int>`, `isLowBattery()` → `Future<bool>`
  - `batteryMonitorProvider`, `lowBatteryProvider` (Riverpod)
  - `PeerDiscoveryService` abstract class with 6 members
  - `NearbyConnectionsService` implements `PeerDiscoveryService`
  - `peerDiscoveryServiceProvider` (Riverpod)

**Status: DONE (2026-08-07)** — relay dedup 3/3 PASS, analyze clean, full suite 7/7, commit `206903b`. Deviations: (1) `svcId` uses `AppConfig.nearbyServiceId(groupId)` (flavor-aware, per Task 10 update); (2) lint fixes vs snippet: `static const _uuid = Uuid();`, braces on single-statement `if`/`for` in `NearbyConnectionsService` (`curly_braces_in_flow_control_structures`, `prefer_const_declarations`). Verified `nearby_connections` 4.3.0 API matches snippet (typedefs `OnConnectionInitiated`/`OnConnectionResult`/`OnDisconnected`, `Payload.bytes`, `Status.CONNECTED`).

- [x] **Step 1: Create uuid_generator.dart**
  ```dart
  import 'package:uuid/uuid.dart';
  class UuidGenerator {
    static final _uuid = Uuid();
    static String generate() => _uuid.v4();
  }
  ```

- [x] **Step 2: Create battery_monitor.dart**
  ```dart
  import 'package:battery_plus/battery_plus.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../constants.dart';

  class BatteryMonitor {
    final _battery = Battery();

    Stream<int> get batteryLevelStream async* {
      while (true) {
        yield await _battery.batteryLevel;
        await Future.delayed(const Duration(seconds: 30));
      }
    }

    Future<bool> isLowBattery() async =>
        (await _battery.batteryLevel) <= AppConstants.lowBatteryThresholdPercent;
  }

  final batteryMonitorProvider = Provider<BatteryMonitor>((_) => BatteryMonitor());

  final lowBatteryProvider = StreamProvider<bool>((ref) =>
      ref.watch(batteryMonitorProvider).batteryLevelStream
          .map((l) => l <= AppConstants.lowBatteryThresholdPercent));
  ```

- [x] **Step 3: Create peer_discovery_service.dart**
  ```dart
  /// Abstract interface for peer-to-peer discovery and messaging.
  /// Concrete implementation: NearbyConnectionsService.
  abstract class PeerDiscoveryService {
    Future<void> startSession({
      required String groupId,
      required String nickname,
      String? pin,
    });
    Future<void> stopSession();
    Future<Set<String>> sendToAll(String jsonPayload);
    Future<void> sendTo(String endpointId, String jsonPayload);
    Stream<({String endpointId, String nickname})> get onPeerConnected;
    Stream<String> get onPeerDisconnected;
    Stream<({String fromEndpointId, String payload})> get onPayloadReceived;
    Stream<Set<String>> get connectedPeersStream;
  }
  ```

- [x] **Step 4: Create nearby_connections_service.dart**
  ```dart
  import 'dart:async';
  import 'dart:convert';
  import 'package:nearby_connections/nearby_connections.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../core/app_config.dart';
  import '../../domain/services/peer_discovery_service.dart';

  class NearbyConnectionsService implements PeerDiscoveryService {
    final _nearby = Nearby();
    final _peers = <String>{};
    final _names = <String, String>{};
    final _connCtrl =
        StreamController<({String endpointId, String nickname})>.broadcast();
    final _discCtrl = StreamController<String>.broadcast();
    final _plCtrl =
        StreamController<({String fromEndpointId, String payload})>.broadcast();
    final _peersCtrl = StreamController<Set<String>>.broadcast();

    @override Stream<({String endpointId, String nickname})> get onPeerConnected => _connCtrl.stream;
    @override Stream<String> get onPeerDisconnected => _discCtrl.stream;
    @override Stream<({String fromEndpointId, String payload})> get onPayloadReceived => _plCtrl.stream;
    @override Stream<Set<String>> get connectedPeersStream => _peersCtrl.stream;

    void _add(String eid, String name) {
      _peers.add(eid); _names[eid] = name;
      _connCtrl.add((endpointId: eid, nickname: name));
      _peersCtrl.add(Set.from(_peers));
    }

    void _remove(String eid) {
      _peers.remove(eid); _names.remove(eid);
      _discCtrl.add(eid);
      _peersCtrl.add(Set.from(_peers));
    }

    void _onPayload(String eid, Payload p) {
      if (p.type == PayloadType.BYTES)
        _plCtrl.add((fromEndpointId: eid, payload: String.fromCharCodes(p.bytes!)));
    }

    @override
    Future<void> startSession({required String groupId, required String nickname, String? pin}) async {
      final svcId = AppConfig.nearbyServiceId(groupId);
      final adName = (pin != null && pin.isNotEmpty) ? '$nickname|$pin' : nickname;

      await _nearby.startAdvertising(adName, Strategy.P2P_CLUSTER,
        onConnectionInitiated: (eid, info) async {
          if (pin != null && pin.isNotEmpty && !info.endpointName.endsWith('|$pin')) {
            await _nearby.rejectConnection(eid); return;
          }
          _names[eid] = info.endpointName.contains('|')
              ? info.endpointName.split('|').first : info.endpointName;
          await _nearby.acceptConnection(eid,
              onPayLoadRecieved: _onPayload, onPayloadTransferUpdate: (_, __) {});
        },
        onConnectionResult: (eid, status) { if (status == Status.CONNECTED) _add(eid, _names[eid] ?? eid); },
        onDisconnected: _remove,
        serviceId: svcId,
      );

      await _nearby.startDiscovery(adName, Strategy.P2P_CLUSTER,
        onEndpointFound: (eid, endpointName, _) {
          final peerName = endpointName.contains('|') ? endpointName.split('|').first : endpointName;
          _names[eid] = peerName;
          _nearby.requestConnection(adName, eid,
            onConnectionInitiated: (eid2, _) async =>
                _nearby.acceptConnection(eid2,
                    onPayLoadRecieved: _onPayload, onPayloadTransferUpdate: (_, __) {}),
            onConnectionResult: (eid2, status) { if (status == Status.CONNECTED) _add(eid2, _names[eid2] ?? eid2); },
            onDisconnected: _remove,
          );
        },
        onEndpointLost: (_) {},
        serviceId: svcId,
      );
    }

    @override
    Future<void> stopSession() async {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      await _nearby.stopAllEndpoints();
      _peers.clear(); _names.clear();
    }

    @override
    Future<Set<String>> sendToAll(String payload) async {
      final b = utf8.encode(payload);
      for (final eid in Set.from(_peers)) await _nearby.sendBytesPayload(eid, b);
      return Set.from(_peers);
    }

    @override
    Future<void> sendTo(String eid, String payload) =>
        _nearby.sendBytesPayload(eid, utf8.encode(payload));

    void dispose() {
      _connCtrl.close(); _discCtrl.close(); _plCtrl.close(); _peersCtrl.close();
    }
  }

  final peerDiscoveryServiceProvider = Provider<PeerDiscoveryService>((ref) {
    final s = NearbyConnectionsService();
    ref.onDispose(s.dispose);
    return s;
  });
  ```

- [x] **Step 5: Write relay dedup test**
  Create `test/domain/services/relay_dedup_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:nearbuddy/core/constants.dart';

  class RelayDeduplicator {
    final _seen = <String, DateTime>{};
    bool shouldRelay(String id) {
      final now = DateTime.now();
      _seen.removeWhere((_, t) =>
          now.difference(t).inSeconds > AppConstants.relayDeduplicationCacheSeconds);
      if (_seen.containsKey(id)) return false;
      _seen[id] = now;
      return true;
    }
  }

  void main() {
    test('first occurrence → relay', () => expect(RelayDeduplicator().shouldRelay('a'), isTrue));
    test('duplicate → skip', () {
      final d = RelayDeduplicator()..shouldRelay('a');
      expect(d.shouldRelay('a'), isFalse);
    });
    test('different IDs → both relay', () {
      final d = RelayDeduplicator()..shouldRelay('a');
      expect(d.shouldRelay('b'), isTrue);
    });
  }
  ```

- [x] **Step 6: Run relay dedup tests — expect PASS**
  ```bash
  flutter test test/domain/services/relay_dedup_test.dart -v
  ```

- [x] **Step 7: Commit**
  ```bash
  git add . && git commit -m "feat: PeerDiscoveryService abstraction, NearbyConnectionsService, BatteryMonitor, relay dedup tests"
  ```

---

## Task 6: Home Screen + Group Create/Join

> ⚠️ **Status: SUPERSEDED — do not implement (see v2 Task 11).**

**Files:**
- Create: `lib/domain/models/group_session.dart`
- Create: `lib/features/home/home_screen.dart`
- Create: `lib/features/home/home_controller.dart`
- Create: `lib/features/group/group_controller.dart`
- Create: `lib/features/group/create_group_screen.dart`
- Create: `lib/features/group/join_group_screen.dart`
- Modify: `lib/core/router.dart` (replace stub home/create-group/join-group routes)

**Interfaces:**
- Consumes: `PeerDiscoveryService`, `groupsDaoProvider`, `appPreferencesProvider`
- Produces:
  - `currentGroupProvider` → `StateProvider<GroupSession?>`
  - `groupControllerProvider` → `Provider<GroupController>`
  - `nearbyGroupsProvider` → `StateNotifierProvider<NearbyGroupsNotifier, List<NearbyGroup>>`
  - `NearbyGroup` typedef: `({String endpointId, String groupName, bool hasPin})`

- [ ] **Step 1: Create domain/models/group_session.dart**
  ```dart
  class GroupSession {
    final String id;
    final String name;
    final String? pin;
    final DateTime createdAt;
    final bool isOwner;
    const GroupSession({
      required this.id, required this.name, required this.createdAt,
      this.pin, this.isOwner = false,
    });
  }
  ```

- [ ] **Step 2: Create features/group/group_controller.dart**
  ```dart
  import 'package:drift/drift.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:uuid/uuid.dart';
  import '../../data/database/app_database.dart';
  import '../../data/database/daos/groups_dao.dart';
  import '../../domain/models/group_session.dart';
  import '../../domain/services/peer_discovery_service.dart';
  import '../../data/preferences/app_preferences.dart';
  import '../../infrastructure/nearby/nearby_connections_service.dart';
  import '../../main.dart';

  final currentGroupProvider = StateProvider<GroupSession?>((ref) => null);
  final groupControllerProvider = Provider<GroupController>((ref) => GroupController(ref));

  class GroupController {
    final Ref _ref;
    GroupController(this._ref);

    GroupsDao get _dao => _ref.read(groupsDaoProvider);
    PeerDiscoveryService get _peer => _ref.read(peerDiscoveryServiceProvider);
    AppPreferences get _prefs => _ref.read(appPreferencesProvider);

    Future<void> createGroup({required String name, String? pin}) async {
      final id = const Uuid().v4();
      await _dao.insertGroup(GroupsCompanion.insert(
        id: id, name: name, pin: Value(pin),
        createdAt: DateTime.now(), isOwner: const Value(true),
      ));
      await _peer.startSession(
          groupId: id, nickname: _prefs.nickname ?? 'Unknown', pin: pin);
      _ref.read(currentGroupProvider.notifier).state =
          GroupSession(id: id, name: name, pin: pin, createdAt: DateTime.now(), isOwner: true);
    }

    Future<void> joinGroup({
      required String groupId,
      required String groupName,
      String? pin,
    }) async {
      await _peer.startSession(
          groupId: groupId, nickname: _prefs.nickname ?? 'Unknown', pin: pin);
      await _dao.insertGroup(GroupsCompanion.insert(
        id: groupId, name: groupName, pin: Value(pin), createdAt: DateTime.now(),
      ));
      _ref.read(currentGroupProvider.notifier).state =
          GroupSession(id: groupId, name: groupName, pin: pin, createdAt: DateTime.now());
    }

    Future<void> leaveGroup() async {
      await _peer.stopSession();
      _ref.read(currentGroupProvider.notifier).state = null;
    }
  }
  ```

- [ ] **Step 3: Create features/home/home_controller.dart**
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  typedef NearbyGroup = ({String endpointId, String groupName, bool hasPin});

  final nearbyGroupsProvider =
      StateNotifierProvider<NearbyGroupsNotifier, List<NearbyGroup>>(
          (_) => NearbyGroupsNotifier());

  class NearbyGroupsNotifier extends StateNotifier<List<NearbyGroup>> {
    NearbyGroupsNotifier() : super([]);

    void addGroup(NearbyGroup g) {
      if (!state.any((x) => x.endpointId == g.endpointId))
        state = [...state, g];
    }

    void removeGroup(String endpointId) =>
        state = state.where((g) => g.endpointId != endpointId).toList();

    void clear() => state = [];
  }
  ```

- [ ] **Step 4: Create features/home/home_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import 'package:go_router/go_router.dart';
  import 'home_controller.dart';
  import '../../core/utils/battery_monitor.dart';

  class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final l10n = AppLocalizations.of(context)!;
      final groups = ref.watch(nearbyGroupsProvider);
      final isLow = ref.watch(lowBatteryProvider).valueOrNull ?? false;

      return Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Text(l10n.appName),
            if (isLow) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                child: Text(l10n.lowBatteryMode,
                    style: const TextStyle(fontSize: 11)),
              ),
            ],
          ]),
          actions: [
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings')),
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.nearbyGroups,
                  style: Theme.of(context).textTheme.titleMedium)),
          Expanded(
            child: groups.isEmpty
                ? Center(child: Text(l10n.noNearbyGroups))
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(groups[i].groupName),
                      trailing: groups[i].hasPin
                          ? const Icon(Icons.lock, size: 16)
                          : null,
                      onTap: () => context.push(
                          '/join-group/${groups[i].endpointId}',
                          extra: groups[i]),
                    )),
          ),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/create-group'),
          icon: const Icon(Icons.add),
          label: Text(l10n.createGroup),
        ),
      );
    }
  }
  ```

- [ ] **Step 5: Create features/group/create_group_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import 'package:go_router/go_router.dart';
  import 'group_controller.dart';
  import '../../core/constants.dart';

  class CreateGroupScreen extends ConsumerStatefulWidget {
    const CreateGroupScreen({super.key});
    @override
    ConsumerState<CreateGroupScreen> createState() => _State();
  }

  class _State extends ConsumerState<CreateGroupScreen> {
    final _nameCtrl = TextEditingController();
    final _pinCtrl = TextEditingController();
    bool _usePIN = false, _loading = false;

    @override
    void dispose() { _nameCtrl.dispose(); _pinCtrl.dispose(); super.dispose(); }

    Future<void> _create() async {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) return;
      final pin = (_usePIN && _pinCtrl.text.trim().length >= AppConstants.pinLengthMin)
          ? _pinCtrl.text.trim() : null;
      setState(() => _loading = true);
      await ref.read(groupControllerProvider).createGroup(name: name, pin: pin);
      if (mounted) context.go('/chat/${ref.read(currentGroupProvider)!.id}');
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.createGroup)),
        body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          TextField(controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.groupName,
                  border: const OutlineInputBorder())),
          SwitchListTile(title: Text(l10n.groupPin), value: _usePIN,
              onChanged: (v) => setState(() => _usePIN = v)),
          if (_usePIN)
            TextField(controller: _pinCtrl, keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLengthMax,
                decoration: InputDecoration(labelText: l10n.groupPin,
                    border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          _loading ? const CircularProgressIndicator()
              : FilledButton(onPressed: _create, child: Text(l10n.createGroup)),
        ])),
      );
    }
  }
  ```

- [ ] **Step 6: Create features/group/join_group_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import 'package:go_router/go_router.dart';
  import 'group_controller.dart';
  import 'home_controller.dart';
  import '../../core/constants.dart';
  import '../home/home_controller.dart';

  class JoinGroupScreen extends ConsumerStatefulWidget {
    final NearbyGroup group;
    const JoinGroupScreen({super.key, required this.group});
    @override
    ConsumerState<JoinGroupScreen> createState() => _State();
  }

  class _State extends ConsumerState<JoinGroupScreen> {
    final _pinCtrl = TextEditingController();
    bool _loading = false;

    @override
    void dispose() { _pinCtrl.dispose(); super.dispose(); }

    Future<void> _join() async {
      final pin = widget.group.hasPin ? _pinCtrl.text.trim() : null;
      if (widget.group.hasPin &&
          (pin == null || pin.length < AppConstants.pinLengthMin)) return;
      setState(() => _loading = true);
      await ref.read(groupControllerProvider).joinGroup(
          groupId: widget.group.endpointId,
          groupName: widget.group.groupName,
          pin: pin);
      if (mounted) context.go('/chat/${widget.group.endpointId}');
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.joinGroup)),
        body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text(widget.group.groupName,
              style: Theme.of(context).textTheme.headlineSmall),
          if (widget.group.hasPin) ...[
            const SizedBox(height: 16),
            TextField(controller: _pinCtrl, keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLengthMax,
                decoration: InputDecoration(labelText: l10n.groupPin,
                    border: const OutlineInputBorder())),
          ],
          const SizedBox(height: 24),
          _loading ? const CircularProgressIndicator()
              : FilledButton(onPressed: _join, child: Text(l10n.joinGroup)),
        ])),
      );
    }
  }
  ```

- [ ] **Step 7: Update router.dart with real home/create/join routes**
  Replace stub routes with `HomeScreen`, `CreateGroupScreen`, `JoinGroupScreen`.

- [ ] **Step 8: flutter run --debug — smoke test home → create group → navigate to chat stub**

- [ ] **Step 9: Commit**
  ```bash
  git add . && git commit -m "feat: home screen, group create/join with PIN, GroupController with Riverpod"
  ```

---

## Task 7: Chat Screen + Text Messaging + Multi-Hop Relay

> ⚠️ **Status: SUPERSEDED — do not implement (see v2 Task 12). The wire payload below is the DEAD v1 plaintext format.**

**Files:**
- Create: `lib/domain/models/message.dart`
- Create: `lib/features/chat/chat_controller.dart`
- Create: `lib/features/chat/chat_screen.dart`
- Create: `lib/features/chat/widgets/message_bubble.dart`
- Create: `lib/features/chat/widgets/location_ping_card.dart` (stub — full impl in Task 8)
- Create: `test/features/chat/chat_controller_test.dart`
- Modify: `lib/core/router.dart` (replace chat stub with ChatScreen)

**Interfaces:**
- Consumes: `PeerDiscoveryService.onPayloadReceived`, `MessagesDao`, `appPreferencesProvider`, `currentGroupProvider`
- Produces:
  - `chatControllerProvider` → `Provider<ChatController>`
  - `MessageType` enum: `text`, `location`
  - Wire payload: `{"id":"<uuid>","gid":"<groupId>","sid":"<nickname>","content":"<text>","type":"text"|"location","ts":<epochMs>,"hop":<int>,"max":3,"dlv":[]}`

- [ ] **Step 1: Create domain/models/message.dart**
  ```dart
  enum MessageType { text, location }

  class Message {
    final String id;
    final String groupId;
    final String senderId;
    final String content;
    final MessageType type;
    final DateTime timestamp;
    final int hopCount;
    final List<String> deliveredTo;
    final double? latitude;
    final double? longitude;
    final double? locationAccuracy;

    const Message({
      required this.id, required this.groupId, required this.senderId,
      required this.content, required this.type, required this.timestamp,
      this.hopCount = 0, this.deliveredTo = const [],
      this.latitude, this.longitude, this.locationAccuracy,
    });

    Map<String, dynamic> toWireJson() => {
      'id': id, 'gid': groupId, 'sid': senderId, 'content': content,
      'type': type.name, 'ts': timestamp.millisecondsSinceEpoch,
      'hop': hopCount, 'max': 3, 'dlv': deliveredTo,
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
      if (locationAccuracy != null) 'acc': locationAccuracy,
    };

    factory Message.fromWireJson(Map<String, dynamic> j) => Message(
      id: j['id'] as String, groupId: j['gid'] as String,
      senderId: j['sid'] as String, content: j['content'] as String,
      type: MessageType.values.firstWhere((e) => e.name == j['type']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
      hopCount: (j['hop'] as int?) ?? 0,
      deliveredTo: List<String>.from(j['dlv'] ?? []),
      latitude: (j['lat'] as num?)?.toDouble(),
      longitude: (j['lng'] as num?)?.toDouble(),
      locationAccuracy: (j['acc'] as num?)?.toDouble(),
    );

    Message copyWith({int? hopCount}) => Message(
      id: id, groupId: groupId, senderId: senderId, content: content,
      type: type, timestamp: timestamp, hopCount: hopCount ?? this.hopCount,
      deliveredTo: deliveredTo, latitude: latitude, longitude: longitude,
      locationAccuracy: locationAccuracy,
    );
  }
  ```

- [ ] **Step 2: Write failing test — run before creating ChatController**
  Create `test/features/chat/chat_controller_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:nearbuddy/domain/models/message.dart';

  void main() {
    test('Message roundtrip via toWireJson/fromWireJson', () {
      final m = Message(id: 'x', groupId: 'g', senderId: 'Bimo',
          content: 'Hi', type: MessageType.text,
          timestamp: DateTime.utc(2026, 8, 7, 10), hopCount: 1);
      final r = Message.fromWireJson(m.toWireJson());
      expect(r.id, 'x'); expect(r.hopCount, 1); expect(r.type, MessageType.text);
    });

    test('wire payload has hop, max, dlv keys', () {
      final j = Message(id: 'a', groupId: 'g', senderId: 'A',
          content: 'hi', type: MessageType.text,
          timestamp: DateTime.now()).toWireJson();
      expect(j['hop'], 0); expect(j['max'], 3);
      expect(j.containsKey('dlv'), isTrue);
    });

    test('copyWith increments hopCount, preserves id', () {
      final m = Message(id: 'r', groupId: 'g', senderId: 'A',
          content: 'relay', type: MessageType.text,
          timestamp: DateTime.now(), hopCount: 1);
      final r = m.copyWith(hopCount: 2);
      expect(r.hopCount, 2); expect(r.id, 'r');
    });
  }
  ```
  ```bash
  flutter test test/features/chat/chat_controller_test.dart -v
  ```
  Expected: PASS (message.dart exists from Step 1)

- [ ] **Step 3: Create features/chat/chat_controller.dart**
  ```dart
  import 'dart:async';
  import 'dart:convert';
  import 'package:drift/drift.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../core/constants.dart';
  import '../../core/utils/uuid_generator.dart';
  import '../../data/database/app_database.dart';
  import '../../data/database/daos/messages_dao.dart';
  import '../../data/database/tables/messages_table.dart';
  import '../../domain/models/message.dart';
  import '../../domain/services/peer_discovery_service.dart';
  import '../../data/preferences/app_preferences.dart';
  import '../../infrastructure/nearby/nearby_connections_service.dart';
  import '../../main.dart';
  import '../group/group_controller.dart';

  final chatControllerProvider =
      Provider<ChatController>((ref) => ChatController(ref));

  class ChatController {
    final Ref _ref;
    final _seen = <String, DateTime>{};
    StreamSubscription? _sub;

    ChatController(this._ref) {
      _listenToIncoming();
      Future.microtask(deleteOldMessages);
    }

    MessagesDao get _dao => _ref.read(messagesDaoProvider);
    PeerDiscoveryService get _peer => _ref.read(peerDiscoveryServiceProvider);
    AppPreferences get _prefs => _ref.read(appPreferencesProvider);
    String? get _gid => _ref.read(currentGroupProvider)?.id;

    Stream<List<MessageRow>> watchMessages(String groupId) =>
        _dao.watchMessages(groupId);

    void _listenToIncoming() {
      _sub = _peer.onPayloadReceived.listen((e) async {
        try {
          final msg = Message.fromWireJson(jsonDecode(e.payload));
          if (msg.groupId != _gid) return;
          if (!_dedup(msg.id)) return;
          await _persist(msg);
          final age = DateTime.now().difference(msg.timestamp).inSeconds;
          if (msg.hopCount < AppConstants.maxHops &&
              age < AppConstants.relayTtlSeconds) {
            await _peer.sendToAll(
                jsonEncode(msg.copyWith(hopCount: msg.hopCount + 1).toWireJson()));
          }
        } catch (_) {}
      });
    }

    bool _dedup(String id) {
      final now = DateTime.now();
      _seen.removeWhere((_, t) => now.difference(t).inSeconds >
          AppConstants.relayDeduplicationCacheSeconds);
      if (_seen.containsKey(id)) return false;
      _seen[id] = now;
      return true;
    }

    Future<void> sendTextMessage(String content) async {
      if (_gid == null) return;
      final msg = Message(
        id: UuidGenerator.generate(), groupId: _gid!,
        senderId: _prefs.nickname ?? 'Unknown',
        content: content, type: MessageType.text, timestamp: DateTime.now(),
      );
      await _persist(msg);
      _dedup(msg.id);
      await _peer.sendToAll(jsonEncode(msg.toWireJson()));
    }

    Future<void> _persist(Message msg) => _dao.insertMessage(MessagesCompanion.insert(
      id: msg.id, groupId: msg.groupId, senderId: msg.senderId,
      content: msg.content, type: msg.type.name, timestamp: msg.timestamp,
      hopCount: Value(msg.hopCount),
      latitude: Value(msg.latitude), longitude: Value(msg.longitude),
      locationAccuracy: Value(msg.locationAccuracy),
    ));

    Future<void> deleteOldMessages() => _dao.deleteOlderThan(
        DateTime.now().subtract(Duration(days: AppConstants.messageRetentionDays)));

    void dispose() => _sub?.cancel();
  }
  ```

- [ ] **Step 4: Create features/chat/widgets/message_bubble.dart**
  ```dart
  import 'package:flutter/material.dart';
  import '../../../data/database/tables/messages_table.dart';
  import 'location_ping_card.dart';

  class MessageBubble extends StatelessWidget {
    final MessageRow row;
    final bool isMe;
    const MessageBubble({super.key, required this.row, required this.isMe});

    @override
    Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? cs.primary : cs.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isMe)
              Text(row.senderId, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
            if (row.type == 'location' &&
                row.latitude != null && row.longitude != null)
              LocationPingCard(latitude: row.latitude!, longitude: row.longitude!)
            else
              Text(row.content,
                  style: TextStyle(color: isMe ? cs.onPrimary : null)),
            Text(_fmt(row.timestamp), style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? cs.onPrimary.withOpacity(0.7)
                    : cs.outline)),
          ]),
        ),
      );
    }

    String _fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  ```

- [ ] **Step 5: Create stub features/chat/widgets/location_ping_card.dart**
  ```dart
  // Stub — full implementation in Task 8
  import 'package:flutter/material.dart';
  class LocationPingCard extends StatelessWidget {
    final double latitude, longitude;
    const LocationPingCard({super.key, required this.latitude, required this.longitude});
    @override
    Widget build(BuildContext context) => Text('$latitude, $longitude',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12));
  }
  ```

- [ ] **Step 6: Create features/chat/chat_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import '../../data/database/tables/messages_table.dart';
  import '../../main.dart';
  import 'chat_controller.dart';
  import 'widgets/message_bubble.dart';
  import '../group/group_controller.dart';

  class ChatScreen extends ConsumerStatefulWidget {
    final String groupId;
    const ChatScreen({super.key, required this.groupId});
    @override
    ConsumerState<ChatScreen> createState() => _ChatScreenState();
  }

  class _ChatScreenState extends ConsumerState<ChatScreen> {
    final _msgCtrl = TextEditingController();
    final _scrollCtrl = ScrollController();

    @override
    void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

    void _scrollToBottom() {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      final group = ref.watch(currentGroupProvider);
      final controller = ref.read(chatControllerProvider);
      final myNick = ref.read(appPreferencesProvider).nickname ?? '';

      return Scaffold(
        appBar: AppBar(
          title: Text(group?.name ?? ''),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(groupControllerProvider).leaveGroup();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: StreamBuilder<List<MessageRow>>(
              stream: controller.watchMessages(widget.groupId),
              builder: (ctx, snap) {
                final msgs = snap.data ?? [];
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => MessageBubble(
                      row: msgs[i], isMe: msgs[i].senderId == myNick),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.location_pin),
                  tooltip: l10n.sendLocation,
                  onPressed: () => _sendLocationPing(controller),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLength: 500, maxLines: null,
                    decoration: InputDecoration(
                        hintText: l10n.send,
                        border: const OutlineInputBorder(),
                        counterText: ''),
                    onSubmitted: (_) => _sendText(controller),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendText(controller)),
              ]),
            ),
          ),
        ]),
      );
    }

    Future<void> _sendText(ChatController c) async {
      final text = _msgCtrl.text.trim();
      if (text.isEmpty) return;
      _msgCtrl.clear();
      await c.sendTextMessage(text);
    }

    Future<void> _sendLocationPing(ChatController c) async {
      // Implemented in Task 8
    }
  }
  ```

- [ ] **Step 7: Update router.dart chat route to use ChatScreen**

- [ ] **Step 8: Run chat tests — expect PASS**
  ```bash
  flutter test test/features/chat/chat_controller_test.dart -v
  ```

- [ ] **Step 9: Commit**
  ```bash
  git add . && git commit -m "feat: chat screen with StreamBuilder, ChatController multi-hop relay (3 hops, 10s TTL, UUID dedup)"
  ```

---

## Task 8: Location Ping

> ⚠️ **Status: SUPERSEDED — do not implement (see v2 Task 14).**

**Files:**
- Replace: `lib/features/chat/widgets/location_ping_card.dart` (full implementation)
- Modify: `lib/features/chat/chat_controller.dart` (add `sendLocationPing`)
- Modify: `lib/features/chat/chat_screen.dart` (wire `_sendLocationPing`)

**Interfaces:**
- Consumes: `geolocator`, `PermissionHandlerService`, existing `ChatController._persist`
- Produces: `ChatController.sendLocationPing()` → `Future<String?>` (null = success, non-null = error message)

- [ ] **Step 1: Replace location_ping_card.dart with full implementation**
  ```dart
  import 'package:flutter/material.dart';
  import 'l10n/app_localizations.dart';
  import 'package:url_launcher/url_launcher.dart';

  class LocationPingCard extends StatelessWidget {
    final double latitude;
    final double longitude;
    const LocationPingCard(
        {super.key, required this.latitude, required this.longitude});

    Future<void> _openMaps() async {
      final uri = Uri.parse(
          'https://maps.google.com/maps?q=$latitude,$longitude');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_pin, color: Colors.red, size: 18),
          const SizedBox(width: 4),
          Text(l10n.locationPingLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        Text(
          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        TextButton.icon(
          onPressed: _openMaps,
          icon: const Icon(Icons.map_outlined, size: 16),
          label: Text(l10n.openInMaps),
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
      ]);
    }
  }
  ```

- [ ] **Step 2: Add sendLocationPing to ChatController**

  Add the following imports to `chat_controller.dart`:
  ```dart
  import 'package:geolocator/geolocator.dart';
  import '../../core/utils/permission_handler_service.dart';
  ```

  Add method inside `ChatController` class:
  ```dart
  Future<String?> sendLocationPing() async {
    if (_gid == null) return 'No active group';
    final ok = await _ref
        .read(permissionHandlerServiceProvider)
        .requestLocationPermission();
    if (!ok) return 'Location permission denied';
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10)));
      final msg = Message(
        id: UuidGenerator.generate(),
        groupId: _gid!,
        senderId: _prefs.nickname ?? 'Unknown',
        content: '${pos.latitude},${pos.longitude}',
        type: MessageType.location,
        timestamp: DateTime.now(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        locationAccuracy: pos.accuracy,
      );
      await _persist(msg);
      _dedup(msg.id);
      await _peer.sendToAll(jsonEncode(msg.toWireJson()));
      return null;
    } catch (e) {
      return 'GPS error: $e';
    }
  }
  ```

- [ ] **Step 3: Wire _sendLocationPing in ChatScreen**

  Replace the stub `_sendLocationPing` in `chat_screen.dart`:
  ```dart
  Future<void> _sendLocationPing(ChatController c) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sendLocation),
        content: Text(l10n.sendLocationConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.sendLocation)),
        ],
      ),
    );
    if (ok != true) return;
    final err = await c.sendLocationPing();
    if (mounted && err != null)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
  }
  ```

- [ ] **Step 4: Smoke test on emulator**

  Run app → create group → chat screen → tap 📍 pin → accept dialog.
  Expected: Location card appears with `lat, lng` and "Buka di Maps" button.
  Tap "Buka di Maps" → browser/Maps opens with coordinates.

- [ ] **Step 5: Commit**
  ```bash
  git add . && git commit -m "feat: location ping — GPS capture, LocationPingCard with Open in Maps deep link"
  ```

---

## Task 9: Settings Screen + Final Wiring

> ⚠️ **Status: SUPERSEDED — do not implement (see v2 Task 15, settings part).**

**Files:**
- Create: `lib/features/settings/settings_screen.dart`
- Modify: `lib/core/router.dart` (replace settings stub with SettingsScreen)

**Interfaces:**
- Consumes: `appPreferencesProvider`, `localeProvider`, `lowBatteryProvider`
- Produces: Settings screen with language dropdown (ID/EN) and nickname edit field

- [ ] **Step 1: Create lib/features/settings/settings_screen.dart**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'l10n/app_localizations.dart';
  import '../../core/constants.dart';
  import '../../main.dart';

  class SettingsScreen extends ConsumerStatefulWidget {
    const SettingsScreen({super.key});
    @override
    ConsumerState<SettingsScreen> createState() => _State();
  }

  class _State extends ConsumerState<SettingsScreen> {
    late TextEditingController _ctrl;
    @override
    void initState() {
      super.initState();
      _ctrl = TextEditingController(
          text: ref.read(appPreferencesProvider).nickname);
    }
    @override
    void dispose() { _ctrl.dispose(); super.dispose(); }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      final prefs = ref.read(appPreferencesProvider);
      final locale = ref.watch(localeProvider);

      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: ListView(children: [
          ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (code) async {
                if (code == null) return;
                await prefs.setLanguageCode(code);
                ref.read(localeProvider.notifier).state = Locale(code);
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.changeNickname,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                maxLength: AppConstants.nicknameLengthMax,
                decoration: InputDecoration(
                    hintText: l10n.nicknameHint,
                    border: const OutlineInputBorder()),
              ),
              FilledButton(
                onPressed: () async {
                  final v = _ctrl.text.trim();
                  if (v.length < AppConstants.nicknameLengthMin) return;
                  await prefs.setNickname(v);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nickname updated')));
                },
                child: Text(l10n.continueLabel),
              ),
            ]),
          ),
        ]),
      );
    }
  }
  ```

- [ ] **Step 2: Update router.dart settings route with real SettingsScreen**

- [ ] **Step 3: Run full test suite**
  ```bash
  flutter test -v
  ```
  Expected: All tests PASS (messages_dao_test, relay_dedup_test, disclaimer_screen_test, chat_controller_test)

- [ ] **Step 4: End-to-end smoke test checklist**
  - [ ] Disclaimer screen on first launch; "Saya Mengerti" advances to nickname screen
  - [ ] Nickname screen saves name; advances to home screen
  - [ ] Low-battery badge visible in AppBar when battery < 20% (test with emulator battery level)
  - [ ] Create Group → chat screen opens
  - [ ] Type text → send → message bubble appears
  - [ ] Tap 📍 → confirm dialog → location card with coordinates + "Buka di Maps"
  - [ ] Tap "Buka di Maps" → maps app/browser opens
  - [ ] Settings → language dropdown switches between ID and EN
  - [ ] Settings → nickname change persists after app restart

- [ ] **Step 5: Final commit**
  ```bash
  git add . && git commit -m "feat: settings screen (language toggle, nickname), full MVP feature-complete"
  ```

---

## Task 10: Build Flavors (dev + prod)

> ⚠️ **Status: SUPERSEDED — do not implement (see v2 Task 15, flavors part).**

**Files:**
- Modify: `android/app/build.gradle.kts` (flavorDimensions + productFlavors)
- Modify: `android/app/src/main/AndroidManifest.xml` (label → `@string/app_name`)
- Create: `lib/core/app_config.dart` (AppConfig — reads `FLAVOR` dart-define)
- Create: `scripts/flavor.ps1` (wrapper script)

**Context:** Added after Task 9 per product decision. Tasks 2/5 snippets already reference `AppConfig` (db name, service ID) — this task creates the class they use. **Once `productFlavors` exists, plain `flutter run` / `flutter build` without `--flavor` FAILS** — always use `scripts/flavor.ps1`.

**Interfaces:**
- Produces: `AppConfig.{flavor, isDev, databaseName, nearbyServiceId(groupId)}` — compile-time constants from `String.fromEnvironment('FLAVOR', defaultValue: 'prod')`
- dev: applicationId `com.nearbuddy.nearbuddy.dev`, label "NearBuddy Dev", DB `nearbuddy_db_dev`, service ID `com.nearbuddy.dev.<gid>`
- prod: applicationId `com.nearbuddy.nearbuddy`, label "NearBuddy", DB `nearbuddy_db`, service ID `com.nearbuddy.<gid>`

- [ ] **Step 1: Add productFlavors to android/app/build.gradle.kts**

  Inside `android { ... }` block (after `buildTypes`):
  ```kotlin
  flavorDimensions += "env"
  productFlavors {
      create("dev") {
          dimension = "env"
          applicationIdSuffix = ".dev"
          resValue("string", "app_name", "NearBuddy Dev")
      }
      create("prod") {
          dimension = "env"
          resValue("string", "app_name", "NearBuddy")
      }
  }
  ```

- [ ] **Step 2: Use the flavor resource for the app label in AndroidManifest.xml**

  Replace `android:label="nearbuddy"` with `android:label="@string/app_name"` (the `resValue` from Step 1 resolves per flavor).

- [ ] **Step 3: Create lib/core/app_config.dart**
  ```dart
  /// Compile-time build flavor config. Set via --dart-define=FLAVOR=dev|prod.
  abstract final class AppConfig {
    static const String flavor =
        String.fromEnvironment('FLAVOR', defaultValue: 'prod');
    static const bool isDev = flavor == 'dev';
    static const String databaseName = isDev ? 'nearbuddy_db_dev' : 'nearbuddy_db';

    /// Nearby service ID — dev and prod builds must not discover each other.
    static String nearbyServiceId(String groupId) =>
        isDev ? 'com.nearbuddy.dev.$groupId' : 'com.nearbuddy.$groupId';
  }
  ```

- [ ] **Step 4: Create scripts/flavor.ps1**
  ```powershell
  param(
    [ValidateSet('dev','prod')][string]$Flavor = 'dev',
    [ValidateSet('run','build')][string]$Action = 'run'
  )
  $ErrorActionPreference = 'Stop'
  switch ($Action) {
    'run'   { flutter run --flavor $Flavor --dart-define=FLAVOR=$Flavor }
    'build' { flutter build apk --debug --flavor $Flavor --dart-define=FLAVOR=$Flavor }
  }
  ```
  Usage: `.\scripts\flavor.ps1 -Flavor dev -Action build` (default: dev + run).

- [ ] **Step 5: Verify both flavors build**
  ```bash
  .\scripts\flavor.ps1 -Flavor dev -Action build
  .\scripts\flavor.ps1 -Flavor prod -Action build
  ```
  Expected: both BUILD SUCCESSFUL; dev APK has applicationId suffix `.dev` and label "NearBuddy Dev". Also confirm `flutter build apk --debug` WITHOUT `--flavor` now errors (expected — this is the new baseline).

- [ ] **Step 6: Commit**
  ```bash
  git add . && git commit -m "feat: build flavors dev/prod — productFlavors, AppConfig (db name, service ID), flavor script"
  ```

---

## Spec Coverage Matrix

| PRD Requirement | Task | Status |
|---|---|---|
| FR-01: Device Discovery | T5 | ✅ NearbyConnectionsService P2P_CLUSTER |
| FR-02: Text Messaging | T7 | ✅ ChatController + reactive Drift stream |
| FR-03: Location Ping | T8 | ✅ GPS + LocationPingCard + Open in Maps |
| FR-04: Multi-Hop Relay (flood, 3 hops, 10s TTL) | T7 | ✅ relay in ChatController._listenToIncoming |
| FR-05: Group Mgmt + Onboarding + PIN | T4 + T6 | ✅ Disclaimer, nickname, create/join with PIN |
| FR-06: SOS | — | ✅ Skipped per D-06 (v1.1 scope) |
| D-01: Android-only MVP | T1 | ✅ `--platforms android`, minSdk 23 |
| D-02: Max 30 devices | T1 | ✅ AppConstants.maxGroupSize = 30 |
| D-03: 7-day message retention | T7 | ✅ deleteOldMessages() on controller init |
| D-04: Nickname uniqueness | T2 + T6 | ✅ GroupsDao.isNicknameTaken |
| D-05: No offline map | T8 | ✅ LocationPingCard with coordinates only |
| D-07: Bilingual ID/EN | T3 | ✅ ARB + flutter_localizations + language toggle |
| D-08: Disclaimer once | T4 | ✅ SharedPreferences hasAcceptedDisclaimer |
| D-09: PeerDiscoveryService abstraction | T5 | ✅ Interface + NearbyConnectionsService |
| D-10: FeatureFlags class | T1 | ✅ All false in v1 |
| Drift SQLite persistence | T2 | ✅ Messages/Groups/Members + DAOs |
| UUID relay dedup (30s cache) | T5 + T7 | ✅ _dedup() in ChatController |
| Low-battery badge (< 20%) | T5 + T6 | ✅ lowBatteryProvider + HomeScreen badge |
| Build flavors dev/prod | T10 | ✅ productFlavors + AppConfig (DB, service ID) + scripts/flavor.ps1 |

> ⚠️ **Note:** Actual discovery interval slowdown (3× slower advertising) when `isLowBattery()` is true has the badge in place but the interval change in `NearbyConnectionsService.startSession()` is deferred to M4 polish phase — it requires passing the battery state into the service and hot-restarting advertising. The badge correctly signals the mode to users in MVP.
