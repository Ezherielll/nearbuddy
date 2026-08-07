import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _kNick = 'nickname';
  static const _kDisclaimer = 'hasAcceptedDisclaimer';
  static const _kLang = 'languageCode';

  final SharedPreferences _p;
  AppPreferences(this._p);

  static Future<AppPreferences> create() async =>
      AppPreferences(await SharedPreferences.getInstance());

  String? get nickname => _p.getString(_kNick);
  Future<void> setNickname(String v) => _p.setString(_kNick, v);

  bool get hasAcceptedDisclaimer => _p.getBool(_kDisclaimer) ?? false;
  Future<void> acceptDisclaimer() => _p.setBool(_kDisclaimer, true);

  String get languageCode => _p.getString(_kLang) ?? 'id';
  Future<void> setLanguageCode(String c) => _p.setString(_kLang, c);
}
