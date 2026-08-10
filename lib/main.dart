import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants.dart';
import 'data/database/app_database.dart';
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
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
  );
  _scheduleRetentionCleanup(container);
  runApp(UncontrolledProviderScope(
    container: container,
    child: const NearBuddyApp(),
  ));
}

/// M4: 7-day retention runs at app start and then daily — it must not
/// depend on a chat screen ever being opened.
void _scheduleRetentionCleanup(ProviderContainer container) {
  Future<void> run() async {
    final dao = container.read(appDatabaseProvider).messagesDao;
    await dao.deleteOlderThan(DateTime.now().subtract(
        const Duration(days: AppConstants.messageRetentionDays)));
  }

  unawaited(run());
  Timer.periodic(const Duration(hours: 24), (_) => unawaited(run()));
}
