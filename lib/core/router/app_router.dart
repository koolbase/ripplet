import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/chat/domain/conversation_summary.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/chat/presentation/new_message_screen.dart';
import '../../features/profile/application/profile_providers.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/system/application/platform_config_providers.dart';
import '../../features/system/presentation/update_required_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ref.watch(sessionProvider) != null;
  final updateRequired = ref.watch(updateRequiredProvider);

  final needsProfile =
      signedIn &&
      ref
          .watch(myProfileProvider)
          .maybeWhen(data: (p) => p == null, orElse: () => false);

  return GoRouter(
    initialLocation: '/chats',
    redirect: (context, state) {
      if (updateRequired) return '/update-required';
      final onAuthScreen =
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/signup';
      if (!signedIn && !onAuthScreen) return '/welcome';
      if (needsProfile && state.matchedLocation != '/complete-profile') {
        return '/complete-profile';
      }
      if (!needsProfile && state.matchedLocation == '/complete-profile') {
        return '/chats';
      }
      if (signedIn && onAuthScreen) return '/chats';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const SignupScreen(completeMode: true),
      ),
      GoRoute(
        path: '/update-required',
        builder: (_, __) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        path: '/new-message',
        builder: (_, __) => const NewMessageScreen(),
      ),
      GoRoute(
        path: '/chats/:id',
        builder: (_, state) => ChatRoomScreen(
          conversationId: state.pathParameters['id']!,
          summary: state.extra as ConversationSummary?,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (_, __) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
