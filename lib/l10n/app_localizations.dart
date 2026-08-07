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
  /// **'Saya Mengerti'**
  String get disclaimerAccept;

  /// No description provided for @nicknameTitle.
  ///
  /// In id, this message translates to:
  /// **'Siapa namamu?'**
  String get nicknameTitle;

  /// No description provided for @nicknameHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nickname (3-20 karakter)'**
  String get nicknameHint;

  /// No description provided for @nicknameError.
  ///
  /// In id, this message translates to:
  /// **'Nickname harus 3-20 karakter'**
  String get nicknameError;

  /// No description provided for @continueLabel.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get continueLabel;

  /// No description provided for @createGroup.
  ///
  /// In id, this message translates to:
  /// **'Buat Grup'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In id, this message translates to:
  /// **'Gabung Grup'**
  String get joinGroup;

  /// No description provided for @groupName.
  ///
  /// In id, this message translates to:
  /// **'Nama Grup'**
  String get groupName;

  /// No description provided for @groupPin.
  ///
  /// In id, this message translates to:
  /// **'PIN Grup (opsional)'**
  String get groupPin;

  /// No description provided for @nearbyGroups.
  ///
  /// In id, this message translates to:
  /// **'Grup di Sekitar'**
  String get nearbyGroups;

  /// No description provided for @noNearbyGroups.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada grup ditemukan. Buat grup baru atau tunggu.'**
  String get noNearbyGroups;

  /// No description provided for @send.
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get send;

  /// No description provided for @sendLocation.
  ///
  /// In id, this message translates to:
  /// **'Kirim Lokasi Saya'**
  String get sendLocation;

  /// No description provided for @sendLocationConfirm.
  ///
  /// In id, this message translates to:
  /// **'Kirim koordinat lokasi Anda sekarang?'**
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
  /// **'Mode Hemat Aktif'**
  String get lowBatteryMode;

  /// No description provided for @permissionRequired.
  ///
  /// In id, this message translates to:
  /// **'Izin Diperlukan'**
  String get permissionRequired;

  /// No description provided for @permissionExplanation.
  ///
  /// In id, this message translates to:
  /// **'NearBuddy memerlukan izin Bluetooth dan Lokasi untuk menemukan perangkat di sekitar.'**
  String get permissionExplanation;

  /// No description provided for @grantPermission.
  ///
  /// In id, this message translates to:
  /// **'Berikan Izin'**
  String get grantPermission;

  /// No description provided for @nicknameInUse.
  ///
  /// In id, this message translates to:
  /// **'Nickname sudah dipakai anggota lain. Pilih nama lain.'**
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
  /// **'Ganti Nickname'**
  String get changeNickname;

  /// No description provided for @leaveGroup.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Grup'**
  String get leaveGroup;

  /// No description provided for @members.
  ///
  /// In id, this message translates to:
  /// **'Anggota'**
  String get members;
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
