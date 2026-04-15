import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/features/schedule/schedule_service.dart';
import 'package:study_flow/features/study/study_service.dart';
import 'package:study_flow/features/tasks/task_service.dart';
import 'package:study_flow/features/student_id/student_id_service.dart';
import 'package:study_flow/state/app_theme_controller.dart';

/// Main entry point for the application
///
/// This sets up:
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeController()..load()),
        ChangeNotifierProvider(create: (_) => TaskService()..load()),
        ChangeNotifierProvider(create: (_) => NotesService()..load()),
        ChangeNotifierProvider(create: (_) => ScheduleService()),
        ChangeNotifierProvider(create: (_) => StudyService()..load()),
        ChangeNotifierProvider(create: (_) => StudentIdService()..load()),
      ],
      child: Consumer<AppThemeController>(
        builder: (context, theme, _) => _RouterHost(theme: theme),
      ),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost({required this.theme});
  final AppThemeController theme;

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MaterialApp.router(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: _router,
    );
  }
}