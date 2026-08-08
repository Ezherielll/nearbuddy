import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'NearBuddy'**
  String get appName;

  /// No description provided for @disclaimerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pemberitahuan Penting'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In id, this message translates to:
  /// **'NearBuddy adalah alat komunikasi komunitas, bukan pengganti layanan darurat resmi. Jangan andalkan aplikasi ini sebagai satu-satunya alat dalam situasi darurat.'**
  String get disclaimerBody;

  /// No description provided for @disclaimerAccept.
  ///
  /// In id, this message translates to:
  /// **'Saya mengerti'**
  String get disclaimerAccept;

  /// No description provided for @nicknameTitle.
  ///
  /// In id, this message translates to:
  /// **'Siapa namamu?'**
  String get nicknameTitle;

  /// No description provided for @nicknameHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama (3-20 karakter)'**
  String get nicknameHint;

  /// No description provided for @nicknameError.
  ///
  /// In id, this message translates to:
  /// **'Nama harus 3-20 karakter'**
  String get nicknameError;

  /// No description provided for @continueLabel.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get continueLabel;

  /// No description provided for @createGroup.
  ///
  /// In id, this message translates to:
  /// **'Buat grup'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In id, this message translates to:
  /// **'Gabung grup'**
  String get joinGroup;

  /// No description provided for @groupName.
  ///
  /// In id, this message translates to:
  /// **'Nama grup'**
  String get groupName;

  /// No description provided for @groupPin.
  ///
  /// In id, this message translates to:
  /// **'PIN grup (opsional)'**
  String get groupPin;

  /// No description provided for @nearbyGroups.
  ///
  /// In id, this message translates to:
  /// **'Grup di sekitar'**
  String get nearbyGroups;

  /// No description provided for @noNearbyGroups.
  ///
  /// In id, this message translates to:
  /// **'Belum ada grup. Buat grup baru atau tunggu.'**
  String get noNearbyGroups;

  /// No description provided for @send.
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get send;

  /// No description provided for @sendLocation.
  ///
  /// In id, this message translates to:
  /// **'Kirim lokasi'**
  String get sendLocation;

  /// No description provided for @sendLocationConfirm.
  ///
  /// In id, this message translates to:
  /// **'Kirim lokasimu sekarang?'**
  String get sendLocationConfirm;

  /// No description provided for @locationPingLabel.
  ///
  /// In id, this message translates to:
  /// **'Lokasi'**
  String get locationPingLabel;

  /// No description provided for @openInMaps.
  ///
  /// In id, this message translates to:
  /// **'Buka di Maps'**
  String get openInMaps;

  /// No description provided for @memberCount.
  ///
  /// In id, this message translates to:
  /// **'{count} anggota'**
  String memberCount(int count);

  /// No description provided for @messageSent.
  ///
  /// In id, this message translates to:
  /// **'Terkirim'**
  String get messageSent;

  /// No description provided for @messageDelivered.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get messageDelivered;

  /// No description provided for @lowBatteryMode.
  ///
  /// In id, this message translates to:
  /// **'Mode hemat aktif'**
  String get lowBatteryMode;

  /// No description provided for @permissionRequired.
  ///
  /// In id, this message translates to:
  /// **'Izin diperlukan'**
  String get permissionRequired;

  /// No description provided for @permissionExplanation.
  ///
  /// In id, this message translates to:
  /// **'NearBuddy membutuhkan izin Bluetooth dan lokasi untuk menemukan perangkat di dekatmu.'**
  String get permissionExplanation;

  /// No description provided for @grantPermission.
  ///
  /// In id, this message translates to:
  /// **'Izinkan'**
  String get grantPermission;

  /// No description provided for @nicknameInUse.
  ///
  /// In id, this message translates to:
  /// **'Nama sudah dipakai anggota lain. Pilih nama lain.'**
  String get nicknameInUse;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @changeNickname.
  ///
  /// In id, this message translates to:
  /// **'Ganti nama'**
  String get changeNickname;

  /// No description provided for @leaveGroup.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari grup'**
  String get leaveGroup;

  /// No description provided for @members.
  ///
  /// In id, this message translates to:
  /// **'Anggota'**
  String get members;

  /// No description provided for @verifyTitle.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi perangkat'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In id, this message translates to:
  /// **'Kedua perangkat harus menampilkan angka yang sama:'**
  String get verifyBody;

  /// No description provided for @verifyMatch.
  ///
  /// In id, this message translates to:
  /// **'Angka cocok'**
  String get verifyMatch;

  /// No description provided for @verifyMismatch.
  ///
  /// In id, this message translates to:
  /// **'Tidak cocok'**
  String get verifyMismatch;

  /// No description provided for @groupCode.
  ///
  /// In id, this message translates to:
  /// **'Kode grup'**
  String get groupCode;

  /// No description provided for @pinError.
  ///
  /// In id, this message translates to:
  /// **'PIN minimal 4 digit'**
  String get pinError;

  /// No description provided for @groupCodeHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode'**
  String get groupCodeHint;

  /// No description provided for @dmSessions.
  ///
  /// In id, this message translates to:
  /// **'Pesan pribadi'**
  String get dmSessions;

  /// No description provided for @dmNew.
  ///
  /// In id, this message translates to:
  /// **'Percakapan baru'**
  String get dmNew;

  /// No description provided for @dmEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada percakapan. Mulai dari daftar anggota atau masukkan ID perangkat.'**
  String get dmEmpty;

  /// No description provided for @dmPeerDeviceId.
  ///
  /// In id, this message translates to:
  /// **'ID perangkat'**
  String get dmPeerDeviceId;

  /// No description provided for @dmPeerNickname.
  ///
  /// In id, this message translates to:
  /// **'Nama kontak'**
  String get dmPeerNickname;

  /// No description provided for @dmKeyMissing.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kunci perangkat — coba lagi setelah verifikasi grup'**
  String get dmKeyMissing;

  /// No description provided for @decryptFailed.
  ///
  /// In id, this message translates to:
  /// **'Pesan ini tidak dapat dibaca'**
  String get decryptFailed;

  /// No description provided for @deviceIdLabel.
  ///
  /// In id, this message translates to:
  /// **'ID perangkat'**
  String get deviceIdLabel;

  /// No description provided for @permissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin Bluetooth dan lokasi diperlukan untuk menemukan perangkat di sekitar.'**
  String get permissionDenied;

  /// No description provided for @sessionStartFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memulai sesi — periksa Bluetooth/Wi-Fi dan coba lagi.'**
  String get sessionStartFailed;

  /// No description provided for @nicknameSaved.
  ///
  /// In id, this message translates to:
  /// **'Nama diperbarui'**
  String get nicknameSaved;

  /// No description provided for @tagline.
  ///
  /// In id, this message translates to:
  /// **'Chat tanpa internet, tanpa server.'**
  String get tagline;

  /// No description provided for @readyStatus.
  ///
  /// In id, this message translates to:
  /// **'Siap terhubung langsung'**
  String get readyStatus;

  /// No description provided for @readyStatusDesc.
  ///
  /// In id, this message translates to:
  /// **'Semua pesan terenkripsi dan hanya tersimpan di perangkat ini.'**
  String get readyStatusDesc;

  /// No description provided for @createGroupDesc.
  ///
  /// In id, this message translates to:
  /// **'Buat ruang untuk berkomunikasi tanpa internet.'**
  String get createGroupDesc;

  /// No description provided for @joinGroupDesc.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode grup untuk bergabung.'**
  String get joinGroupDesc;

  /// No description provided for @dmSessionsDesc.
  ///
  /// In id, this message translates to:
  /// **'Chat langsung dengan perangkat di sekitar.'**
  String get dmSessionsDesc;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai percakapan pertama'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDesc.
  ///
  /// In id, this message translates to:
  /// **'Buat grup atau gabung dengan kode — tidak ada data yang keluar dari perangkat.'**
  String get homeEmptyDesc;

  /// No description provided for @disclaimerBullet1.
  ///
  /// In id, this message translates to:
  /// **'Berfungsi tanpa internet atau sinyal seluler'**
  String get disclaimerBullet1;

  /// No description provided for @disclaimerBullet2.
  ///
  /// In id, this message translates to:
  /// **'Semua pesan terenkripsi end-to-end'**
  String get disclaimerBullet2;

  /// No description provided for @disclaimerBullet3.
  ///
  /// In id, this message translates to:
  /// **'Bukan pengganti layanan darurat resmi'**
  String get disclaimerBullet3;

  /// No description provided for @encryptedLabel.
  ///
  /// In id, this message translates to:
  /// **'Terenkripsi'**
  String get encryptedLabel;

  /// No description provided for @todayLabel.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get yesterdayLabel;

  /// No description provided for @copyCode.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In id, this message translates to:
  /// **'Kode disalin.'**
  String get codeCopied;

  /// No description provided for @sendMessageTooltip.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesan'**
  String get sendMessageTooltip;

  /// No description provided for @sendLocationTooltip.
  ///
  /// In id, this message translates to:
  /// **'Kirim lokasi'**
  String get sendLocationTooltip;

  /// No description provided for @groupSection.
  ///
  /// In id, this message translates to:
  /// **'Umum'**
  String get groupSection;

  /// No description provided for @identitySection.
  ///
  /// In id, this message translates to:
  /// **'Identitas'**
  String get identitySection;

  /// No description provided for @securitySection.
  ///
  /// In id, this message translates to:
  /// **'Keamanan'**
  String get securitySection;

  /// No description provided for @verifiedDevice.
  ///
  /// In id, this message translates to:
  /// **'Perangkat terverifikasi'**
  String get verifiedDevice;

  /// No description provided for @verifyCopyHint.
  ///
  /// In id, this message translates to:
  /// **'Kedua perangkat harus menampilkan angka yang sama. Cocokkan sebelum melanjutkan.'**
  String get verifyCopyHint;

  /// No description provided for @connConnected.
  ///
  /// In id, this message translates to:
  /// **'Terhubung langsung'**
  String get connConnected;

  /// No description provided for @connSearching.
  ///
  /// In id, this message translates to:
  /// **'Mencari perangkat…'**
  String get connSearching;

  /// No description provided for @connOutOfRange.
  ///
  /// In id, this message translates to:
  /// **'Di luar jangkauan — kirim ulang saat terhubung'**
  String get connOutOfRange;

  /// No description provided for @connRadioOff.
  ///
  /// In id, this message translates to:
  /// **'Bluetooth/Wi-Fi mati — aktifkan untuk terhubung'**
  String get connRadioOff;

  /// No description provided for @devicesFound.
  ///
  /// In id, this message translates to:
  /// **'{count} perangkat di sekitar'**
  String devicesFound(int count);

  /// No description provided for @devicesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perangkat di sekitar. Pastikan Bluetooth/Wi-Fi aktif.'**
  String get devicesEmpty;

  /// No description provided for @devicesNearbySection.
  ///
  /// In id, this message translates to:
  /// **'Perangkat di sekitar'**
  String get devicesNearbySection;

  /// No description provided for @deviceDetected.
  ///
  /// In id, this message translates to:
  /// **'terdeteksi'**
  String get deviceDetected;

  /// No description provided for @pinWrong.
  ///
  /// In id, this message translates to:
  /// **'PIN salah — coba lagi'**
  String get pinWrong;

  /// No description provided for @noDevicesFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada perangkat ditemukan'**
  String get noDevicesFound;

  /// No description provided for @retryLabel.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retryLabel;

  /// No description provided for @typingIndicator.
  ///
  /// In id, this message translates to:
  /// **'sedang mengetik…'**
  String get typingIndicator;

  /// No description provided for @leaveConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari grup?'**
  String get leaveConfirmTitle;

  /// No description provided for @leaveConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Kamu tidak akan menerima pesan dari grup ini lagi.'**
  String get leaveConfirmBody;

  /// No description provided for @leaveLabel.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get leaveLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancelLabel;

  /// No description provided for @deviceIdHelp.
  ///
  /// In id, this message translates to:
  /// **'Digunakan untuk mengenali perangkat di jaringan lokal.'**
  String get deviceIdHelp;

  /// No description provided for @securityDesc.
  ///
  /// In id, this message translates to:
  /// **'Pesan dienkripsi selama komunikasi.'**
  String get securityDesc;

  /// No description provided for @messagePending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu koneksi'**
  String get messagePending;

  /// No description provided for @messageFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal — ketuk untuk kirim ulang'**
  String get messageFailed;

  /// No description provided for @connConnecting.
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan…'**
  String get connConnecting;

  /// No description provided for @connDisconnected.
  ///
  /// In id, this message translates to:
  /// **'Tidak terhubung'**
  String get connDisconnected;

  /// No description provided for @devicesAvailable.
  ///
  /// In id, this message translates to:
  /// **'Tersedia'**
  String get devicesAvailable;

  /// No description provided for @devicesConnected.
  ///
  /// In id, this message translates to:
  /// **'Terhubung'**
  String get devicesConnected;

  /// No description provided for @devicesEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada perangkat di sekitar'**
  String get devicesEmptyTitle;

  /// No description provided for @devicesEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Pastikan NearBuddy aktif di perangkat temanmu.'**
  String get devicesEmptyHint;

  /// No description provided for @searchAgain.
  ///
  /// In id, this message translates to:
  /// **'Cari lagi'**
  String get searchAgain;

  /// No description provided for @seeAllDevices.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua perangkat'**
  String get seeAllDevices;

  /// No description provided for @communicationSection.
  ///
  /// In id, this message translates to:
  /// **'Komunikasi'**
  String get communicationSection;

  /// No description provided for @myGroupsSection.
  ///
  /// In id, this message translates to:
  /// **'Grup saya'**
  String get myGroupsSection;

  /// No description provided for @inviteDevices.
  ///
  /// In id, this message translates to:
  /// **'Undang perangkat'**
  String get inviteDevices;

  /// No description provided for @inviteDevicesHint.
  ///
  /// In id, this message translates to:
  /// **'Perangkat terpilih akan terhubung otomatis saat bergabung.'**
  String get inviteDevicesHint;

  /// No description provided for @startChat.
  ///
  /// In id, this message translates to:
  /// **'Mulai chat'**
  String get startChat;

  /// No description provided for @connectingTo.
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan ke {name}…'**
  String connectingTo(String name);

  /// No description provided for @creatingGroup.
  ///
  /// In id, this message translates to:
  /// **'Membuat grup…'**
  String get creatingGroup;

  /// No description provided for @groupNotFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat menemukan grup'**
  String get groupNotFound;

  /// No description provided for @groupNotFoundHint.
  ///
  /// In id, this message translates to:
  /// **'Pastikan kode grup benar dan pemilik grup sedang aktif.'**
  String get groupNotFoundHint;

  /// No description provided for @connectionLost.
  ///
  /// In id, this message translates to:
  /// **'Koneksi dengan {name} terputus'**
  String connectionLost(String name);

  /// No description provided for @messageWillWait.
  ///
  /// In id, this message translates to:
  /// **'Pesan akan ditandai menunggu — ketuk pesan untuk kirim ulang.'**
  String get messageWillWait;

  /// No description provided for @deviceIdCopied.
  ///
  /// In id, this message translates to:
  /// **'ID perangkat disalin.'**
  String get deviceIdCopied;

  /// No description provided for @securityTitle.
  ///
  /// In id, this message translates to:
  /// **'Keamanan pesan'**
  String get securityTitle;

  /// No description provided for @securityBody.
  ///
  /// In id, this message translates to:
  /// **'Pesan dienkripsi saat dikirim dan disimpan hanya di perangkat ini.'**
  String get securityBody;

  /// No description provided for @learnSecurity.
  ///
  /// In id, this message translates to:
  /// **'Pelajari cara kerja keamanan'**
  String get learnSecurity;

  /// No description provided for @securityDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Cara kerja keamanan'**
  String get securityDialogTitle;

  /// No description provided for @securityDialogBody.
  ///
  /// In id, this message translates to:
  /// **'NearBuddy memakai kunci X25519 per perangkat, verifikasi 6 angka, dan enkripsi AES-GCM. Perangkat perantara hanya meneruskan pesan — tidak bisa membacanya.'**
  String get securityDialogBody;

  /// No description provided for @pendingConnectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Menunggu koneksi'**
  String get pendingConnectionLabel;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai percakapan'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesan pertama ke {name}.'**
  String chatEmptyBody(String name);

  /// No description provided for @settingsProfileHint.
  ///
  /// In id, this message translates to:
  /// **'Nama yang terlihat oleh perangkat lain'**
  String get settingsProfileHint;

  /// No description provided for @settingsChangeNickname.
  ///
  /// In id, this message translates to:
  /// **'Ganti nama'**
  String get settingsChangeNickname;

  /// No description provided for @aboutSection.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String appVersion(String version);

  /// No description provided for @aboutNearBuddy.
  ///
  /// In id, this message translates to:
  /// **'Tentang NearBuddy'**
  String get aboutNearBuddy;

  /// No description provided for @encryptionRow.
  ///
  /// In id, this message translates to:
  /// **'Enkripsi'**
  String get encryptionRow;

  /// No description provided for @encryptionRowSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pesan dienkripsi selama komunikasi'**
  String get encryptionRowSubtitle;

  /// No description provided for @appearanceSection.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get appearanceSection;

  /// No description provided for @themeLabel.
  ///
  /// In id, this message translates to:
  /// **'Tema'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Mengikuti sistem'**
  String get themeSystem;

  /// No description provided for @menuDisconnect.
  ///
  /// In id, this message translates to:
  /// **'Putuskan'**
  String get menuDisconnect;

  /// No description provided for @menuEncryptedInfo.
  ///
  /// In id, this message translates to:
  /// **'Terenkripsi end-to-end · koneksi langsung'**
  String get menuEncryptedInfo;

  /// No description provided for @connError.
  ///
  /// In id, this message translates to:
  /// **'Koneksi gagal'**
  String get connError;

  /// No description provided for @emojiPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Emoji'**
  String get emojiPickerTitle;

  /// No description provided for @emojiCatSmileys.
  ///
  /// In id, this message translates to:
  /// **'Senyum & Ekspresi'**
  String get emojiCatSmileys;

  /// No description provided for @emojiCatGestures.
  ///
  /// In id, this message translates to:
  /// **'Gestur & Tangan'**
  String get emojiCatGestures;

  /// No description provided for @emojiCatHearts.
  ///
  /// In id, this message translates to:
  /// **'Hati'**
  String get emojiCatHearts;

  /// No description provided for @emojiCatAnimals.
  ///
  /// In id, this message translates to:
  /// **'Hewan & Makanan'**
  String get emojiCatAnimals;

  /// No description provided for @emojiCatSymbols.
  ///
  /// In id, this message translates to:
  /// **'Simbol'**
  String get emojiCatSymbols;

  /// No description provided for @languageDialogSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih bahasa antarmuka'**
  String get languageDialogSubtitle;

  /// No description provided for @themeSheetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih tampilan aplikasi'**
  String get themeSheetSubtitle;

  /// No description provided for @themeLightDesc.
  ///
  /// In id, this message translates to:
  /// **'Tampilan cerah dan bersih'**
  String get themeLightDesc;

  /// No description provided for @themeDarkDesc.
  ///
  /// In id, this message translates to:
  /// **'Nyaman di kondisi minim cahaya'**
  String get themeDarkDesc;

  /// No description provided for @themeSystemDesc.
  ///
  /// In id, this message translates to:
  /// **'Mengikuti mode perangkat'**
  String get themeSystemDesc;

  /// No description provided for @applyLabel.
  ///
  /// In id, this message translates to:
  /// **'Terapkan'**
  String get applyLabel;

  /// No description provided for @messageHint.
  ///
  /// In id, this message translates to:
  /// **'Tulis pesan…'**
  String get messageHint;

  /// No description provided for @secureDirectTagline.
  ///
  /// In id, this message translates to:
  /// **'Secure. Private. Direct.'**
  String get secureDirectTagline;

  /// No description provided for @aboutBody.
  ///
  /// In id, this message translates to:
  /// **'NearBuddy adalah aplikasi pesan peer-to-peer yang bekerja tanpa internet maupun sinyal seluler. Pesan dienkripsi dan hanya tersimpan di perangkatmu.'**
  String get aboutBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
