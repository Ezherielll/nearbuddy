# NearBuddy — AGENTS.md

Offline-first P2P mesh messenger (Flutter, Android-only) using Google Nearby Connections — general-purpose (not outdoor-specific), 1:1 + group chat, full E2EE. v2 plan Tasks 6–15 DONE (crypto core, schema v2→v3, wire v2, key exchange, group chat, DM, location, settings, flavors) + post-plan UX passes (connection status, discovery, delivery states, theme system). Task 16 (3-device smoke checklist) pending manual testing. Do not `flutter run` without `--flavor` (see Commands).

## Canonical documents (read before coding)

- `NearBuddy_PRD.md` — product spec, in Indonesian. **Section 14 (Decisions Log) supersedes earlier sections** — D-11…D-16 (added 2026-08-07) bring 1:1 chat, E2EE at v1, device-key identity, general-purpose positioning, PIN moved out of the advertisement name.
- `docs/superpowers/plans/2026-08-07-nearbuddy-mvp-v2.md` — the **authoritative implementation plan** (replaces v1 for tasks ≥6). Tasks 6–15 DONE, Task 16 manual. v1 plan is only authoritative for the DONE tasks 1–5 and its Global Constraints/UI Policy (still in force). Post-plan UX refinements are recorded in git history, not the plan — read the code.

## Hard constraints

- Android only; `minSdk 23`, `targetSdk 34`. **No network calls, no Firebase, no cloud, no analytics of any kind.**
- Max hops 3, relay TTL 10s, dedup cache 30s, group max 30, message max 500 chars, retention 7 days.
- Nickname 3–20 chars, unique within group — **display label only; identity is the per-device X25519 key** (private seed in Android Keystore via `flutter_secure_storage`; `deviceId` = first 16 hex of sha256(pubkey)).
- Bilingual ID (default) + EN via ARB files; disclaimer once via `hasAcceptedDisclaimer` in SharedPreferences.
- **E2EE is core, not a flag**: X25519 identity keys + 6-digit SAS verification + AES-GCM payloads. Relay nodes never decrypt — they forward envelopes untouched.
- Do NOT add: `flutter_map`, SOS, voice messaging, cloud, forward secrecy (double ratchet), at-rest encryption (SQLCipher), DM standalone.
- Accepted limitations (do not re-litigate): no forward secrecy, group key is session-scoped in memory (restart = re-key), no rekey on member leave. **Messages are NOT auto-sent later** — pending/failed requires manual retry; do not add UI claiming store-and-forward.
- `PeerDiscoveryService` is the abstract interface; `NearbyConnectionsService` is the concrete impl — business logic must never import `nearby_connections` directly.
- Wire v2 contract (STABLE): `{"v":2,"h":{id,gid,to?,hop,max,ts,k},"n":"<b64 nonce 12B>","c":"<b64 ciphertext||MAC>"}`. Canonical open: `SecretBox.fromConcatenation([...nonce, ...cipherWithMac], nonceLength: 12, macLength: 16)` — `macLength` is REQUIRED in cryptography 2.7.
- Control messages (hop-local, never relayed): `hello` / `verify_ok` / `verify_fail` / `key` / **`ack`** (`{"t":"ack","id":"<msgId>"}` — DM delivery receipt, flooded) / **`typing`** (`{"t":"typing","on":bool,"to":"<deviceId>","gid":"<sessionId>"}` — flooded, filtered by `to`). Old v1 wire JSON is dead — do not send it.
- UI library is `shadcn_ui` (^0.56) + `chat_bubbles` (^1.10.1, presentation-only via `NearBuddyMessageBubble` wrapper). App bootstrap: `ShadApp.custom` + `MaterialApp.router`; widget tests wrap screens in `ShadApp`. Do not introduce another widget library.
- **`ShadButton` pins height via size theme (regular = 40dp)** — large vertical paddings overflow and CLIP labels. Use `NearBuddyButton` (shared CTA: explicit `height: 50`, horizontal-only padding, `DefaultTextStyle.merge` without color so label inherits `primaryForeground`).
- **`ShadDialog` has NO Material ancestor** — `InkWell` inside dialog bodies throws "No Material widget found". Use `GestureDetector(behavior: opaque)` for tappable dialog rows.
- Crypto deps: `cryptography` ^2.7 + `flutter_secure_storage` ^9. `battery_plus` is pinned to ^7.1.1 (built-in Kotlin — the 6.x line triggers the KGP warning and will fail future Flutter builds).
- Semantic theme tokens in `lib/theme/nearbuddy_color_scheme.dart` (`NearBuddyColorScheme` light/dark + `NearBuddyColors` extension with fallbacks for tests). Theme mode comes from `themeModeProvider` (persisted via `AppPreferences.themeMode`).

## Commands

- Generate Drift code: `flutter pub run build_runner build` — **required after any edit to `tables/`, `daos/`, or `app_database.dart`**; never hand-write `.g.dart`. (`--delete-conflicting-outputs` is removed in build_runner 2.15 — omit it.)
- Generate l10n: `flutter gen-l10n` — **required after editing ARB files** in `lib/l10n/`. Flutter 3.44 removed `synthetic-package`; generated files land in `lib/l10n/` and are imported as `import 'l10n/app_localizations.dart';` (never `package:flutter_gen/...`).
- `intl` is pinned to `^0.20.2` by Flutter 3.44 (via `flutter_localizations`) — do not downgrade to ^0.19.
- Single test: `flutter test test/<path>.dart -v`. Full suite: `flutter test -v`. Pure-Dart crypto tests need no device/plugin (KeyManager test uses a fake `KeyValueStore`).
- Run/build MUST use flavors: `.\scripts\flavor.ps1 -Flavor dev -Action run|build` (wraps `--flavor dev --dart-define=FLAVOR=dev`; `prod` also available). NOTE: on this project's AGP 9, plain `flutter run`/`build` still succeeds (no flavor error) — but it builds WITHOUT the `FLAVOR` dart-define, so always use the script to keep `--flavor` and `--dart-define` paired. `flutter test` needs no flavor (AppConfig defaults to `prod`).
- Flavor differences (from `lib/core/app_config.dart`): dev = applicationId `.dev` suffix, label "NearBuddy Dev", DB `nearbuddy_db_dev`, Nearby service ID `com.nearbuddy.dev.<gid>` + scan ID `com.nearbuddy.dev.scan`; prod = clean values. Never hardcode — use `AppConfig.nearbyServiceId(groupId)` / `AppConfig.scanServiceId` / `AppConfig.databaseName`.
- After `flutter clean` is REQUIRED when a plugin major version changes (stale `GeneratedPluginRegistrant.java` references the old class).

## Gotchas

- Drift tests use `AppDatabase.forTesting(NativeDatabase.memory())`; never touch real device DBs in tests. Schema is **version 3** (migration v1→2 adds `messages.to`, `members.publicKey`, `sessions`; v2→3 adds `messages.status` — `'pending'|'sent'|'delivered'|'failed'` for outgoing).
- v2 message model split: `MessageEnvelope` (header + nonce + ciphertext) and `Message` (encrypted payload). `NearBuddyMessageBubble` maps `MessageStatus` → `chat_bubbles` rendering; `MessageBubble` adapts `MessageRow` (grouped = tighter spacing + no tail/avatar).
- Ambient scan: `PeerDiscoveryService.startScan/stopScan/onDeviceFound/onDeviceLost` + `connectedPeers` (sync snapshot). Scan runs only while Home/Devices/Invite screens are visible; `ScanController` start/stop lifecycle. `connectionStatusProvider` derives `ConnectionStatus` (connected/searching/outOfRange/radioOff); `ConnectionBadge.chat` re-maps searching→"Menghubungkan…" (amber) inside conversations.
- **Riverpod lifecycle**: `ref` must not be used after widget disposal. Root causes fixed: SAS challenge subscriptions (`onSasChallenge`) are wired per-screen with `StreamSubscription` + cancel in `dispose`, and every async handler re-checks `if (!mounted) return;` AFTER each `await` before touching `ref`/context. `checkRadioAvailability().then(...)` guards `mounted` too. Do not reintroduce `ref.read` after `await` without a mounted guard, and always cancel `Timer`s/`StreamSubscription`s in `dispose`.
- `FeatureFlags` gates premium features (all `false`) — keep them `false`; E2EE is NOT a flag.
- PRD is written in Indonesian; plan and code identifiers in English. UI strings must come from `AppLocalizations`, never hardcoded.
- Button label contrast: never style a `ShadButton` child with `Theme.of(context).textTheme.p` (dark foreground on blue). Text without explicit color inherits the button's foreground correctly.
- No CI config exists yet; M1 milestone calls for GitHub Actions (lint, test, build APK) — nothing to run locally beyond `flutter analyze`.
- Emulator caveat: the dev AVD once hit a broken PackageManager after reboot (all packages fail activity resolution) — cold-restart the AVD (`emulator -avd Medium_Phone -no-snapshot-load`) to recover. Visual smoke via `uiautomator dump` is text-based (this model cannot read screenshots).
