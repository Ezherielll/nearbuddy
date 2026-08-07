# NearBuddy — AGENTS.md

Offline-first P2P mesh messenger (Flutter, Android-only) using Google Nearby Connections — general-purpose (not outdoor-specific), 1:1 + group chat, full E2EE. v2 plan Tasks 6–15 are DONE (crypto core, schema v2, wire v2, key exchange, group chat, DM, location, settings, flavors); Task 16 (3-device smoke checklist) pending manual testing. Do not `flutter run` without `--flavor` (see Commands).

## Canonical documents (read before coding)

- `NearBuddy_PRD.md` — product spec, in Indonesian. **Section 14 (Decisions Log) supersedes earlier sections** — D-11…D-16 (added 2026-08-07) bring 1:1 chat, E2EE at v1, device-key identity, general-purpose positioning, PIN moved out of the advertisement name.
- `docs/superpowers/plans/2026-08-07-nearbuddy-mvp-v2.md` — the **authoritative implementation plan** (replaces v1 for tasks ≥6): crypto core → schema v2 → wire v2 → key exchange → group chat E2EE → DM → location → settings/flavors → smoke checklist. Tasks 6–15 DONE, Task 16 manual. v1 plan (`2026-08-07-nearbuddy-mvp.md`) is only authoritative for the DONE tasks 1–5 and its Global Constraints/UI Policy (still in force). Follow the plan task-by-task (subagent-driven-development or executing-plans workflow); deviate only if forced.

## Hard constraints

- Android only; `minSdk 23`, `targetSdk 34`. **No network calls, no Firebase, no cloud, no analytics of any kind.**
- Max hops 3, relay TTL 10s, dedup cache 30s, group max 30, message max 500 chars, retention 7 days.
- Nickname 3–20 chars, unique within group — **display label only; identity is the per-device X25519 key** (private seed in Android Keystore via `flutter_secure_storage`; `deviceId` = first 16 hex of sha256(pubkey)).
- Bilingual ID (default) + EN via ARB files; disclaimer once via `hasAcceptedDisclaimer` in SharedPreferences.
- **E2EE is core, not a flag**: X25519 identity keys + 6-digit SAS verification + AES-GCM payloads. Relay nodes never decrypt — they forward envelopes (cleartext header `{id, gid, to?, hop, max, ts, k}`) untouched.
- Do NOT add: `flutter_map`, SOS, voice messaging, cloud, forward secrecy (double ratchet), at-rest encryption (SQLCipher), DM standalone — all deferred per plan v2 Risks & Limitations.
- Accepted limitations (do not re-litigate): no forward secrecy, group key is session-scoped in memory (restart = re-key), no rekey on member leave.
- `PeerDiscoveryService` is the abstract interface; `NearbyConnectionsService` is the concrete impl — business logic must never import `nearby_connections` directly.
- Wire v2 contract (STABLE): `{"v":2,"h":{id,gid,to?,hop,max,ts,k},"n":"<b64 nonce 12B>","c":"<b64 ciphertext||MAC>"}`. Canonical open: `SecretBox.fromConcatenation([...nonce, ...cipherWithMac], nonceLength: 12)`. Control messages (`hello`/`verify_ok`/`verify_fail`/`key`) are hop-local, never relayed. Old v1 wire JSON is dead — do not send it.
- UI library is `shadcn_ui` (^0.56) — plan's **UI Policy** section maps Material widgets to `Shad*` equivalents. App bootstrap uses `ShadApp.custom` + `MaterialApp.router`; widget tests wrap screens in `ShadApp`. Do not introduce another widget library.
- Crypto deps: `cryptography` ^2.7 (X25519, AES-GCM, HKDF, SHA-256) + `flutter_secure_storage` ^9. Never hand-roll primitives; keep parameters from v2 Tasks 6/9 unchanged.

## Commands

- Generate Drift code: `flutter pub run build_runner build` — **required after any edit to `tables/`, `daos/`, or `app_database.dart`**; never hand-write `.g.dart`. (`--delete-conflicting-outputs` is removed in build_runner 2.15 — omit it.)
- Generate l10n: `flutter gen-l10n` — **required after editing ARB files** in `lib/l10n/`. Flutter 3.44 removed `synthetic-package`; generated files land in `lib/l10n/` and are imported as `import 'l10n/app_localizations.dart';` (never `package:flutter_gen/...`).
- `intl` is pinned to `^0.20.2` by Flutter 3.44 (via `flutter_localizations`) — do not downgrade to ^0.19.
- Single test: `flutter test test/<path>.dart -v`. Full suite: `flutter test -v`. Pure-Dart crypto tests need no device/plugin (KeyManager test uses a fake `KeyValueStore`).
- Run/build MUST use flavors: `.\scripts\flavor.ps1 -Flavor dev -Action run|build` (wraps `--flavor dev --dart-define=FLAVOR=dev`; `prod` also available). NOTE: on this project's AGP 9, plain `flutter run`/`build` still succeeds (no flavor error) — but it builds WITHOUT the `FLAVOR` dart-define, so always use the script to keep `--flavor` and `--dart-define` paired. `flutter test` needs no flavor (AppConfig defaults to `prod`).
- Flavor differences (from `lib/core/app_config.dart`): dev = applicationId `.dev` suffix, label "NearBuddy Dev", DB `nearbuddy_db_dev`, Nearby service ID `com.nearbuddy.dev.<gid>`; prod = clean values. Never hardcode — use `AppConfig.nearbyServiceId(groupId)` / `AppConfig.databaseName`.

## Gotchas

- Drift tests use `AppDatabase.forTesting(NativeDatabase.memory())`; never touch real device DBs in tests. Schema is version 2 (migration adds `messages.to`, `members.publicKey`, `sessions` table).
- v2 message model split: `MessageEnvelope` (routing header + nonce + ciphertext) and `Message` (encrypted payload only — no id/gid/to). `chat_controller_test.dart` in v2 covers envelope roundtrip + relay decision rules; `crypto_test.dart` + `key_exchange_test.dart` cover the crypto core.
- `FeatureFlags` gates premium features (all `false` in v1) — keep them `false`; E2EE is NOT a flag.
- PRD is written in Indonesian; plan and code identifiers in English. UI strings must come from `AppLocalizations`, never hardcoded.
- No CI config exists yet; M1 milestone calls for GitHub Actions (lint, test, build APK) — nothing to run locally beyond `flutter analyze`.
