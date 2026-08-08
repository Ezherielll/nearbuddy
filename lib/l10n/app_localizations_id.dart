// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'NearBuddy';

  @override
  String get disclaimerTitle => 'Pemberitahuan Penting';

  @override
  String get disclaimerBody =>
      'NearBuddy adalah alat komunikasi komunitas, bukan pengganti layanan darurat resmi. Jangan andalkan aplikasi ini sebagai satu-satunya alat dalam situasi darurat.';

  @override
  String get disclaimerAccept => 'Saya mengerti';

  @override
  String get nicknameTitle => 'Siapa namamu?';

  @override
  String get nicknameHint => 'Masukkan nama (3-20 karakter)';

  @override
  String get nicknameError => 'Nama harus 3-20 karakter';

  @override
  String get continueLabel => 'Lanjut';

  @override
  String get createGroup => 'Buat grup';

  @override
  String get joinGroup => 'Gabung grup';

  @override
  String get groupName => 'Nama grup';

  @override
  String get groupPin => 'PIN grup (opsional)';

  @override
  String get nearbyGroups => 'Grup di sekitar';

  @override
  String get noNearbyGroups => 'Belum ada grup. Buat grup baru atau tunggu.';

  @override
  String get send => 'Kirim';

  @override
  String get sendLocation => 'Kirim lokasi';

  @override
  String get sendLocationConfirm => 'Kirim lokasimu sekarang?';

  @override
  String get locationPingLabel => 'Lokasi';

  @override
  String get openInMaps => 'Buka di Maps';

  @override
  String memberCount(int count) {
    return '$count anggota';
  }

  @override
  String get messageSent => 'Terkirim';

  @override
  String get messageDelivered => 'Diterima';

  @override
  String get lowBatteryMode => 'Mode hemat aktif';

  @override
  String get permissionRequired => 'Izin diperlukan';

  @override
  String get permissionExplanation =>
      'NearBuddy membutuhkan izin Bluetooth dan lokasi untuk menemukan perangkat di dekatmu.';

  @override
  String get grantPermission => 'Izinkan';

  @override
  String get nicknameInUse =>
      'Nama sudah dipakai anggota lain. Pilih nama lain.';

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get changeNickname => 'Ganti nama';

  @override
  String get leaveGroup => 'Keluar dari grup';

  @override
  String get members => 'Anggota';

  @override
  String get verifyTitle => 'Verifikasi perangkat';

  @override
  String get verifyBody => 'Kedua perangkat harus menampilkan angka yang sama:';

  @override
  String get verifyMatch => 'Angka cocok';

  @override
  String get verifyMismatch => 'Tidak cocok';

  @override
  String get groupCode => 'Kode grup';

  @override
  String get pinError => 'PIN minimal 4 digit';

  @override
  String get groupCodeHint => 'Masukkan kode';

  @override
  String get dmSessions => 'Pesan pribadi';

  @override
  String get dmNew => 'Percakapan baru';

  @override
  String get dmEmpty =>
      'Belum ada percakapan. Mulai dari daftar anggota atau masukkan ID perangkat.';

  @override
  String get dmPeerDeviceId => 'ID perangkat';

  @override
  String get dmPeerNickname => 'Nama kontak';

  @override
  String get dmKeyMissing =>
      'Belum ada kunci perangkat — coba lagi setelah verifikasi grup';

  @override
  String get decryptFailed => 'Pesan ini tidak dapat dibaca';

  @override
  String get deviceIdLabel => 'ID perangkat';

  @override
  String get permissionDenied =>
      'Izin Bluetooth dan lokasi diperlukan untuk menemukan perangkat di sekitar.';

  @override
  String get sessionStartFailed =>
      'Gagal memulai sesi — periksa Bluetooth/Wi-Fi dan coba lagi.';

  @override
  String get nicknameSaved => 'Nama diperbarui';

  @override
  String get tagline => 'Chat tanpa internet, tanpa server.';

  @override
  String get readyStatus => 'Siap terhubung langsung';

  @override
  String get readyStatusDesc =>
      'Semua pesan terenkripsi dan hanya tersimpan di perangkat ini.';

  @override
  String get createGroupDesc =>
      'Buat ruang untuk berkomunikasi tanpa internet.';

  @override
  String get joinGroupDesc => 'Masukkan kode grup untuk bergabung.';

  @override
  String get dmSessionsDesc => 'Chat langsung dengan perangkat di sekitar.';

  @override
  String get homeEmptyTitle => 'Mulai percakapan pertama';

  @override
  String get homeEmptyDesc =>
      'Buat grup atau gabung dengan kode — tidak ada data yang keluar dari perangkat.';

  @override
  String get disclaimerBullet1 =>
      'Berfungsi tanpa internet atau sinyal seluler';

  @override
  String get disclaimerBullet2 => 'Semua pesan terenkripsi end-to-end';

  @override
  String get disclaimerBullet3 => 'Bukan pengganti layanan darurat resmi';

  @override
  String get encryptedLabel => 'Terenkripsi';

  @override
  String get todayLabel => 'Hari ini';

  @override
  String get yesterdayLabel => 'Kemarin';

  @override
  String get copyCode => 'Salin';

  @override
  String get codeCopied => 'Kode disalin.';

  @override
  String get sendMessageTooltip => 'Kirim pesan';

  @override
  String get sendLocationTooltip => 'Kirim lokasi';

  @override
  String get groupSection => 'Umum';

  @override
  String get identitySection => 'Identitas';

  @override
  String get securitySection => 'Keamanan';

  @override
  String get verifiedDevice => 'Perangkat terverifikasi';

  @override
  String get verifyCopyHint =>
      'Kedua perangkat harus menampilkan angka yang sama. Cocokkan sebelum melanjutkan.';

  @override
  String get connConnected => 'Terhubung langsung';

  @override
  String get connSearching => 'Mencari perangkat…';

  @override
  String get connOutOfRange => 'Di luar jangkauan — kirim ulang saat terhubung';

  @override
  String get connRadioOff => 'Bluetooth/Wi-Fi mati — aktifkan untuk terhubung';

  @override
  String devicesFound(int count) {
    return '$count perangkat di sekitar';
  }

  @override
  String get devicesEmpty =>
      'Belum ada perangkat di sekitar. Pastikan Bluetooth/Wi-Fi aktif.';

  @override
  String get devicesNearbySection => 'Perangkat di sekitar';

  @override
  String get deviceDetected => 'terdeteksi';

  @override
  String get pinWrong => 'PIN salah — coba lagi';

  @override
  String get noDevicesFound => 'Tidak ada perangkat ditemukan';

  @override
  String get retryLabel => 'Coba lagi';

  @override
  String get typingIndicator => 'sedang mengetik…';

  @override
  String get leaveConfirmTitle => 'Keluar dari grup?';

  @override
  String get leaveConfirmBody =>
      'Kamu tidak akan menerima pesan dari grup ini lagi.';

  @override
  String get leaveLabel => 'Keluar';

  @override
  String get cancelLabel => 'Batal';

  @override
  String get deviceIdHelp =>
      'Digunakan untuk mengenali perangkat di jaringan lokal.';

  @override
  String get securityDesc => 'Pesan dienkripsi selama komunikasi.';

  @override
  String get messagePending => 'Menunggu koneksi';

  @override
  String get messageFailed => 'Gagal — ketuk untuk kirim ulang';

  @override
  String get connConnecting => 'Menghubungkan…';

  @override
  String get connDisconnected => 'Tidak terhubung';

  @override
  String get devicesAvailable => 'Tersedia';

  @override
  String get devicesConnected => 'Terhubung';

  @override
  String get devicesEmptyTitle => 'Belum ada perangkat di sekitar';

  @override
  String get devicesEmptyHint =>
      'Pastikan NearBuddy aktif di perangkat temanmu.';

  @override
  String get searchAgain => 'Cari lagi';

  @override
  String get seeAllDevices => 'Lihat semua perangkat';

  @override
  String get communicationSection => 'Komunikasi';

  @override
  String get myGroupsSection => 'Grup saya';

  @override
  String get inviteDevices => 'Undang perangkat';

  @override
  String get inviteDevicesHint =>
      'Perangkat terpilih akan terhubung otomatis saat bergabung.';

  @override
  String get startChat => 'Mulai chat';

  @override
  String connectingTo(String name) {
    return 'Menghubungkan ke $name…';
  }

  @override
  String get creatingGroup => 'Membuat grup…';

  @override
  String get groupNotFound => 'Tidak dapat menemukan grup';

  @override
  String get groupNotFoundHint =>
      'Pastikan kode grup benar dan pemilik grup sedang aktif.';

  @override
  String connectionLost(String name) {
    return 'Koneksi dengan $name terputus';
  }

  @override
  String get messageWillWait =>
      'Pesan akan ditandai menunggu — ketuk pesan untuk kirim ulang.';

  @override
  String get deviceIdCopied => 'ID perangkat disalin.';

  @override
  String get securityTitle => 'Keamanan pesan';

  @override
  String get securityBody =>
      'Pesan dienkripsi saat dikirim dan disimpan hanya di perangkat ini.';

  @override
  String get learnSecurity => 'Pelajari cara kerja keamanan';

  @override
  String get securityDialogTitle => 'Cara kerja keamanan';

  @override
  String get securityDialogBody =>
      'NearBuddy memakai kunci X25519 per perangkat, verifikasi 6 angka, dan enkripsi AES-GCM. Perangkat perantara hanya meneruskan pesan — tidak bisa membacanya.';

  @override
  String get pendingConnectionLabel => 'Menunggu koneksi';

  @override
  String get chatEmptyTitle => 'Mulai percakapan';

  @override
  String chatEmptyBody(String name) {
    return 'Kirim pesan pertama ke $name.';
  }

  @override
  String get settingsProfileHint => 'Nama yang terlihat oleh perangkat lain';

  @override
  String get settingsChangeNickname => 'Ganti nama';

  @override
  String get aboutSection => 'Tentang';

  @override
  String appVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get aboutNearBuddy => 'Tentang NearBuddy';

  @override
  String get encryptionRow => 'Enkripsi';

  @override
  String get encryptionRowSubtitle => 'Pesan dienkripsi selama komunikasi';

  @override
  String get appearanceSection => 'Tampilan';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeSystem => 'Mengikuti sistem';

  @override
  String get menuDisconnect => 'Putuskan';

  @override
  String get menuEncryptedInfo => 'Terenkripsi end-to-end · koneksi langsung';

  @override
  String get connError => 'Koneksi gagal';

  @override
  String get emojiPickerTitle => 'Emoji';

  @override
  String get emojiCatSmileys => 'Senyum & Ekspresi';

  @override
  String get emojiCatGestures => 'Gestur & Tangan';

  @override
  String get emojiCatHearts => 'Hati';

  @override
  String get emojiCatAnimals => 'Hewan & Makanan';

  @override
  String get emojiCatSymbols => 'Simbol';

  @override
  String get languageDialogSubtitle => 'Pilih bahasa antarmuka';

  @override
  String get themeSheetSubtitle => 'Pilih tampilan aplikasi';

  @override
  String get themeLightDesc => 'Tampilan cerah dan bersih';

  @override
  String get themeDarkDesc => 'Nyaman di kondisi minim cahaya';

  @override
  String get themeSystemDesc => 'Mengikuti mode perangkat';

  @override
  String get applyLabel => 'Terapkan';

  @override
  String get messageHint => 'Tulis pesan…';

  @override
  String get secureDirectTagline => 'Secure. Private. Direct.';

  @override
  String get aboutBody =>
      'NearBuddy adalah aplikasi pesan peer-to-peer yang bekerja tanpa internet maupun sinyal seluler. Pesan dienkripsi dan hanya tersimpan di perangkatmu.';
}
