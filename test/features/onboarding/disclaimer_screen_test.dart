import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbuddy/l10n/app_localizations.dart' show AppLocalizations;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:nearbuddy/data/preferences/app_preferences.dart';
import 'package:nearbuddy/main.dart';
import 'package:nearbuddy/features/onboarding/disclaimer_screen.dart';

Future<AppPreferences> mockPrefs({bool accepted = false}) async {
  SharedPreferences.setMockInitialValues({'hasAcceptedDisclaimer': accepted});
  return AppPreferences.create();
}

// Must use ShadApp (not MaterialApp) so ShadTheme is available to shadcn widgets.
Widget wrap(Widget child, AppPreferences prefs) => ProviderScope(
  overrides: [appPreferencesProvider.overrideWithValue(prefs)],
  child: ShadApp(
    theme: ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadGreenColorScheme.light(),
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const [Locale('id')],
    home: child,
  ),
);

void main() {
  testWidgets('DisclaimerScreen shows title and accept button', (tester) async {
    final prefs = await mockPrefs();
    await tester.pumpWidget(wrap(const DisclaimerScreen(), prefs));
    await tester.pumpAndSettle();
    expect(find.text('Pemberitahuan Penting'), findsOneWidget);
    expect(find.text('Saya Mengerti'), findsOneWidget);
  });
}
