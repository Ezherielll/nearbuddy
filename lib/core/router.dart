import 'package:go_router/go_router.dart';
import '../features/onboarding/disclaimer_screen.dart';
import '../features/onboarding/nickname_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/devices_screen.dart';
import '../features/group/create_group_screen.dart';
import '../features/group/join_group_screen.dart';
import '../features/group/invite_devices_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/dm_sessions_screen.dart';
import '../features/chat/dm_chat_screen.dart';
import '../features/settings/settings_screen.dart';

late final GoRouter appRouter;

GoRouter buildRouter(dynamic prefs) => GoRouter(
  initialLocation: _initialRoute(prefs),
  routes: [
    GoRoute(path: '/disclaimer', builder: (_, __) => const DisclaimerScreen()),
    GoRoute(path: '/nickname',   builder: (_, __) => const NicknameScreen()),
    GoRoute(path: '/home',         builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/create-group', builder: (_, __) => const CreateGroupScreen()),
    GoRoute(
      path: '/invite/:groupId',
      builder: (_, s) => InviteDevicesScreen(
        groupId: s.pathParameters['groupId']!,
        groupName: s.extra as String? ?? '',
      ),
    ),
    GoRoute(path: '/join-group',   builder: (_, __) => const JoinGroupScreen()),
    // Stub routes — replaced with real widgets in Tasks 13:
    GoRoute(path: '/chat/:groupId', builder: (_, s) => ChatScreen(groupId: s.pathParameters['groupId']!)),
    GoRoute(path: '/devices', builder: (_, __) => const DevicesScreen()),
    GoRoute(path: '/dms',          builder: (_, __) => const DmSessionsScreen()),
    GoRoute(path: '/dm/:sessionId', builder: (_, s) => DmChatScreen(sessionId: s.pathParameters['sessionId']!)),
    GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
  ],
);

String _initialRoute(dynamic prefs) {
  if (!prefs.hasAcceptedDisclaimer) return '/disclaimer';
  if (prefs.nickname == null) return '/nickname';
  return '/home';
}
