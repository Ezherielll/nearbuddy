import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/router.dart';
import 'main.dart';

class NearBuddyApp extends ConsumerWidget {
  const NearBuddyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return ShadApp.custom(
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadGreenColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadGreenColorScheme.dark(),
      ),
      themeMode: ThemeMode.system,
      appBuilder: (context) {
        return MaterialApp.router(
          title: 'NearBuddy',
          routerConfig: appRouter,
          theme: Theme.of(context),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('id'), Locale('en')],
          builder: (context, child) => ShadAppBuilder(child: child!),
        );
      },
    );
  }
}
