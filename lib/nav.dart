import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:study_flow/ui/app_shell.dart';
import 'package:study_flow/ui/pages/calendar_page.dart';
import 'package:study_flow/ui/pages/dashboard_page.dart';
import 'package:study_flow/ui/pages/notes_page.dart';
import 'package:study_flow/ui/pages/profile_page.dart';
import 'package:study_flow/ui/pages/study_page.dart';
import 'package:study_flow/ui/pages/tasks_page.dart';

/// Custom fade + slide page transition for fluid navigation
class FadeSlidePage<T> extends CustomTransitionPage<T> {
  FadeSlidePage({required super.child, super.name, super.arguments, super.restorationId})
      : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ));
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

/// Hero-style zoom page transition for login/logout
class ZoomFadePage<T> extends CustomTransitionPage<T> {
  ZoomFadePage({required super.child, super.name, super.arguments, super.restorationId})
      : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuart,
                reverseCurve: Curves.easeInQuart,
              ),
            );
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

///
/// [StatefulShellRoute.indexedStack] so each tab preserves its navigation state.
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                pageBuilder: (context, state) => FadeSlidePage(name: 'dashboard', child: const DashboardPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                name: 'tasks',
                pageBuilder: (context, state) => FadeSlidePage(name: 'tasks', child: const TasksPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notes,
                name: 'notes',
                pageBuilder: (context, state) => FadeSlidePage(name: 'notes', child: const NotesPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.study,
                name: 'study',
                pageBuilder: (context, state) => FadeSlidePage(name: 'study', child: const StudyPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                pageBuilder: (context, state) => FadeSlidePage(name: 'calendar', child: const CalendarPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) => FadeSlidePage(name: 'profile', child: const ProfilePage()),
              ),
            ],
          ),
        ],
      ),

      // Back-compat: route / -> /dashboard
      GoRoute(
        path: '/',
        redirect: (_, __) => AppRoutes.dashboard,
      ),
      ],
      errorPageBuilder: (context, state) => MaterialPage(
        child: Scaffold(
          body: Center(
            child: Text(
              'Route not found: ${state.uri}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String tasks = '/tasks';
  static const String notes = '/notes';
  static const String study = '/study';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
}
