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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPreferences.create();
  appRouter = buildRouter(prefs);
  runApp(ProviderScope(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
    child: const NearBuddyApp(),
  ));
}
