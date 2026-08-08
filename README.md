# NearBuddy

> **Offline-first peer-to-peer mesh messenger for Android.** Group chat, 1:1 chat, and location pings that work **without internet or cellular signal** — powered by Google Nearby Connections (Wi-Fi Direct / BLE).

NearBuddy is built for situations where connectivity fails: festivals, hiking trails, remote areas, or disaster zones. There are **no accounts, no servers, no cloud** — every message stays on the devices that carry it, end-to-end encrypted.

---

## Screenshots

| | | |
|---|---|---|
| ![Home](screenshots/homepage-portrait.png) | ![Chat](screenshots/chat_room-portrait.png) | ![Settings](screenshots/settings-portrait.png) |
| ![About](screenshots/about-portrait.png) | | |

---

## Feature Highlights

### Messaging
- **Group chat (up to 30 members)** and **1:1 direct messages** over a peer-to-peer mesh — flood routing, max **3 hops**, relay **TTL 10 s**, UUID-based dedup (30 s cache)
- **Delivery receipts** per message: `sent ✓` / `delivered ✓✓` / `pending` / `failed` with **manual retry** (no automatic store-and-forward)
- **Typing indicator** for 1:1 chats
- **Location pings** with "Open in Maps" via `url_launcher`
- **In-app emoji picker** — offline curated catalog (5 categories, ~125 emoji), no third-party package, inserts at the cursor position

### Security
- **Full end-to-end encryption (E2EE) as the core, not a flag**:
  - Per-device **X25519** identity keys (private seed in Android Keystore via `flutter_secure_storage`)
  - **6-digit SAS verification** during key exchange (out-of-band compare)
  - **AES-GCM** encrypted payloads — relay nodes only forward envelopes, they **can never decrypt content**
- `deviceId` is derived from the public key (first 16 hex of `sha256(pubkey)`) — stable, unforgeable device identity; nicknames are display labels only

### UX & Reliability
- **Ambient device discovery** — see nearby NearBuddy devices before joining anything (scan runs only while relevant screens are visible to save battery)
- **Real-time connection status** everywhere: connected / connecting / searching / out of range / radio off, with a low-battery power-saver mode
- **Premium theme picker** — bottom sheet with live phone mockups (light / dark / system) drawn entirely with `CustomPaint`
- **Bilingual** — Indonesian (default) + English, runtime switchable
- **Light / dark / system themes** with semantic color tokens; one-time legal disclaimer on first launch

---

## How It Works

```
Nearby Connections (Wi-Fi Direct / BLE)
        ↓
  PeerDiscoveryService   (abstract)  ←  NearbyConnectionsService (impl)
        ↓
  KeyExchangeService     (X25519 + SAS handshake, group key delivery)
        ↓
  ChatController         (envelope seal/open, relay, ack/typing)
        ↓
  Drift (SQLite)         (schema v3: messages / groups / members / sessions)
        ↓
  Riverpod providers  →  UI (shadcn_ui + chat_bubbles)
```

### Wire format v2 (stable)

Every message is an opaque envelope: a **cleartext routing header** plus an **AES-GCM payload** (nonce + ciphertext + MAC). Relays route on the header alone — they never see plaintext.

```json
{
  "v": 2,
  "h": { "id": "<msgId>", "gid": "<sessionId>", "to": "<deviceId>", "hop": 0, "max": 3, "ts": 0, "k": "<groupKeyHint>" },
  "n": "<b64 nonce 12B>",
  "c": "<b64 ciphertext||MAC>"
}
```

Hop-local **control messages** (`hello`, `key`, `verify_ok`, `verify_fail`) are never relayed; `ack` (delivery receipts) and `typing` are flooded hop-by-hop and filtered by recipient.

### Operational constraints

| Constraint | Value |
|---|---|
| Max relay hops | 3 |
| Relay TTL | 10 s |
| Dedup cache | 30 s |
| Max group size | 30 members |
| Max message length | 500 chars |
| Message retention | 7 days |
| Nickname | 3–20 chars, unique per group (display only) |
| Platform | Android only · `minSdk 23` · `targetSdk 34` |

---

## Getting Started

### Prerequisites

- Flutter **3.44+** (Dart 3.12) — older versions may work but are untested
- Android device or emulator with **Bluetooth + Location** permissions granted at first run
- No Google account, no Firebase project, no network access required

### Run / Build — always via the flavor script

> Plain `flutter run` / `flutter build` compiles **without** the `FLAVOR` dart-define and produces a misconfigured app. Always use `scripts/flavor.ps1`.

```powershell
# Debug run (dev flavor, hot reload)
.\scripts\flavor.ps1 -Flavor dev -Action run

# Debug APK (large, dev only — ~165–230 MB, never distribute)
.\scripts\flavor.ps1 -Flavor dev -Action build

# Obfuscated release — 3 split APKs (per ABI, ~18–24 MB each)
.\scripts\flavor.ps1 -Flavor prod -Action release

# Single android-arm64 release APK (internal builds)
.\scripts\flavor.ps1 -Flavor dev -Action release -Arm64Only
```

**Release builds** are obfuscated (`--obfuscate`); stack-trace symbols are saved to `build/symbols/<flavor>`. Debug APKs embed the kernel blob + JIT engine + Vulkan validation layer, which is why they are huge — never distribute them.

### Flavors

| | `dev` | `prod` |
|---|---|---|
| applicationId | `…dev` suffix | clean |
| App label | NearBuddy Dev | NearBuddy |
| Database | `nearbuddy_db_dev` | `nearbuddy_db` |
| Nearby service IDs | `com.nearbuddy.dev.*` | `com.nearbuddy.*` |

Dev and prod builds **never see each other on the mesh** (isolated service IDs).

### Tests

```bash
flutter test                          # full suite (36 tests)
flutter test test/<path>.dart -v      # single test
```

Pure-Dart crypto tests need no device/plugin; Drift tests use an in-memory database. Widget tests wrap screens in `ShadApp`.

### Codegen (after structural changes)

```bash
flutter pub run build_runner build    # after editing tables/daos/app_database.dart
flutter gen-l10n                      # after editing lib/l10n/*.arb
```

---

## Architecture

### Stack (resolved versions)

| Area | Package |
|---|---|
| UI | `shadcn_ui` ^0.56.1 · `chat_bubbles` ^1.10.1 (presentation wrapper) |
| State | `flutter_riverpod` 2.6.1 · `riverpod` 2.6.1 |
| Persistence | `drift` 2.31.0 (+ `drift_flutter`) · `shared_preferences` 2.5.5 |
| Networking | `nearby_connections` 4.3.0 · `permission_handler` 11.4.0 |
| Crypto | `cryptography` 2.9.0 · `flutter_secure_storage` 9.2.4 |
| Location / battery | `geolocator` 12.0.0 · `battery_plus` 7.1.1 (pinned — 6.x triggers the KGP warning) |
| Navigation / misc | `go_router` 14.8.1 · `uuid` 4.6.0 · `url_launcher` 6.3.2 · `intl` 0.20.2 |

### Design principles

- **`PeerDiscoveryService` is the only interface** the business logic knows — `nearby_connections` is never imported outside `infrastructure/`
- **Drift schema v3** — migrations are versioned (v1→v2 adds `to`, `publicKey`, `sessions`; v2→v3 adds message `status` for outgoing delivery states)
- **Semantic theme tokens** (`NearBuddyColorScheme` light/dark) — screens never hardcode colors; theme mode persists across launches
- **Riverpod lifecycle discipline** — every async handler re-checks `mounted` after each `await`; timers and stream subscriptions are cancelled in `dispose`

### Project structure

```
lib/
├── core/            # constants, feature flags, app config (flavors), router, emoji catalog
├── crypto/          # X25519 keys, AES-GCM, HKDF, SAS
├── data/            # Drift schema v3 + DAOs, SharedPreferences wrapper
├── domain/          # models (MessageEnvelope/Message), services (discovery, key exchange)
├── infrastructure/  # nearby_connections implementation
├── features/        # onboarding, home (+scan), group, chat (+DM), settings
├── l10n/            # ARB files (id/en) + generated localizations
└── theme/           # NearBuddyColorScheme (light/dark semantic tokens)
```

---

## Privacy

- **Zero network calls** — no Firebase, no cloud, no telemetry, no analytics of any kind
- Keys never leave the device; group keys are session-scoped in memory
- Relay nodes are cryptographically unable to read message content or derive keys

---

## Known Limitations (v1)

- **No forward secrecy** — static session group key (double-ratchet is explicitly out of scope)
- **No rekey on member leave**; group key is memory-scoped (app restart = re-key)
- **Pending/failed messages require manual retry** — there is no automatic store-and-forward
- **DM requires prior group contact** (peer public key must already be known)
- **No at-rest encryption** (SQLCipher deferred)
- Intentionally not planned: `flutter_map` / SOS / voice messaging / cloud sync

---

## Roadmap (Milestone M1)

- [ ] **Task 16** — 3-device manual smoke checklist (pending)
- [ ] **CI** — GitHub Actions: lint, test, build APK
- [ ] Release distribution (obfuscated split APKs, per-ABI)

---

## Docs