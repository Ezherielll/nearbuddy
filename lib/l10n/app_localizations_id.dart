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
}
