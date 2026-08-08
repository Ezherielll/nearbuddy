# NearBuddy

Offline-first peer-to-peer mesh messenger for Android — group chat, 1:1 chat, and location pings that work **without internet or cellular signal**, using Google Nearby Connections (Wi-Fi Direct / BLE).

NearBuddy is designed for situations where connectivity fails: festivals, hiking trails, disaster areas. No accounts, no servers, no cloud — every message stays on the devices that carry it.

## Features

- **Group & 1:1 chat** over a peer-to-peer mesh (flood routing, max 3 hops, 10s TTL, UUID dedup)
- **Full E2EE** — per-device X25519 identity keys, 6-digit SAS verification at join, AES-GCM encrypted payloads; relay nodes can never read message content
- **Ambient device discovery** — see nearby NearBuddy devices before joining anything
- **Real-time connection status** everywhere (connected / connecting / searching / out of range), with delivery receipts per message (sent ✓ / delivered ✓✓ / pending / failed + retry)
- **Location pings** with "Open in Maps"
- **Typing indicator** for 1:1 chats
- **Bilingual** Indonesian (default) + English; **light/dark/system theme**

## Architecture

```
Nearby Connections / Wi-Fi Direct
        ↓
  PeerDiscoveryService  (abstract)  ← NearbyConnectionsService (impl)
        ↓
  KeyExchangeService    (X25519 + SAS handshake, group key delivery)
        ↓
  ChatController        (envelope seal/open, relay, ack/typing)
        ↓
  Drift (SQLite)        (schema v3: messages/groups/members/sessions)
        ↓
  Riverpod providers → UI (shadcn_ui + chat_bubbles)
```

- **Wire format v2**: cleartext routing header `{id, gid, to?, hop, max, ts, k}` + AES-GCM payload — relays forward envelopes without decrypting
- **Identity**: one X25519 keypair per device (Keystore via `flutter_secure_storage`); `deviceId` is derived from the public key; nicknames are display labels only
- **State**: Riverpod (providers/notifiers), Drift for persistence, GoRouter for navigation

## Stack

Flutter 3.44 · Dart 3.12 · shadcn_ui ^0.56 · chat_bubbles ^1.10 · drift ^2.31 · flutter_riverpod ^2.5 · cryptography ^2.7 · go_router ^14 · nearby_connections ^4.3

## Commands

```bash
# Run / build — MUST use flavors (plain commands skip the FLAVOR define)
.\scripts\flavor.ps1 -Flavor dev -Action run     # debug run / hot reload
.\scripts\flavor.ps1 -Flavor dev -Action build   # debug APK (large, dev only)
.\scripts\flavor.ps1 -Flavor prod -Action release                # obfuscated release, 3 split APKs (per ABI)
.\scripts\flavor.ps1 -Flavor dev -Action release -Arm64Only      # single android-arm64 release APK (internal)

# Tests
flutter test                                   # full suite
flutter test test/<path>.dart -v               # single test

# Codegen (after editing tables/daos/app_database.dart)
flutter pub run build_runner build
# l10n (after editing lib/l10n/*.arb)
flutter gen-l10n
```

**Release builds** are obfuscated (`--obfuscate`) with symbols saved to `build/symbols/<flavor>` for stack-trace decoding. Debug APKs are huge (~165–230 MB — kernel blob + JIT engine + Vulkan validation layer); release split APKs are ~18–24 MB each (arm64 ≈ 21 MB, within the PRD ≤ 30 MB target).

Flavor differences: `dev` = applicationId `.dev` suffix, label "NearBuddy Dev", DB `nearbuddy_db_dev`, Nearby service IDs under `com.nearbuddy.dev.*`; `prod` = clean values. Dev and prod builds never see each other on the mesh.

## Project structure

```
lib/
├── core/          # constants, feature flags, app config (flavors), router
├── crypto/        # X25519 keys, AES-GCM, HKDF, SAS
├── data/          # Drift schema v3 + DAOs, SharedPreferences wrapper
├── domain/        # models (MessageEnvelope/Message), services (discovery, key exchange)
├── infrastructure/# nearby_connections implementation
├── features/      # onboarding, home (+scan), group, chat (+DM), settings
├── l10n/          # ARB files (id/en) + generated localizations
└── theme/         # NearBuddyColorScheme (light/dark semantic tokens)
```

## Limitations (v1)

- No forward secrecy (static session group key); group key is memory-scoped (restart = re-key)
- No rekey on member leave; at-rest encryption (SQLCipher) deferred
- Pending/failed messages require **manual retry** — no automatic store-and-forward
- DM requires prior group contact (peer public key known)

## Docs

- `NearBuddy_PRD.md` — product spec (Indonesian); Decisions Log §14 supersedes earlier sections
- `docs/superpowers/plans/2026-08-07-nearbuddy-mvp-v2.md` — implementation plan (Tasks 6–15 done; Task 16 = 3-device manual smoke checklist)
