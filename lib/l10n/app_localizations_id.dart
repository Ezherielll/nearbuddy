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
  String get disclaimerAccept => 'Saya Mengerti';

  @override
  String get nicknameTitle => 'Siapa namamu?';

  @override
  String get nicknameHint => 'Masukkan nickname (3-20 karakter)';

  @override
  String get nicknameError => 'Nickname harus 3-20 karakter';

  @override
  String get continueLabel => 'Lanjut';

  @override
  String get createGroup => 'Buat Grup';

  @override
  String get joinGroup => 'Gabung Grup';

  @override
  String get groupName => 'Nama Grup';

  @override
  String get groupPin => 'PIN Grup (opsional)';

  @override
  String get nearbyGroups => 'Grup di Sekitar';

  @override
  String get noNearbyGroups =>
      'Tidak ada grup ditemukan. Buat grup baru atau tunggu.';

  @override
  String get send => 'Kirim';

  @override
  String get sendLocation => 'Kirim Lokasi Saya';

  @override
  String get sendLocationConfirm => 'Kirim koordinat lokasi Anda sekarang?';

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
  String get lowBatteryMode => 'Mode Hemat Aktif';

  @override
  String get permissionRequired => 'Izin Diperlukan';

  @override
  String get permissionExplanation =>
      'NearBuddy memerlukan izin Bluetooth dan Lokasi untuk menemukan perangkat di sekitar.';

  @override
  String get grantPermission => 'Berikan Izin';

  @override
  String get nicknameInUse =>
      'Nickname sudah dipakai anggota lain. Pilih nama lain.';

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get changeNickname => 'Ganti Nickname';

  @override
  String get leaveGroup => 'Keluar dari Grup';

  @override
  String get members => 'Anggota';

  @override
  String get verifyTitle => 'Verifikasi Perangkat';

  @override
  String get verifyBody => 'Kedua perangkat harus menampilkan angka yang sama:';

  @override
  String get verifyMatch => 'Angka Cocok';

  @override
  String get verifyMismatch => 'Tidak Cocok';

  @override
  String get groupCode => 'Kode Grup';

  @override
  String get pinError => 'PIN minimal 4 digit';

  @override
  String get groupCodeHint => 'Masukkan kode grup untuk bergabung';

  @override
  String get dmSessions => 'Pesan Pribadi';

  @override
  String get dmNew => 'Percakapan Baru';

  @override
  String get dmEmpty =>
      'Belum ada percakapan. Mulai dari daftar anggota atau masukkan ID perangkat.';

  @override
  String get dmPeerDeviceId => 'ID Perangkat';

  @override
  String get dmPeerNickname => 'Nama Kontak';

  @override
  String get dmKeyMissing =>
      'Belum ada kunci perangkat — coba lagi setelah verifikasi grup';

  @override
  String get decryptFailed => 'Tidak dapat mendekripsi pesan ini';

  @override
  String get deviceIdLabel => 'ID Perangkat';

  @override
  String get permissionDenied =>
      'Izin Bluetooth/Lokasi diperlukan untuk menemukan perangkat di sekitar.';

  @override
  String get sessionStartFailed =>
      'Gagal memulai sesi — periksa Bluetooth/WiFi dan coba lagi.';

  @override
  String get nicknameSaved => 'Nickname diperbarui';

  @override
  String get tagline => 'Chat tanpa internet, tanpa server.';

  @override
  String get readyStatus => 'Siap terhubung langsung';

  @override
  String get readyStatusDesc =>
      'Semua pesan terenkripsi dan tetap di perangkat ini.';

  @override
  String get createGroupDesc => 'Buat ruang baru, dengan PIN opsional';

  @override
  String get joinGroupDesc => 'Masuk ke grup dengan kode';

  @override
  String get dmSessionsDesc => 'Percakapan 1:1 terenkripsi end-to-end';

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
  String get encryptedLabel => 'Terenskripsi';

  @override
  String get todayLabel => 'Hari ini';

  @override
  String get yesterdayLabel => 'Kemarin';

  @override
  String get copyCode => 'Salin';

  @override
  String get codeCopied => 'Kode disalin';

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
  String get connOutOfRange =>
      'Di luar jangkauan — pesan terkirim otomatis saat terhubung';

  @override
  String get connRadioOff => 'Bluetooth/Wi-Fi mati — aktifkan untuk terhubung';

  @override
  String devicesFound(int count) {
    return '$count perangkat di sekitar';
  }

  @override
  String get devicesEmpty =>
      'Belum ada perangkat terdeteksi di sekitar. Pastikan Bluetooth/Wi-Fi aktif.';

  @override
  String get devicesNearbySection => 'Perangkat di Sekitar';

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
  String get leaveConfirmBody => 'Pesan lama tetap tersimpan di perangkat ini.';

  @override
  String get leaveLabel => 'Keluar';

  @override
  String get cancelLabel => 'Batal';

  @override
  String get deviceIdHelp =>
      'Bagikan ID ini untuk memulai percakapan 1:1, atau gunakan untuk dukungan teknis.';

  @override
  String get securityDesc =>
      'X25519 + AES-GCM end-to-end — relay tidak bisa membaca pesan.';

  @override
  String get messagePending => 'Menunggu perangkat';

  @override
  String get messageFailed => 'Gagal — tap untuk kirim ulang';

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
  String get myGroupsSection => 'Grup Saya';

  @override
  String get inviteDevices => 'Undang perangkat';

  @override
  String get inviteDevicesHint =>
      'Perangkat terpilih akan terhubung otomatis saat bergabung.';

  @override
  String get startChat => 'Mulai Chat';

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
      'Pesan akan ditandai menunggu — ketuk ikon untuk kirim ulang.';

  @override
  String get deviceIdCopied => 'ID perangkat disalin.';

  @override
  String get securityTitle => 'Keamanan pesan';

  @override
  String get securityBody =>
      'Pesan dienkripsi dan disimpan secara lokal di perangkat ini.';

  @override
  String get learnSecurity => 'Pelajari cara kerja keamanan';

  @override
  String get securityDialogTitle => 'Cara kerja keamanan';

  @override
  String get securityDialogBody =>
      'NearBuddy menggunakan kunci X25519 per perangkat dengan verifikasi 6 angka, dan pesan dienkripsi AES-GCM. Perangkat perantara hanya meneruskan pesan tanpa bisa membacanya.';

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
  String get settingsChangeNickname => 'Ganti nickname';

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
  String get encryptionRowSubtitle =>
      'Pesan terenkripsi dan disimpan secara lokal';

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
}
