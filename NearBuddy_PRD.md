# NearBuddy — Product Requirements Document (PRD)

**Versi:** 1.0 (Draft)
**Tanggal:** 7 Agustus 2026
**Status:** Under Review
**Author:** Product Team

---

## Asumsi Eksplisit

> Informasi berikut diasumsikan karena tidak dispesifikasikan secara eksplisit dalam brief. Jika ada yang tidak tepat, perlu dikoreksi sebelum development dimulai.

| Asumsi | Dasar Pengambilan |
|---|---|
| Android sebagai platform prioritas MVP; iOS menyusul di v1.1 | Nearby Connections (Android) lebih mature dan stabil vs. Multipeer Connectivity (iOS) yang memiliki lebih banyak batasan background |
| Target SDK Android minimum: API 23 (Android 6.0) | Nearby Connections API mensyaratkan minimal API 23; masih mencakup ~95%+ perangkat aktif |
| Ukuran grup realistis: 2–30 perangkat per sesi | Lebih dari 30 node berpotensi membebani mesh relay tanpa bottleneck management |
| Tidak ada monetisasi di v1 — freemium di v1.1+ | Fokus pada traction dan validasi pasar; SOS & offline map sebagai kandidat fitur premium |
| Bahasa UI: Indonesia + English (bilingual, ID sebagai default) | Target user Indonesia namun produk berpotensi internasional; i18n setup sejak M1 |
| Tidak ada akun pengguna (identitas berbasis nickname lokal) | Sesuai arsitektur offline-first tanpa server |
| Nickname bisa diubah, harus unik dalam grup (validasi saat join) | Mencegah ambiguitas identitas terutama di skenario SAR |
| Disclaimer hukum wajib di-accept saat onboarding (sekali) | Perlindungan legal minimal, friction rendah |
| Riwayat pesan tersimpan 7 hari lalu auto-delete | Cukup untuk review pasca-operasi; menjaga privasi dan storage |
| Location ping tanpa peta (koordinat + tombol 'Buka di Maps') | Offline map dipindahkan ke v1.1; implementasi lebih ringan dan fokus |

---

## 1. Overview & Background

### Ringkasan Produk

**NearBuddy** adalah aplikasi mobile Flutter yang memungkinkan komunikasi grup secara offline — tanpa internet, tanpa sinyal seluler — menggunakan teknologi peer-to-peer lokal (WiFi Direct, Bluetooth Low Energy, melalui Google Nearby Connections API di Android dan Apple Multipeer Connectivity di iOS).

Aplikasi ini dirancang untuk situasi di mana konektivitas tradisional tidak tersedia atau tidak dapat diandalkan: puncak gunung, dalam hutan, arena festival outdoor, lokasi bencana. NearBuddy mengisi gap komunikasi yang tidak bisa diisi oleh WhatsApp, Zello, atau aplikasi chat berbasis internet lainnya.

### Latar Belakang Masalah

Pertumbuhan outdoor activity di Indonesia meningkat signifikan pasca-pandemi. Data Kementerian Pariwisata menunjukkan jumlah kunjungan ke kawasan alam terbuka naik 40%+ antara 2022–2024. Di sisi lain, infrastruktur telekomunikasi masih memiliki *coverage gap* yang besar di area-area ini:

- **Festival outdoor** (Hammersonic, Synchronize, Pestapora) dengan 50.000–100.000 pengunjung menyebabkan *network congestion* yang membuat SMS dan data seluler praktis tidak bisa digunakan
- **Jalur pendakian populer** (Semeru, Rinjani, Prau) masih memiliki *dead zone* di sebagian besar rutenya
- **Operasi SAR** di medan terbuka sering mengandalkan HT yang mahal, berat, dan memerlukan lisensi operator

### Mengapa Sekarang?

Tiga faktor konvergen membuat timing ini tepat:

1. **Kematangan API**: Google Nearby Connections API (Android) dan Apple Multipeer Connectivity (iOS) kini cukup mature untuk production use, dengan dokumentasi dan community yang memadai
2. **Flutter maturity**: Flutter 3.x memungkinkan satu codebase untuk Android dan iOS dengan performa near-native
3. **Kesadaran pengguna**: Insiden grup terpisah di festival (viral di Twitter/X) dan kecelakaan pendakian solo menciptakan *pull demand* yang nyata di komunitas outdoor Indonesia

---

## 2. Problem Statement

### Masalah Utama

**Grup orang tidak bisa berkomunikasi saat berada di area tanpa sinyal, namun masih dalam jarak fisik yang berdekatan (10–200 meter).**

### Breakdown Masalah Spesifik

| Skenario | Frekuensi | Severity | Solusi Eksisting & Kekurangannya |
|---|---|---|---|
| Teman terpisah di festival | Setiap event besar, dialami mayoritas pengunjung | Tinggi | Telepon/WA tidak bisa karena jaringan macet; bertemu di titik yang telah ditentukan tidak fleksibel |
| Grup hiking terpisah di jalur bercabang | 1–3x per pendakian multi-hari | Kritis | Hanya bisa teriak atau menunggu; Handy Talkie mahal dan berat |
| Tim SAR kehilangan koordinasi di lapangan | Tiap operasi skala menengah-besar | Kritis | Radio HT profesional tersedia namun tidak accessible untuk relawan; tidak ada log pesan |
| Camping group koordinasi aktivitas | Harian selama trip | Medium | Tidak ada solusi sama sekali tanpa internet |
| Event organizer koordinasi panitia di venue | Per event | Medium | Walkie-talkie fisik terbatas; HT perlu lisensi ORARI |

### Siapa yang Merasakan Masalah Ini?

- **Hikers** 18–45 tahun, aktif di komunitas hiking Indonesia (Backpacker Nusantara, Mountaineers ID, dll.) — segmen terbesar dengan *pain point* paling jelas
- **Festival-goers** 17–35 tahun, menghadiri 2–5 festival per tahun — segmen terbesar secara volume namun *pain* lebih episodik
- **Tim SAR / Relawan Outdoor** — segmen kecil namun *high-impact*, berpotensi menjadi *reference customers*
- **Event Organizers** — segmen B2B kecil yang mungkin mau membayar untuk fitur premium di masa depan

---

## 3. Goals & Non-Goals

### Goals (Tujuan Terukur)

| Goal | Metrik Sukses | Target v1 |
|---|---|---|
| G1: Memungkinkan komunikasi teks tanpa internet | Pesan terkirim dalam grup offline dalam < 2 detik (jarak <50m) | 95% success rate dalam pengujian |
| G2: Device discovery yang cepat dan reliable | Waktu menemukan device lain dalam jaringan | < 10 detik di lingkungan normal |
| G3: Memperluas jangkauan via mesh relay | Pesan sampai ke device di luar jangkauan langsung | Relay 2 hop, coverage hingga ~150m |
| G4: Location sharing sesama anggota grup | Anggota bisa kirim dan lihat pin lokasi sesama | Akurasi GPS native device |
| G5: Pengalaman onboarding yang mudah | User bisa join grup dan kirim pesan pertama | < 60 detik dari buka app pertama kali |

### Non-Goals (Eksplisit TIDAK dikerjakan di v1)

- ❌ **Bukan pengganti radio HT profesional atau sistem komunikasi darurat resmi** — NearBuddy tidak memenuhi standar reliability yang disyaratkan untuk SAR profesional BASARNAS
- ❌ **Bukan emergency service** — Tidak terintegrasi dengan nomor darurat, BPBD, atau layanan rescue resmi
- ❌ **Tidak ada sinkronisasi cloud** — Tidak ada backup pesan ke server, tidak ada riwayat lintas sesi
- ❌ **Tidak ada voice/audio messaging** — Terlalu membebani bandwidth BLE/WiFi Direct di v1
- ❌ **Tidak ada enkripsi end-to-end** di v1 — Komunikasi lokal dianggap cukup aman dalam konteks ini; akan dipertimbangkan di v2
- ❌ **Tidak ada fitur tracking real-time** (GPS broadcasting terus-menerus) — Hanya on-demand location ping untuk hemat baterai
- ❌ **Tidak ada fitur sosial** (profil, follower, history lintas sesi)
- ❌ **Tidak ada monetisasi** di v1

---

## 4. Target Users & Personas

### Persona 1: Bimo — Pendaki Aktif

| Atribut | Detail |
|---|---|
| **Nama** | Bimo Prakoso, 28 tahun |
| **Pekerjaan** | Software Engineer, Jakarta |
| **Aktivitas** | Mendaki 1–2x sebulan, sering ke Semeru, Rinjani, Papandayan |
| **Perangkat** | Samsung Galaxy S22 (Android 13), baterai besar |
| **Grup Tipikal** | 4–8 orang, campuran pengalaman |

**Pain Points:**
- Selalu ada anggota grup yang "nyasar" atau berjalan lebih lambat — koordinasi jadi masalah
- Titik meeting yang sudah disepakati kadang berubah di lapangan karena kondisi cuaca/jalur
- Pernah 2 jam menunggu 2 orang yang terpisah di jalur bercabang Semeru

**Skenario Penggunaan Nyata:**
> Bimo memimpin grup 6 orang naik Gunung Prau. Setelah pos 3, sinyal hilang total. Dua anggota terlambat dan jalur bercabang. Dengan NearBuddy, Bimo bisa kirim pesan "tunggu di persimpangan" yang di-relay oleh device anggota yang lebih belakang, dan menerima location ping dari anggota yang terpisah.

---

### Persona 2: Nadia — Festival Enthusiast

| Atribut | Detail |
|---|---|
| **Nama** | Nadia Kusuma, 23 tahun |
| **Pekerjaan** | Content Creator, Bandung |
| **Aktivitas** | 3–5 festival per tahun (Synchronize, Pestapora, We The Fest) |
| **Perangkat** | iPhone 14 (iOS 17) |
| **Grup Tipikal** | 5–12 orang, teman kuliah dan komunitas |

**Pain Points:**
- Di festival besar, WhatsApp tidak bisa dikirim karena jaringan congested
- Grup sering terpisah setelah keluar dari area yang sama
- Selalu harus menetapkan "titik kumpul" yang kaku di awal, tidak fleksibel

**Skenario Penggunaan Nyata:**
> Nadia dan 8 teman hadir di Synchronize Fest. Setelah band favorit tampil, mereka terpisah di kerumunan. Nadia kirim "Aku di food court dekat pintu C, ada yang mau ke sini?" lewat NearBuddy. Pesan di-relay oleh beberapa device di antaranya dan 5 temannya melihat dalam 3 detik.

---

### Persona 3: Reza — Tim Relawan SAR

| Atribut | Detail |
|---|---|
| **Nama** | Reza Fauzi, 35 tahun |
| **Pekerjaan** | Relawan SAR Komunitas, Bogor |
| **Aktivitas** | 4–6 operasi SAR per tahun di Jabar |
| **Perangkat** | Xiaomi Redmi Note 12 (Android 12), waterproof case |
| **Grup Tipikal** | 8–20 orang, dibagi dalam tim kecil |

**Pain Points:**
- Koordinasi lapangan sering bergantung pada HT yang baterainya cepat habis
- Tidak ada log pesan tertulis — informasi penting (koordinat korban, kondisi jalur) harus diulang via radio
- Beberapa anggota tim berada di luar jangkauan langsung, perlu relay manusia

**Skenario Penggunaan Nyata:**
> Tim Reza mencari pendaki hilang di Gunung Salak. Tim dibagi 3 kelompok, masing-masing bergerak ke arah berbeda. Dengan NearBuddy mesh relay, koordinat temuan jejak korban dari Tim C bisa sampai ke Reza di Tim A melalui Tim B sebagai relay, tanpa radio. Pesan bisa disimpan sebagai log operasi.

---

## 5. User Stories & Use Cases

### Epic 1: Onboarding & Group Setup

| ID | User Story | Priority |
|---|---|---|
| US-01 | Sebagai **pengguna baru**, saya ingin membuat identitas (nickname) tanpa perlu daftar akun, agar saya bisa langsung menggunakan app tanpa friction | P0 |
| US-02 | Sebagai **pemimpin grup**, saya ingin membuat room/sesi baru dengan nama yang mudah diingat (mis. "Tim Prau 2026"), agar tim saya bisa join dengan mudah | P0 |
| US-03 | Sebagai **anggota**, saya ingin melihat daftar grup yang tersedia di sekitar saya, agar saya bisa memilih dan bergabung dengan cepat | P0 |
| US-04 | Sebagai **anggota**, saya ingin join grup dengan PIN 4–6 digit, agar grup tidak bisa dimasuki orang asing yang tidak diundang | P1 |

### Epic 2: Messaging

| ID | User Story | Priority |
|---|---|---|
| US-05 | Sebagai **anggota**, saya ingin mengirim pesan teks ke semua orang di grup, agar semua bisa membaca informasi penting | P0 |
| US-06 | Sebagai **anggota**, saya ingin tahu pesan saya sudah terkirim/diterima siapa, agar saya tidak perlu mengirim ulang | P1 |
| US-07 | Sebagai **anggota**, saya ingin melihat siapa yang sedang online/aktif di grup, agar saya tahu siapa yang bisa menerima pesan | P1 |
| US-08 | Sebagai **Reza (SAR)**, saya ingin pesan tersimpan di device saya meski app ditutup, agar ada log operasi yang bisa dibaca ulang | P1 |

### Epic 3: Location Ping

| ID | User Story | Priority |
|---|---|---|
| US-09 | Sebagai **Bimo (pendaki)**, saya ingin mengirim pin lokasi saya sekarang ("Saya di sini"), agar anggota yang terpisah tahu posisi saya | P0 |
| US-10 | Sebagai **anggota**, saya ingin melihat pin lokasi anggota lain di peta sederhana, agar bisa menuju lokasi mereka | P1 |
| US-11 | Sebagai **anggota**, saya ingin lokasi ping tidak dikirim secara otomatis terus-menerus, agar baterai hemat dan privasi terjaga | P0 |

### Epic 4: Multi-Hop Relay

| ID | User Story | Priority |
|---|---|---|
| US-12 | Sebagai **Bimo**, saya ingin pesan saya bisa sampai ke anggota yang di luar jangkauan WiFi direct saya, asalkan ada device perantara, agar komunikasi tidak terputus meski tersebar | P0 |
| US-13 | Sebagai **pengguna**, saya ingin device saya otomatis menjadi relay untuk anggota lain, tanpa perlu konfigurasi manual | P0 |

### Epic 5: Skenario Darurat

| ID | User Story | Priority |
|---|---|---|
| US-14 | Sebagai **Reza (SAR)**, saya ingin broadcast pesan SOS ke semua device dalam jangkauan mesh (bukan hanya grup saya), agar bisa meminta bantuan segera | P1 (Nice-to-have) |
| US-15 | Sebagai **anggota**, saya ingin app tetap berfungsi meski baterai < 20%, dengan mode low-power yang mengurangi frekuensi scan | P1 |
| US-16 | Sebagai **anggota**, saya ingin lihat siapa yang tidak check-in dalam X menit, agar tahu apakah ada yang mungkin bermasalah | P2 (Nice-to-have) |

---

## 6. Functional Requirements

### FR-01: Device Discovery

**Deskripsi:** App harus bisa menemukan device NearBuddy lain yang berada dalam jangkauan fisik dan menampilkan daftarnya kepada pengguna.

| # | Acceptance Criteria | Prioritas |
|---|---|---|
| AC-01.1 | Discovery dimulai secara otomatis saat app dibuka (foreground) | Must Have |
| AC-01.2 | Daftar device yang ditemukan diperbarui dalam ≤ 5 detik setelah device baru masuk jangkauan | Must Have |
| AC-01.3 | Device yang keluar jangkauan dihapus dari daftar dalam ≤ 15 detik | Must Have |
| AC-01.4 | Discovery menggunakan Nearby Connections (Android) dan Multipeer Connectivity (iOS) | Must Have |
| AC-01.5 | Pengguna dapat melihat nama/nickname device yang ditemukan | Must Have |
| AC-01.6 | Discovery berhenti secara otomatis saat app masuk background (Android background battery restriction) | Must Have |
| AC-01.7 | Ada indikator visual yang jelas saat discovery sedang aktif vs. tidak aktif | Should Have |

---

### FR-02: Text Messaging

**Deskripsi:** Pengguna dalam grup yang sama bisa saling mengirim pesan teks.

| # | Acceptance Criteria | Prioritas |
|---|---|---|
| AC-02.1 | Pesan teks dikirim ke semua anggota grup yang terhubung | Must Have |
| AC-02.2 | Pesan muncul di penerima dalam ≤ 2 detik jika jarak ≤ 50m tanpa obstacle | Must Have |
| AC-02.3 | Pesan diberi timestamp lokal (device sender) | Must Have |
| AC-02.4 | Ada read receipt: "terkirim" (device sender berhasil broadcast) dan "diterima" per device | Should Have |
| AC-02.5 | Panjang pesan maksimum: 500 karakter per pesan | Must Have |
| AC-02.6 | Pesan tersimpan lokal di device dalam sesi yang sedang berjalan | Must Have |
| AC-02.7 | Pesan persisten (tidak hilang jika app di-minimize) untuk durasi sesi | Should Have |
| AC-02.8 | Pesan dari device yang di luar jangkauan langsung diterima via relay (lihat FR-04) | Must Have |

---

### FR-03: Location Ping

**Deskripsi:** Pengguna dapat mengirimkan koordinat GPS mereka sebagai pesan khusus ("pin lokasi") kepada grup.

| # | Acceptance Criteria | Prioritas |
|---|---|---|
| AC-03.1 | Pengguna dapat menekan tombol "Kirim Lokasi Saya" untuk mengirim koordinat GPS saat ini | Must Have |
| AC-03.2 | Location ping muncul di chat sebagai pesan khusus dengan ikon pin dan koordinat | Must Have |
| AC-03.3 | Location ping dapat dibuka untuk menampilkan peta statis (mini-map) dengan pin | Should Have |
| AC-03.4 | Lokasi hanya dikirim saat pengguna secara eksplisit menekan tombol (bukan auto-broadcast) | Must Have |
| AC-03.5 | App meminta izin akses GPS dengan penjelasan konteks yang jelas sebelum fitur digunakan | Must Have |
| AC-03.6 | Jika GPS tidak tersedia (indoor/cave), tampilkan pesan error yang informatif | Must Have |
| AC-03.7 | Format data: latitude, longitude, akurasi, dan timestamp | Must Have |

---

### FR-04: Multi-Hop Relay

**Deskripsi:** Pesan dari pengirim A dapat mencapai penerima C melalui device B sebagai perantara, memperluas jangkauan efektif jaringan.

| # | Acceptance Criteria | Prioritas |
|---|---|---|
| AC-04.1 | Setiap device dalam grup otomatis berfungsi sebagai relay node | Must Have |
| AC-04.2 | Pesan di-relay hingga maksimum 3 hop (A→B→C→D) | Must Have |
| AC-04.3 | Pesan yang sama tidak di-relay ulang (deduplikasi via message ID) | Must Have |
| AC-04.4 | TTL (Time-to-Live) pesan: maksimum 10 detik atau 3 hop, mana yang lebih dulu tercapai | Must Have |
| AC-04.5 | Relay terjadi transparan; pengguna tidak perlu konfigurasi manual | Must Have |
| AC-04.6 | Overhead relay tidak menyebabkan lag >500ms tambahan per hop | Should Have |

---

### FR-05: Onboarding & Group Management

| # | Acceptance Criteria | Prioritas |
|---|---|---|
| AC-05.1 | Pengguna membuat nickname (3–20 karakter) saat pertama buka app | Must Have |
| AC-05.2 | Pengguna dapat membuat grup baru dengan nama grup | Must Have |
| AC-05.3 | Grup baru di-broadcast agar bisa ditemukan device lain di sekitar | Must Have |
| AC-05.4 | Pengguna dapat join grup yang terdeteksi dengan atau tanpa PIN | Must Have |
| AC-05.5 | Jika grup menggunakan PIN, PIN-nya 4–6 digit numerik | Should Have |
| AC-05.6 | Daftar anggota grup yang aktif terlihat di UI | Should Have |
| AC-05.7 | Pengguna dapat keluar dari grup | Must Have |

---

### FR-06: SOS Broadcast *(Nice-to-Have)*

| # | Acceptance Criteria | Prioritas |
|---|---|---|
| AC-06.1 | Pengguna dapat memicu SOS yang dikirim ke semua device NearBuddy di sekitar, terlepas dari grup | Nice-to-Have |
| AC-06.2 | SOS memerlukan konfirmasi 2 langkah untuk mencegah false trigger | Nice-to-Have |
| AC-06.3 | SOS di-relay maksimum 5 hop untuk memperluas jangkauan | Nice-to-Have |
| AC-06.4 | Device penerima SOS menampilkan alert yang tidak bisa diabaikan (full-screen) | Nice-to-Have |

---

## 7. Non-Functional Requirements

### 7.1 Performa & Latency

| Requirement | Target |
|---|---|
| Latency pengiriman pesan (dalam jangkauan langsung, ≤50m) | ≤ 2 detik (P95) |
| Latency pesan per hop relay tambahan | ≤ 500ms tambahan per hop |
| Waktu discovery device baru | ≤ 10 detik |
| Waktu startup app (cold start) | ≤ 3 detik |
| Ukuran payload per pesan teks | ≤ 2 KB |
| Ukuran payload location ping | ≤ 1 KB |

### 7.2 Battery Efficiency

| Mode | Target Konsumsi Baterai |
|---|---|
| Mode Aktif (discovery + connected) | ≤ 8% per jam (benchmark Samsung Galaxy S22) |
| Mode Low-Power (baterai < 20%) | ≤ 4% per jam; discovery interval diperlambat 3x |
| Background (app diminimize) | Discovery dihentikan, hanya maintain koneksi yang sudah ada |

### 7.3 Jangkauan & Reliability

| Skenario | Target |
|---|---|
| Jangkauan WiFi Direct (line of sight) | 30–100m (tergantung hardware; tidak bisa dijanjikan melewati ini) |
| Jangkauan BLE (fallback) | 10–30m |
| Jangkauan efektif dengan 3 hop relay | Hingga ~200m (estimasi; tidak dijamin) |
| Reliability pengiriman pesan dalam jangkauan | ≥ 95% success rate |
| Recovery koneksi setelah putus singkat (< 30 detik) | Otomatis, ≤ 15 detik reconnect |

### 7.4 Keamanan & Privasi

| Requirement | Keterangan |
|---|---|
| Tidak ada data yang dikirim ke server eksternal | Zero cloud dependency; semua data tetap di device |
| Identitas berupa nickname lokal | Tidak ada email, nomor telepon, atau data PII tersimpan |
| PIN grup | Opsional; untuk grup yang ingin membatasi akses |
| Data lokal | Disimpan di app-private storage (tidak accessible app lain) |
| Enkripsi data lokal | Pertimbangkan enkripsi Drift database via SQLCipher di v1.1 |
| Tidak ada analytics remote | Tidak ada Firebase Analytics, Crashlytics, atau sejenisnya di v1 |

### 7.5 Ukuran App & Kompatibilitas

| Requirement | Target |
|---|---|
| Ukuran APK (Android) | ≤ 30 MB |
| Ukuran IPA (iOS) | ≤ 40 MB |
| Android minimum SDK | API 23 (Android 6.0) |
| iOS minimum versi | iOS 13 |
| Dukungan offline penuh | App harus berfungsi 100% tanpa koneksi internet |

---

## 8. Technical Constraints & Architecture Notes

### 8.1 Platform API: Android

- **Google Nearby Connections API** mendukung tiga *strategy*: STAR (hub-and-spoke), CLUSTER (peer-to-peer), dan POINT_TO_POINT. Untuk NearBuddy, gunakan **CLUSTER** strategy untuk mendukung mesh peer-to-peer.
- Nearby Connections menggunakan kombinasi BLE advertising + WiFi Direct untuk data transfer — lebih efisien daripada BLE saja.
- **Keterbatasan background**: Android 8+ membatasi advertising saat app di background. Solusi: gunakan Foreground Service dengan persistent notification saat sesi aktif.
- Membutuhkan permission: `ACCESS_FINE_LOCATION`, `NEARBY_WIFI_DEVICES` (API 33+), `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`.
- Flutter plugin yang direkomendasikan: **`nearby_connections`** (pub.dev) atau wrapper custom menggunakan Platform Channels.

### 8.2 Platform API: iOS

- **Apple Multipeer Connectivity (MPC)** lebih terbatas dibanding Nearby Connections:
  - Tidak bisa berjalan di background lebih dari beberapa menit tanpa trik khusus (Background Task / VoIP push)
  - Lebih rentan terhadap rejection App Store jika diklaim sebagai emergency communication tool
  - Jangkauan BLE lebih pendek vs. WiFi Direct Android
- Strategi iOS: prioritaskan untuk passive relay (menerima dan meneruskan pesan), batasi advertising background.
- Flutter plugin: **`nearby`** atau `flutter_multipeer_connectivity`.

### 8.3 Multi-Hop Relay Architecture

```
Device A --- (direct) --- Device B --- (direct) --- Device C
     \                                               /
      '------------- (tidak dalam jangkauan) --------'

Pesan A→C: A kirim ke B, B mendeteksi C dalam jangkauan B, B forward ke C.
```

- Setiap pesan diberi **UUID unik** (messageId) untuk deduplikasi.
- Pesan diberi field **hopCount** (bertambah setiap relay) dan **maxHops** (default: 3).
- Setiap device menyimpan cache messageId yang sudah diteruskan selama 30 detik untuk mencegah loop.
- **Flood routing** di v1 (broadcast ke semua peer yang terhubung); pertimbangkan targeted routing di v2.

### 8.4 Data Model & Local Storage

**Pilihan Storage:**

| Opsi | Kelebihan | Kekurangan | Rekomendasi |
|---|---|---|---|
| **Drift (SQLite)** | Query SQL powerful, relational, type-safe codegen, reactive streams, Flutter-native | Setup awal lebih verbose (codegen) | ✅ Recommended untuk pesan, sesi & relay cache |
| **Hive** | Ringan, setup cepat | Tidak ada query relasional; sulit untuk query kompleks lintas entitas | ⛔ Tidak digunakan |
| **SharedPreferences** | Sederhana | Hanya key-value, tidak untuk data list | ✅ Untuk settings user saja |

**Alasan memilih Drift:**
- **Relational queries**: Memudahkan query seperti "semua pesan di grup X yang belum di-relay" atau "anggota aktif dalam 5 menit terakhir" — sulit dilakukan dengan Hive
- **Reactive streams**: `watchMessages()` via Drift stream memberi real-time UI update tanpa polling manual
- **Type-safe codegen**: Compile-time safety untuk schema; lebih mudah di-maintain seiring schema berkembang
- **Migration support**: Drift punya API migrasi database yang proper — penting untuk evolusi schema antar versi app
- **SQLite-based**: MBTiles untuk offline map juga SQLite, sehingga hanya satu dependency engine

**Struktur Data Utama:**

```dart
// Message Model
class Message {
  String id;          // UUID
  String groupId;
  String senderId;    // Device nickname
  String content;
  MessageType type;   // text | locationPing | sos
  DateTime timestamp;
  int hopCount;
  List<String> deliveredTo; // deviceIds yang sudah menerima
}

// Group Session
class GroupSession {
  String id;
  String name;
  String? pin;        // nullable jika tanpa PIN
  DateTime createdAt;
  List<String> memberIds;
}

// Location Ping (embedded dalam Message)
class LocationData {
  double latitude;
  double longitude;
  double accuracy;
  DateTime capturedAt;
}
```

### 8.5 Offline Map (Nice-to-Have)

- Gunakan **flutter_map** + **MBTiles** atau tile cache dari provider offline (mis. OpenStreetMap tiles yang di-cache sebelum berangkat)
- Strategi caching: pengguna harus pre-download area map sebelum berangkat (tidak bisa download saat offline)
- Format tile cache: SQLite-based MBTiles adalah standar yang paling kompatibel
- Plugin: `flutter_map` (lightweight, no Google dependency) + `tile_provider` custom dari local SQLite

---

## 9. UX Principles & Key Flows

### 9.1 Prinsip UX

1. **Zero setup friction**: Pengguna bisa dari buka app → kirim pesan dalam < 60 detik tanpa registrasi
2. **Offline-first visual design**: Status konektivitas selalu terlihat jelas; tidak ada elemen UI yang imply "perlu internet"
3. **Battery awareness**: Indikator konsumsi daya visible; mode low-power aktif otomatis
4. **Graceful degradation**: Jika relay gagal, user diberitahu; bukan silent fail
5. **Accessible in duress**: Font cukup besar, kontras tinggi, tombol critical (SOS, Location Ping) mudah dijangkau satu tangan

### 9.2 Flow Utama

#### Flow 1: First-Time Onboarding
```
[Splash Screen]
    → Izin Bluetooth + Location (dengan penjelasan konteks)
    → Set Nickname (3–20 karakter)
    → Home Screen (discovery aktif)
```

#### Flow 2: Membuat Grup Baru
```
[Home Screen] → Tombol "Buat Grup"
    → Masukkan Nama Grup
    → (Opsional) Aktifkan PIN → masukkan PIN 4–6 digit
    → Grup dibuat → discovery broadcast dimulai
    → Screen Chat Grup (menunggu anggota join)
```

#### Flow 3: Join Grup
```
[Home Screen] → Daftar grup yang tersedia di sekitar
    → Pilih grup
    → (Jika ada PIN) → Masukkan PIN
    → Konfirmasi masuk grup
    → Screen Chat Grup
```

#### Flow 4: Kirim Pesan Teks
```
[Chat Screen] → Ketik pesan di input bar
    → Tekan Send
    → Pesan muncul di UI dengan status "Mengirim..."
    → Status berubah ke "Terkirim ✓" saat dikonfirmasi diterima
    → Status berubah ke "Diterima ✓✓" saat semua anggota aktif menerima
```

#### Flow 5: Location Ping
```
[Chat Screen] → Tekan ikon 📍 (pin lokasi)
    → Konfirmasi "Kirim lokasi Anda sekarang?"
    → App mengambil GPS fix (loading indicator)
    → Pesan lokasi dikirim dan muncul di chat semua anggota
    → Penerima bisa tap pesan lokasi → buka mini map view
```

#### Flow 6: SOS Broadcast *(Nice-to-Have)*
```
[Any Screen] → Tekan tombol SOS (merah, sudut bawah kiri)
    → Layar konfirmasi: "Anda akan mengirim SOS darurat ke SEMUA device NearBuddy di sekitar"
    → Tahan tombol 3 detik ATAU masukkan PIN konfirmasi
    → SOS dikirim, broadcast ke mesh maksimum 5 hop
    → Device penerima: alert full-screen merah dengan info pengirim dan lokasi (jika tersedia)
```

#### Flow 7: Low Battery Mode
```
[Background process] → Deteksi baterai < 20%
    → Notifikasi: "Mode Hemat Aktif — Interval scan diperpanjang"
    → Discovery interval 3x lebih lambat
    → UI menampilkan badge "⚡ Hemat" di status bar
```

---

## 10. Success Metrics / KPI

> Karena tidak ada backend analytics, metrik diukur secara lokal (in-app telemetry disimpan di device, opt-in) atau melalui mekanisme pengumpulan manual (form feedback, community survey).

### 10.1 Metrik Teknis (In-App, Lokal)

| Metrik | Target | Cara Mengukur |
|---|---|---|
| **Message Delivery Rate** | ≥ 95% pesan terkirim dalam 5 detik | Log lokal: kirim vs. konfirmasi diterima |
| **Crash-Free Rate** | ≥ 99% sesi tanpa crash | Flutter error handling lokal; opt-in crash log |
| **Discovery Latency** | P95 ≤ 10 detik | Timestamp log: mulai discovery → pertama device ditemukan |
| **Relay Success Rate** | ≥ 80% pesan multi-hop sukses (2 hop) | Log relay forwarding |
| **Battery Drain per Sesi** | ≤ 8% per jam mode aktif | Snapshot baterai awal vs. akhir sesi |

### 10.2 Metrik Penggunaan (Manual/Survey)

| Metrik | Target v1 | Cara Mengukur |
|---|---|---|
| **Active Devices per Session** | Rata-rata ≥ 3 device per sesi | Log sesi (opsional, lokal) |
| **Session Duration** | Rata-rata ≥ 15 menit | Timestamp join → leave grup |
| **Message Volume per Session** | Rata-rata ≥ 10 pesan per sesi | Counter lokal |
| **Feature Adoption: Location Ping** | ≥ 30% sesi menggunakan fitur ini | Counter penggunaan fitur |
| **D7 Retention** | ≥ 30% user kembali setelah 7 hari | Survey komunitas / TestFlight analytics |
| **NPS (Net Promoter Score)** | ≥ 40 di beta | In-app feedback form sederhana |

---

## 11. Risks & Mitigations

### 11.1 Risiko Teknis

| Risiko | Kemungkinan | Dampak | Mitigasi |
|---|---|---|---|
| **Fragmentasi Android**: Nearby Connections tidak konsisten di beberapa merek (Xiaomi MIUI, Oppo ColorOS) karena aggressive battery optimization | Tinggi | Tinggi | Deteksi merek dan tampilkan panduan "Izinkan berjalan di background" spesifik per merek; uji di minimum 5 merek populer Indonesia (Samsung, Xiaomi, Oppo, Realme, Vivo) |
| **iOS background limitation**: Multipeer Connectivity dimatikan sistem saat app background | Tinggi | Medium | Gunakan Foreground Service approach yang tepat; dokumentasikan keterbatasan dengan jelas kepada user; iOS v1 mungkin hanya full-featured saat app foreground |
| **Battery drain tinggi**: Kombinasi WiFi Direct + BLE bisa menguras baterai cepat di perangkat tertentu | Medium | Tinggi | Benchmark di 5+ perangkat; mode low-power otomatis; user education di onboarding |
| **Loop pesan di mesh**: Pesan di-relay berulang menyebabkan spam atau crash | Medium | Tinggi | Deduplikasi wajib via UUID + cache 30 detik; TTL/maxHops hard limit |
| **Kompatibilitas WiFi Direct + Hotspot aktif**: Beberapa device tidak bisa menjalankan WiFi Direct saat mobile hotspot aktif | Medium | Medium | Deteksi konflik dan tampilkan peringatan; fallback ke BLE-only |

### 11.2 Risiko Produk & Bisnis

| Risiko | Kemungkinan | Dampak | Mitigasi |
|---|---|---|---|
| **App Store rejection (iOS)**: Apple mungkin reject jika fitur SOS diklaim sebagai emergency service | Medium | Tinggi | Framing yang tepat dalam App Store description: "bukan emergency service resmi"; hindari kata "darurat" dalam nama fitur yang menghadap App Store; SOS = "Distress Signal" |
| **Penyalahgunaan SOS**: Pengguna iseng memicu SOS palsu | Medium | Medium | Konfirmasi 2 langkah + cooldown 30 menit setelah SOS terkirim |
| **Ekspektasi pengguna terlalu tinggi**: User mengira NearBuddy bisa menggantikan HT profesional | Tinggi | Medium | Onboarding yang jelas tentang keterbatasan; FAQ in-app; marketing messaging yang tepat |
| **Kompetisi**: GoTenna, Meshtastic, Bridgefy sudah ada di pasar global | Medium | Low (segmen Indonesia) | Fokus pada UX sederhana + bahasa Indonesia; target komunitas lokal yang spesifik |

### 11.3 Risiko Regulasi

| Risiko | Kemungkinan | Dampak | Mitigasi |
|---|---|---|---|
| Regulasi frekuensi radio (SDPPI Kominfo) untuk WiFi Direct/BLE | Low | Tinggi | WiFi Direct beroperasi di frekuensi WiFi (2.4/5 GHz) yang sudah dilisensikan untuk umum; konsultasi hukum jika produk dipasarkan ke segmen SAR profesional |

---

## 12. Out of Scope (v1)

Fitur-fitur berikut secara sengaja **ditunda ke v2 atau versi berikutnya**:

| Fitur | Alasan Ditunda |
|---|---|
| **Voice/Audio Messaging** | Terlalu membebani bandwidth BLE; perlu kompresi audio yang kompleks |
| **File/Image Sharing** | Payload terlalu besar untuk WiFi Direct yang handal; edge case banyak |
| **Enkripsi end-to-end** | Menambah kompleksitas dan latency; prioritas v1.1 |
| **Offline map dengan pre-cached tiles** | Kompleksitas tinggi (storage, tile management UI); bisa ship sebagai standalone feature update |
| **GPS tracking real-time** (auto-broadcast lokasi) | Battery drain; privasi concern; out of scope untuk MVP |
| **Group check-in timer / heartbeat** | Nice-to-have; perlu UX yang matang |
| **SOS integration ke layanan resmi** | Terlalu kompleks, bukan core value proposition |
| **Backend cloud / sync** | Bertentangan dengan prinsip offline-first arsitektur v1 |
| **Multi-Language (non-ID/EN)** | Prioritaskan ID+EN dulu |
| **Targeted routing (non-flood)** | Flood routing cukup untuk mesh kecil (<30 node); targeted routing untuk v2 jika mesh lebih besar |
| **Push notification (background wakeup)** | Membutuhkan server relay; bertentangan dengan offline-first |
| **Dark mode** | Nice-to-have; bisa ditambah kapan saja |

---

## 13. Release Plan / Milestones

### Timeline MVP

```
Minggu 1–2:    Foundation & Infrastructure
Minggu 3–4:    Core Features (Discovery + Messaging)
Minggu 5–6:    Location Ping + Relay
Minggu 7:      Polish, Testing, Bug Fixing
Minggu 8:      Alpha Internal
Minggu 10–12:  Beta Terbatas (komunitas hiking)
Minggu 14–16:  Public Beta (Google Play Open Testing)
```

### Detail Milestones

#### 🔨 M1: Foundation (Minggu 1–2)
**Goal:** Project scaffold, dependency setup, architecture dasar

- [ ] Project Flutter setup (clean architecture: feature/domain/data layer)
- [ ] Drift setup: database class, table definitions, DAO, dan codegen (`build_runner`)
- [ ] Permission handling (Bluetooth, Location) untuk Android & iOS
- [ ] Nearby Connections plugin integration (Android) — discovery smoke test
- [ ] Basic UI shell (home screen, chat screen skeleton)
- [ ] CI/CD pipeline dasar (GitHub Actions: lint, test, build APK)

**Deliverable:** APK yang bisa menemukan device lain di sekitar

---

#### 🔨 M2: Core Messaging (Minggu 3–4)
**Goal:** Group creation, join, dan text messaging end-to-end

- [ ] Group create / join flow
- [ ] Real-time text messaging (direct connection, tanpa relay)
- [ ] Message persistence lokal via Drift (DAO `MessagesDao` + reactive stream untuk UI)
- [ ] Member list & online status
- [ ] PIN group (opsional)
- [ ] Unit tests untuk messaging logic

**Deliverable:** APK yang bisa chat grup antar 2+ device

---

#### 🔨 M3: Location + Relay (Minggu 5–6)
**Goal:** Location ping + multi-hop relay

- [ ] GPS permission + location capture
- [ ] Location ping sebagai pesan tipe khusus
- [ ] Mini-map view (flutter_map, offline-capable)
- [ ] Multi-hop relay dengan deduplikasi (UUID + TTL)
- [ ] Low-battery mode logic
- [ ] Integration tests relay (3 device simulasi)

**Deliverable:** APK dengan semua fitur MVP aktif

---

#### 🔨 M4: Polish & Alpha (Minggu 7–8)
**Goal:** Stabilitas, UX polish, dan alpha testing internal

- [ ] UX polish (animasi, loading states, error messages)
- [ ] Edge case handling (device disconnect tiba-tiba, GPS unavailable, bluetooth off)
- [ ] Pengujian di 5 merek Android berbeda
- [ ] Crash reporting lokal (opt-in)
- [ ] Onboarding flow final
- [ ] Alpha internal: 10–15 tester dari komunitas pendaki

**Deliverable:** Alpha APK — stable, semua core feature berjalan

---

#### 🔨 M5: Beta Terbatas (Minggu 10–12)
**Goal:** Validasi real-world dengan target users nyata

- [ ] Distribusi via Google Play Internal Testing + TestFlight (iOS)
- [ ] Field test di event komunitas (hiking day trip, mini festival)
- [ ] Feedback collection: in-app form + survey komunitas
- [ ] Iterasi berdasarkan feedback
- [ ] Performance profiling & battery optimization

**Deliverable:** Beta APK — validated di real-world scenario

---

#### 🚀 M6: Public Beta (Minggu 14–16)
**Goal:** Rilis ke publik luas, mulai community traction

- [ ] Google Play Open Testing (public)
- [ ] App Store TestFlight public link
- [ ] Landing page minimal
- [ ] Dokumentasi pengguna (FAQ, "Cara Pakai")
- [ ] Community seeding (posting di grup Facebook/Telegram hiking Indonesia)

**Deliverable:** v1.0 Public Beta — live di store

---

## 14. Decisions Log

> Semua open questions telah dijawab pada 7 Agustus 2026. Bagian ini menggantikan tabel "Open Questions" sebelumnya.

| # | Keputusan | Jawaban | Dampak ke PRD |
|---|---|---|---|
| D-01 | **Strategi iOS** | Android-only untuk MVP; iOS di v1.1 | Tidak ada code path iOS di M1–M6; iOS scope direncanakan terpisah |
| D-02 | **Ukuran grup maksimum** | Maks 30 device per grup | Flood routing tetap digunakan; tidak perlu gossip/targeted routing di v1 |
| D-03 | **Persistensi pesan** | Tersimpan 7 hari, auto-delete | Drift perlu scheduled cleanup job; tambahkan ke M2 |
| D-04 | **Aturan nickname** | Bisa diubah; harus unik dalam grup (validasi saat join) | Tambahkan AC-05.8: validasi keunikan nickname saat join grup |
| D-05 | **Offline map di MVP** | Tidak ada; location ping tampilkan koordinat + tombol 'Buka di Maps' | Hapus `flutter_map` dari M3; update AC-03.3 |
| D-06 | **SOS timing** | Ditunda ke v1.1 | FR-06 digeser ke Out of Scope; scope MVP lebih bersih |
| D-07 | **Bahasa UI** | Bilingual ID/EN dengan language toggle | Setup `flutter_localizations` + ARB files di M1 |
| D-08 | **Disclaimer hukum** | Wajib di-accept saat onboarding (sekali, disimpan SharedPreferences) | Tambahkan screen disclaimer di Flow 1 (Onboarding); store `hasAcceptedDisclaimer` flag |
| D-09 | **Flutter plugin** | Pakai `nearby_connections` pub.dev + abstraction layer `PeerDiscoveryService` | Interface abstraction memungkinkan swap ke custom wrapper tanpa ubah business logic |
| D-10 | **Monetisasi** | Freemium: fitur dasar gratis; SOS + offline map sebagai fitur premium di v1.1+ | Bangun feature flag system (`FeatureFlags` class) dari M1 untuk gate fitur premium |

---

### Implikasi Teknis dari Keputusan-Keputusan di Atas

**Tambahan ke M1 (Foundation):**
- Setup `flutter_localizations` + ARB files (ID & EN)
- Buat `FeatureFlags` class (untuk gating fitur premium masa depan)
- Buat abstraction interface `PeerDiscoveryService` (wrap `nearby_connections` package)
- Tambahkan screen disclaimer (sekali, dengan `hasAcceptedDisclaimer` di SharedPreferences)

**Tambahan ke M2 (Core Messaging):**
- Nickname uniqueness validation saat join grup
- Drift scheduled cleanup job: hapus pesan > 7 hari

**Perubahan ke M3 (Location + Relay):**
- ~~Mini-map view (flutter_map)~~ → Diganti dengan: card koordinat lat/lng + tombol "Buka di Maps" (deep link ke Google Maps/Apple Maps)

**SOS (FR-06) dipindahkan ke Out of Scope v1** — akan masuk roadmap v1.1 bersama offline map dan iOS support.

---

*PRD ini adalah dokumen hidup. Harap diperbarui setiap kali ada keputusan baru yang mengubah scope, requirement, atau arsitektur.*

---

**Changelog:**

| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0 | 7 Agustus 2026 | Initial draft |
| 1.1 | 7 Agustus 2026 | Update local storage: Hive → Drift |
| 1.2 | 7 Agustus 2026 | Semua 10 Open Questions dijawab dan dikonsolidasikan ke Decisions Log; implikasi teknis ditambahkan ke milestones |
