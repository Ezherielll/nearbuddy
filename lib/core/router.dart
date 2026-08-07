import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/onboarding/disclaimer_screen.dart';
import '../features/onboarding/nickname_screen.dart';

late final GoRouter appRouter;

GoRouter buildRouter(dynamic prefs) => GoRouter(
  initialLocation: _initialRoute(prefs),
  routes: [
    GoRoute(path: '/disclaimer', builder: (_, __) => const DisclaimerScreen()),
    GoRoute(path: '/nickname',   builder: (_, __) => const NicknameScreen()),
    // Stub routes — replaced with real widgets in Tasks 6-9:
    GoRoute(path: '/home',         builder: (_, __) => const Scaffold(body: Center(child: Text('Home')))),
    GoRoute(path: '/chat/:groupId', builder: (_, s) => Scaffold(body: Center(child: Text('Chat: ${s.pathParameters["groupId"]}')))),
    GoRoute(path: '/settings',     builder: (_, __) => const Scaffold(body: Center(child: Text('Settings')))),
    GoRoute(path: '/create-group', builder: (_, __) => const Scaffold(body: Center(child: Text('Create Group')))),
  ],
);

String _initialRoute(dynamic prefs) {
  if (!prefs.hasAcceptedDisclaimer) return '/disclaimer';
  if (prefs.nickname == null) return '/nickname';
  return '/home';
}
