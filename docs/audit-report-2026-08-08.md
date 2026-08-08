# NearBuddy Adversarial Audit Report — 2026-08-08

Sumber: audit agent (prompt: `docs/review-prompt.md`), read-only. Cakupan: seluruh `lib/` (60 file) + `test/` (10 file) + AGENTS.md / PRD §14 / plan v2.

## Status update (sesi perbaikan, 2026-08-08)

| ID | Status | Perbaikan |
|---|---|---|
| C1 | **FIXED** | Gate receive: DM dicek via `env.to == myId` (bukan `env.gid == _gid`); DM ikut di-relay; receiver melakukan sender-discovery lewat semua pubkey member yang dikenal (MAC memfilter kunci salah, `_openDm` di `chat_controller.dart`); session DM auto-dibuat di sisi penerima (`_persistIncoming`, keyed pada sessionId pengirim); `GroupsDao.allMemberPublicKeys()` baru. Relay gate juga memakai `env.max` dibatasi 3 hop (parsial M1). Test: `chat_controller_receive_test.dart` (5 kasus). |
| C2 | **FIXED** | State handshake per-endpoint (`Map<String, _EndpointState>` menggantikan `_pendingEndpoint`/`_sasConfirmed` global); `SasChallenge(endpointId, sas)` membawa endpoint ke UI; `confirmSas(bool, endpointId:)` mengirim verdict ke endpoint yang benar; `sendGroupKeyTo` dan acceptance `key` di-gate per endpoint. Test: `key_exchange_test.dart` (2 kasus baru). |
| H2 (interim) | **FIXED** | `verify_fail` yang diterima tidak lagi memanggil `stopSession()` — hanya endpoint itu yang dihapus dari handshake (perbaikan penuh = disconnect endpoint spesifik, butuh API baru di `PeerDiscoveryService`, belum dikerjakan). |
| M7 | **FIXED** | `InviteDevicesScreen` kini subscribe `onSasChallenge` — owner tidak lagi kehilangan challenge saat di layar undang. |
| H1, H3–H6, H8, M1–M6, M8–M10, L1–L8 | belum | Lihat daftar di bawah. |

## Verifikasi

| Check | Result |
|---|---|
| `flutter analyze` | PASS — "No issues found!" (26.2 s) |
| `flutter test -v` | PASS — 36/36 tests (~21 s) |
| File dimodifikasi | Tidak ada (read-only) |

Catatan: suite yang lulus BUKAN bukti kebenaran untuk temuan berisiko tertinggi — C1–C2, H1–H4 semua berada di jalur kode yang tidak pernah diinstansiasi test (lihat L5).

---

## CRITICAL

### [C1] DM messages can never be received (or relayed) — 1:1 chat is send-only
- **Location:** `lib/features/chat/chat_controller.dart:78` (gate), `:128-140` (`_decryptionKey`)
- **Category:** wire
- **Evidence:**
```dart
final env = MessageEnvelope.fromWireJson(j);
if (env.gid != _gid) return;                 // line 78 — _gid = current GROUP id
```
`_gid` = `currentGroupProvider?.id` — the active **group** id. A DM envelope carries `gid = sessionId` — a fresh UUID created by the **sender** (`DmController.startDm`). These never match, so:
- The DM is dropped at line 78 **before** the relay decision → DMs are never relayed through group members either.
- `_decryptionKey` also requires a **local** `SessionRow` for `env.gid` — but sessions are only ever created on the *sender's* device. The receiver has no session and the payload carries **no sender deviceId** (only nickname), so even with the gate fixed the receiver could not derive the pairwise key.
- Net effect: sender persists its bubble locally, sends, and the recipient's device **silently drops everything**. Task 16's "DM A→B while C is in range" can never pass.
- **Root cause:** receive filter conflates "belongs to current group" with "is addressed to me"; wire payload lacks the sender's device identity.
- **Fix:** gate on DM → `env.to == myId` (check before the group filter, and relay DMs too); add sender `deviceId` to the `Message` payload and auto-create the DM `SessionRow` keyed on the sender's deviceId on first receipt.

### [C2] Handshake state is single-slot and global — SAS verdicts go to the wrong peer; the group key can be delivered to / accepted from an unverified endpoint
- **Location:** `lib/domain/services/key_exchange_service.dart:36-37, 72-82, 96-106, 118-155`
- **Category:** crypto / security / concurrency
- **Evidence:**
```dart
String? _pendingEndpoint;
bool _sasConfirmed = false;                       // ONE slot for ALL peers
...
case 'hello': ... _pendingEndpoint = fromEndpointId; _sasConfirmed = false;
...
case 'key': if (!_sasConfirmed) return;
```
A joiner in a cluster connects to **several members at once**; each member's `hello` overwrites `_pendingEndpoint`. Consequences:
1. `confirmSas(true)` sends `verify_ok` to the **last** hello's endpoint — verdict to wrong peer.
2. `sendGroupKeyTo` gates on the global `_sasConfirmed`: a peer whose SAS was never confirmed can receive the group key if any other peer confirmed in the interim.
3. `'key'` acceptance gate uses the same global flag.
4. Multiple stacked SAS dialogs make verdict-to-endpoint mixup likely in real multi-member joins.
- **Root cause:** per-endpoint state machine was specified in the plan (Task 9 "State machine per endpoint") but implemented as process-global fields.
- **Fix:** replace with `Map<String, _EndpointState>`; `confirmSas(bool, endpointId)`; gate key delivery/acceptance on *that endpoint's* confirmed state.

---

## HIGH

### [H1] Delivery receipts are forgeable — `ack` ownership is checked by nickname, not device key
- **Location:** `lib/features/chat/chat_controller.dart:109-114`
- **Category:** security
- **Evidence:** `row.senderId != nickname` check never authenticates the ack sender; envelope header is cleartext + flooded → any member can inject `ack` and mark messages `delivered` without real delivery. Renaming also orphans genuine acks.
- **Fix:** scope ack acceptance to the DM recipient's verified endpoint / device-key binding.

### [H2] Receiving `verify_fail` stops the member's *entire* group session
- **Location:** `lib/domain/services/key_exchange_service.dart:139-141`
- **Category:** concurrency
- **Evidence:** member that receives a joiner's `verify_fail` calls `stopSession()` — tears down advertising + ALL connections while `currentGroupProvider` stays set. UI shows chat but is silently deaf.
- **Fix:** stop only the offending endpoint, or drop `stopSession()` here and keep `_joinRejectedCtrl` for joiner-side UX.

### [H3] Manual retry duplicates the message instead of re-sending it
- **Location:** `lib/features/chat/chat_controller.dart:162-181, 185-225`
- **Category:** db / ux
- **Evidence:** `retryMessage` re-seals with a NEW uuid and persists a NEW row; the old `failed` row stays. Repeated taps grow duplicates unboundedly.
- **Fix:** re-use the original `row.id` and statuses, keep one row.

### [H4] Re-entering a group from Home opens a dead chat — session never resumed
- **Location:** `lib/features/home/home_screen.dart:861-863`, `lib/features/chat/chat_controller.dart:143`
- **Category:** lifecycle / ux
- **Evidence:** tapping group row pushes `/chat/<gid>` with no `startSession`, no `currentGroup`, no group key; `sendTextMessage` silently `return`s.
- **Fix:** run a join/resume flow on group row tap, or disable row + "rejoin" affordance; at minimum surface error on send.

### [H5] Decryption failures are silently swallowed — `decryptFailed` UX is dead code
- **Location:** `lib/features/chat/chat_controller.dart:104`; unused `lib/l10n/app_id.arb:49`
- **Category:** wire / ux
- **Evidence:** `} catch (_) {}` swallows relay + decrypt + persist errors. Plan requires `decryptFailed` placeholder after restart (key lost). l10n key exists but nothing reads it.
- **Fix:** distinguish auth/decrypt errors; persist placeholder row; swallow only transport noise.

### [H6] Group PIN transmitted in cleartext in `hello` to every connecting device
- **Location:** `lib/features/group/group_controller.dart:109-110`, `lib/domain/services/key_exchange_service.dart:59-67`, `lib/domain/models/key_payloads.dart:10`
- **Category:** security
- **Evidence:** D-15 removed PIN from advertisement name because of cleartext exposure — but PIN now rides in the unencrypted, hop-local `hello`; connections are auto-accepted with no consent.
- **Fix:** challenge-based PIN proof (nonce + H(pin‖nonce)) instead of cleartext.

### [H7] Nickname uniqueness is never enforced (dead `isNicknameTaken`) — attribution and receipts are nickname-based
- **Location:** `lib/data/database/daos/groups_dao.dart:36-46`; `lib/features/chat/chat_screen.dart:99`, `dm_chat_screen.dart:63`, `chat_controller.dart:112`
- **Category:** constraint / security
- **Evidence:** nothing calls `isNicknameTaken`; bubble "is me" and ack ownership rely on nickname. Wire payload carries no device id.
- **Fix:** enforce at join (reject with `verify_fail`); carry `senderDeviceId` in payload.

### [H8] Ambient scan and session run on the same Nearby instance concurrently
- **Location:** `lib/features/home/home_screen.dart:85`, `lib/features/group/invite_devices_screen.dart:31-33`
- **Category:** lifecycle — **needs verification** (plugin behavior)
- **Evidence:** `InviteDevicesScreen` calls `_scan.start()` while session advertising is active; `_scanning` set before awaits complete.
- **Fix:** serialize scan/session in `NearbyConnectionsService`; set `_scanning` only after awaits; guard `stop()` racing in-flight `start()`.

---

## MEDIUM

### [M1] Wire `max` field ignored; hop/max not range-validated
- **Location:** `lib/features/chat/chat_controller.dart:83`, `lib/domain/models/message_envelope.dart:35-48`
- **Fix:** `if (env.hop < env.max && env.max <= AppConstants.maxHops ...)`; validate `hop >= 0, max in 1..3` on receive.

### [M2] `sendToAll` partial failure marks message `failed` though some peers got it
- **Location:** `lib/infrastructure/nearby/nearby_connections_service.dart:125-131` + `lib/features/chat/chat_controller.dart:219-223`
- **Fix:** collect per-endpoint errors; "sent to ≥1 peer" = `sent`.

### [M3] Group size limit (30) never enforced
- **Location:** `lib/core/constants.dart:4` (`maxGroupSize` — zero usages)
- **Fix:** count active members before accepting a join; reject with `verify_fail` past 30.

### [M4] 7-day retention cleanup runs once per process, only when first chat screen opens
- **Location:** `lib/features/chat/chat_controller.dart:37`
- **Fix:** run on app start + periodic timer (D-03).

### [M5] `connectionStatusProvider.everConnected` never resets — stale "out of range"
- **Location:** `lib/features/shared/connection_status.dart:12-22`
- **Fix:** reset when peer set goes empty after session stop; re-check radio on resume.

### [M6] Home "connected" indicators read a stale snapshot
- **Location:** `lib/features/home/home_screen.dart:204`
- **Fix:** watch `connectionStatusProvider` instead of raw `read`.

### [M7] Owner's SAS challenge lost while on Invite screen — joiner times out
- **Location:** `lib/features/group/invite_devices_screen.dart` (no `onSasChallenge` subscription)
- **Fix:** subscribe in `InviteDevicesScreen` or move subscription into `GroupController` with pending queue.

### [M8] Join timeout dialog "Retry" button is inert
- **Location:** `lib/features/group/join_group_screen.dart:118-134`
- **Fix:** make Retry re-invoke `_join()` with last values.

### [M9] Typing-off clears the wrong session's indicator
- **Location:** `lib/features/chat/chat_controller.dart:60-72`
- **Fix:** track `(to, gid)` for the off-event.

### [M10] Ambient scan cannot see session devices; join list is display-only
- **Location:** `lib/infrastructure/nearby/nearby_connections_service.dart:95-113`, `lib/features/group/join_group_screen.dart:193-210`
- **Fix:** session serviceId discovery once code entered, or make list a join shortcut (D-11 intent).

---

## LOW

- **[L1] l10n violations:** `home_screen.dart:304` `'Secure. Private. Direct.'`; `settings_screen.dart:64, 578, 606, 615, 624, 649` — Indonesian strings in EN locale. (l10n)
- **[L2] Stale doc comment:** `messages_table.dart:16` missing `'failed'` status. (db/doc)
- **[L3] Unbounded in-memory maps:** `_endpointPubKeys`/`_groupKeys`/`ChatController._seen` never pruned on disconnect. (lifecycle)
- **[L4] Group messages with zero peers marked `'sent'`** while DMs get `'pending'` — inconsistent. (wire/ux)
- **[L5] Test suite doesn't test production code:** relay/dedup and shouldRelay re-implemented as private copies; no tests for receive path, ack, retry, statuses, GroupController, verify_fail, retention, multi-peer flows. (test)
- **[L6] Retry affordance undiscoverable** — no visual hint on bubble. (ux)
- **[L7] `TextEditingController`s never disposed** in `dm_sessions_screen.dart:93-94`. (lifecycle)
- **[L8] Acknowledged-good:** canonical `macLength: 16` open correct everywhere; `c` = ciphertext‖MAC; control messages never relayed; mounted-guards after every await; subscriptions cancelled; no secrets logged; no INTERNET permission; `FeatureFlags` all false.

---

## Summary Table

| Severity | crypto | wire | lifecycle | db | ui | l10n | security | concurrency | constraint | test | Total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| CRITICAL | 1 | 1 | – | – | – | – | – | 1 | – | – | **3** (C1, C2) |
| HIGH | – | 1 | 2 | 1 | – | – | 3 | 1 | 1 | – | **8** (H1–H8) |
| MEDIUM | – | 2 | 2 | 2 | 1 | – | – | 2 | 1 | – | **10** (M1–M10) |
| LOW | – | 1 | 2 | 1 | 1 | 1 | – | – | – | 1 | **8** (L1–L8) |
| **Total** | 1 | 5 | 6 | 4 | 2 | 1 | 3 | 4 | 2 | 1 | **29** |

## Top-5 Must-Fix (ranked by risk)

1. **C1 — DM receive/relay is impossible** (wire): 1:1 chat is a marquee feature of the v2 scope (D-11); currently send-only with silent drops.
2. **C2 — Per-endpoint handshake state** (crypto): SAS verdicts cross peers, keys can flow to/from unverified endpoints; multi-member joins deadlock or mis-verify.
3. **H2 — `verify_fail` kills the member's whole session** (concurrency): a designed flow (SAS mismatch) silently disables an established member.
4. **H1 — Forgeable delivery receipts** (security): "delivered" UI is meaningless without endpoint/device-key binding.
5. **H3+H4 — Retry duplicates rows; group re-entry is a dead chat** (db/ux): user-visible data duplication and a permanently broken navigation path.
