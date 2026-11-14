import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/features/brief/brief_screen.dart';
import 'package:outpost_cadet/features/build/build_screen.dart';
import 'package:outpost_cadet/features/cadet/cadet_screen.dart';
import 'package:outpost_cadet/features/debrief/debrief_screen.dart';
import 'package:outpost_cadet/features/home/home_screen.dart';
import 'package:outpost_cadet/features/learn/learn_screen.dart';
import 'package:outpost_cadet/features/onboarding/onboarding_screen.dart';
import 'package:outpost_cadet/features/progress/progress_screen.dart';
import 'package:outpost_cadet/features/shell/main_shell.dart';
import 'package:outpost_cadet/features/world_2d/world_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/missions',
              builder: (context, state) => const BriefScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journal',
              builder: (context, state) => const LearnScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cadet',
              builder: (context, state) => const CadetScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/build',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BuildScreen(),
    ),
    GoRoute(
      path: '/world',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WorldScreen(),
    ),
    GoRoute(
      path: '/run',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) => '/world',
    ),
    GoRoute(
      path: '/debrief',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const DebriefScreen(),
    ),
    // Legacy redirects
    GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
    GoRoute(path: '/brief', redirect: (context, state) => '/missions'),
    GoRoute(path: '/learn', redirect: (context, state) => '/journal'),
  ],
);
