# NearBuddy — AGENTS.md

Offline-first P2P group chat app (Flutter, Android-only MVP) using Google Nearby Connections. Tasks 1 done (scaffold + deps + constants + Android config); Tasks 2–10 pending in the plan. Do not `flutter run` without `--flavor` (see Commands).

## Canonical documents (read before coding)

- `NearBuddy_PRD.md` — product spec, in Indonesian. **Section 14 (Decisions Log) supersedes earlier sections** (e.g. no offline map in MVP, SOS deferred to v1.1, Android-only, Drift over Hive, feature flags).
- `docs/superpowers/plans/2026-08-07-nearbuddy-mvp.md` — the authoritative implementation plan: checkbox-tracked tasks (scaffold → DB → i18n → onboarding → discovery → home → chat/relay → location → settings → flavors). Follow it task-by-task; the plan mandates the superpowers `subagent-driven-development` or `executing-plans` workflow. Plan file structure and wire format are the contract — deviate only if forced.

## Hard constraints (from plan's Global Constraints)

- Android only; `minSdk 23`, `targetSdk 34`. **No network calls, no Firebase, no cloud, no analytics of any kind.**
- Max hops 3, relay TTL 10s, dedup cache 30s, group max 30, message max 500 chars, retention 7 days.
- Nickname 3–20 chars, unique within group (validate on join via `GroupsDao.isNicknameTaken`).
- Bilingual ID (default) + EN via ARB files; disclaimer once via `hasAcceptedDisclaimer` in SharedPreferences.
- Do NOT add: `flutter_map`, SOS, voice messaging, encryption.
- `PeerDiscoveryService` is the abstract interface; `NearbyConnectionsService` is the concrete impl — business logic must never import `nearby_connections` directly.
- Message wire JSON: `{id, gid, sid, content, type, ts, hop, max, dlv, lat?, lng?, acc?}` — keep field names stable, they travel over the mesh.
- UI library is `shadcn_ui` (^0.56) — plan's **UI Policy** section maps the Material widgets in task snippets to `Shad*` equivalents (`ShadButton`, `ShadInput`, `ShadDialog`, etc.). App bootstrap uses `ShadApp.custom` + `MaterialApp.router`; widget tests wrap screens in `ShadApp`. Do not introduce another widget library.
- Scaffold command is pinned: `flutter create --org com.nearbuddy --project-name nearbuddy --platforms android .`

## Commands

- Generate Drift code: `flutter pub run build_runner build --delete-conflicting-outputs` — **required after any edit to `tables/`, `daos/`, or `app_database.dart`**; never hand-write `.g.dart`.
- Generate l10n: `flutter gen-l10n` — **required after editing ARB files** in `lib/l10n/`. Flutter 3.44 removed `synthetic-package`; generated files land in `lib/l10n/` and are imported as `import 'l10n/app_localizations.dart';` (never `package:flutter_gen/...`).
- `intl` is pinned to `^0.20.2` by Flutter 3.44 (via `flutter_localizations`) — do not downgrade to ^0.19.
- Single test: `flutter test test/<path>.dart -v` (e.g. `flutter test test/domain/services/relay_dedup_test.dart -v`). Full suite: `flutter test -v`.
- Run/build MUST use flavors: `.\scripts\flavor.ps1 -Flavor dev -Action run|build` (wraps `--flavor dev --dart-define=FLAVOR=dev`; `prod` also available). Plain `flutter run`/`flutter build` **without `--flavor` fails** — productFlavors were added in Task 10. `flutter test` needs no flavor (AppConfig defaults to `prod`).
- Flavor differences (from `lib/core/app_config.dart`): dev = applicationId `.dev` suffix, label "NearBuddy Dev", DB `nearbuddy_db_dev`, Nearby service ID `com.nearbuddy.dev.<gid>`; prod = clean values. Never hardcode `com.nearbuddy.<gid>` or `nearbuddy_db` — use `AppConfig.nearbyServiceId(groupId)` / `AppConfig.databaseName`.
- Task 1 (incl. Step 13 `git init`) is DONE — repo is a git repo on `master`; Task 1 commits exist.

## Gotchas

- Drift tests use `AppDatabase.forTesting(NativeDatabase.memory())`; never touch real device DBs in tests.
- `chat_controller_test.dart` only tests message serialization — real relay/dedup logic is exercised in `relay_dedup_test.dart` (plain Dart class) plus manual multi-device smoke tests.
- `FeatureFlags` gates premium features (all `false` in v1) — keep them `false`.
- PRD is written in Indonesian; plan and code identifiers in English. UI strings must come from `AppLocalizations`, never hardcoded.
- No CI config exists yet; M1 milestone calls for GitHub Actions (lint, test, build APK) — nothing to run locally beyond `flutter analyze`.
