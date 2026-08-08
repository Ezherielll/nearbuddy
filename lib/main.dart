import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/preferences/app_preferences.dart';
import 'app.dart';
import 'core/router.dart';

final appPreferencesProvider =
    Provider<AppPreferences>((_) => throw UnimplementedError());
final localeProvider = StateProvider<Locale>(
    (ref) => Locale(ref.watch(appPreferencesProvider).languageCode));

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final v = ref.watch(appPreferencesProvider).themeMode;
  return switch (v) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// Reactive nickname — Settings updates it after persisting so screens that
/// watch it (e.g. the Settings profile card) rebuild immediately.
final nicknameProvider = StateProvider<String>(
    (ref) => ref.watch(appPreferencesProvider).nickname ?? '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPreferences.create();
  appRouter = buildRouter(prefs);
  runApp(ProviderScope(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
    child: const NearBuddyApp(),
  ));
}
