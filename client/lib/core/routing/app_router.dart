// Top-level routing. Uses GoRouter's StatefulShellRoute.indexedStack to wrap
// non-match screens in the AppShell (with bottom nav). Match screens bypass
// the shell so the user cannot accidentally leave the game.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/session_expired_screen.dart';
import '../../features/bingo/presentation/bingo_details_screen.dart';
import '../../features/bingo/presentation/bingo_gameplay_screen.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/games/presentation/games_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/matchmaking/presentation/quick_match_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rooms/presentation/create_room_screen.dart';
import '../../features/rooms/presentation/join_room_screen.dart';
import '../../features/rooms/presentation/waiting_room_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sos/presentation/sos_details_screen.dart';
import '../../features/sos/presentation/sos_gameplay_screen.dart';
import '../../shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/session-expired',
        builder: (_, __) => const SessionExpiredScreen(),
      ),
      GoRoute(
        path: '/match/bingo/:matchId',
        builder: (_, s) => BingoGameplayScreen(
          matchId: s.pathParameters['matchId']!,
          you: s.uri.queryParameters['you'] ?? '',
        ),
      ),
      GoRoute(
        path: '/match/sos/:matchId',
        builder: (_, s) => SosGameplayScreen(
          matchId: s.pathParameters['matchId']!,
          you: s.uri.queryParameters['you'] ?? '',
        ),
      ),
      GoRoute(
        path: '/waiting/:roomId',
        builder: (_, s) => WaitingRoomScreen(roomId: s.pathParameters['roomId']!),
      ),
      GoRoute(
        path: '/quick-match/:kind',
        builder: (_, s) => QuickMatchScreen(kind: s.pathParameters['kind']!),
      ),
      GoRoute(
        path: '/create-room/:kind',
        builder: (_, s) => CreateRoomScreen(kind: s.pathParameters['kind']!),
      ),
      GoRoute(
        path: '/join-room/:kind',
        builder: (_, s) => JoinRoomScreen(kind: s.pathParameters['kind']!),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) {
          final String loc = state.uri.toString();
          return AppShell(location: loc, child: navShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'bingo',
                    builder: (_, __) => const BingoDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'sos',
                    builder: (_, __) => const SosDetailsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                builder: (_, __) => const GamesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/friends',
                builder: (_, __) => const FriendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (_, __) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});