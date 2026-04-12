import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/features/study/study_service.dart';
import 'package:study_flow/features/tasks/task_service.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/state/app_theme_controller.dart';
import 'package:study_flow/theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _drawerAnimationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  static final _items = <_NavItem>[
    _NavItem(label: 'Dashboard', icon: PhosphorIcons.house(), route: AppRoutes.dashboard),
    _NavItem(label: 'Tasks',     icon: PhosphorIcons.checkCircle(), route: AppRoutes.tasks),
    _NavItem(label: 'Notes',     icon: PhosphorIcons.notebook(), route: AppRoutes.notes),
    _NavItem(label: 'Study',     icon: PhosphorIcons.brain(), route: AppRoutes.study),
    _NavItem(label: 'Calendar',  icon: PhosphorIcons.calendarBlank(), route: AppRoutes.calendar),
    _NavItem(label: 'Profile',   icon: PhosphorIcons.user(), route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      drawer: SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(_drawerAnimation),
        child: FadeTransition(
          opacity: _drawerAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(
                  parent: _drawerAnimationController,
                  curve: Curves.easeOutCubic),
            ),
            alignment: Alignment.topLeft,
            child: _AppDrawer(navigationShell: widget.navigationShell),
          ),
        ),
      ),
      onDrawerChanged: (isOpen) {
        if (isOpen) {
          _drawerAnimationController.forward();
        } else {
          _drawerAnimationController.reverse();
        }
      },
      body: _AnimatedTabBody(navigationShell: widget.navigationShell),
      // ─── Modern floating pill navbar ───────────────────────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                selectedIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  );
                },
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                height: 64,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                indicatorColor:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                animationDuration: const Duration(milliseconds: 350),
                destinations: [
                  for (final item in _items)
                    NavigationDestination(
                      icon: Icon(item.icon, size: 22),
                      selectedIcon: Icon(item.icon,
                          size: 22, color: theme.colorScheme.primary),
                      label: item.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton:
          _ShellFab(currentIndex: widget.navigationShell.currentIndex),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _ShellFab extends StatelessWidget {
  const _ShellFab({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (currentIndex != 1) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () => TasksPageActions.openCreateTaskSheet(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('New task'),
    );
  }
}

// ─── Animated Tab Body ─────────────────────────────────────────────────────────

class _AnimatedTabBody extends StatefulWidget {
  const _AnimatedTabBody({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<_AnimatedTabBody>
    with TickerProviderStateMixin {
  int _previousIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
    _previousIndex = _currentIndex;
  }

  @override
  void didUpdateWidget(_AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = widget.navigationShell.currentIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Previous page (animating out if changed)
        if (_previousIndex != _currentIndex)
          _AnimatedPage(
            index: _previousIndex,
            currentIndex: _currentIndex,
            isEntering: false,
            child: _getBranchAt(_previousIndex),
          ),
        // Current page (animating in)
        _AnimatedPage(
          index: _currentIndex,
          currentIndex: _currentIndex,
          isEntering: _previousIndex != _currentIndex,
          child: _getBranchAt(_currentIndex),
        ),
      ],
    );
  }

  Widget _getBranchAt(int index) {
    return widget.navigationShell.currentIndex == index
        ? widget.navigationShell
        : const SizedBox.shrink();
  }
}

class _AnimatedPage extends StatefulWidget {
  const _AnimatedPage({
    required this.index,
    required this.currentIndex,
    required this.isEntering,
    required this.child,
  });

  final int index;
  final int currentIndex;
  final bool isEntering;
  final Widget child;

  @override
  State<_AnimatedPage> createState() => _AnimatedPageState();
}

class _AnimatedPageState extends State<_AnimatedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: widget.isEntering ? 0.0 : 1.0,
      end: widget.isEntering ? 1.0 : 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final isForward = widget.currentIndex >= widget.index;
    final beginOffset = widget.isEntering
        ? (isForward ? const Offset(0.08, 0) : const Offset(-0.08, 0))
        : (isForward ? const Offset(-0.04, 0) : const Offset(0.04, 0));

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: widget.isEntering ? 0.98 : 1.0,
      end: widget.isEntering ? 1.0 : 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Nav item model ───────────────────────────────────────────────────────────

class _NavItem {
  _NavItem(
      {required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}

// ─── Modern Drawer ────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.watch<AppThemeController>().themeMode;
    final isDark = themeMode == ThemeMode.dark;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Profile header ────────────────────────────────────────────
          _DrawerHeader(
            initial: 'S',
            displayName: 'Student',
            email: 'Study Flow App',
          ),

          // ── Quick stats bar ───────────────────────────────────────────
          const _StatsBar(),

          // ── Nav section ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionLabel('Menu'),
                for (int i = 0; i < _AppShellState._items.length; i++)
                  _DrawerNavTile(
                    item: _AppShellState._items[i],
                    isSelected: navigationShell.currentIndex == i,
                    badge: i == 1 ? '4' : null, // tasks badge example
                    onTap: () {
                      Navigator.of(context).pop();
                      navigationShell.goBranch(i, initialLocation: true);
                    },
                  ),
                const SizedBox(height: 4),
                Divider(
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant),
                _SectionLabel('More'),
                _DrawerNavTile(
                  item: _NavItem(
                      label: 'Help & support',
                      icon: PhosphorIcons.question(),
                      route: ''),
                  isSelected: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _DrawerNavTile(
                  item: _NavItem(
                      label: 'About',
                      icon: PhosphorIcons.info(),
                      route: ''),
                  isSelected: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Bottom actions ────────────────────────────────────────────
          _DrawerBottom(
            isDark: isDark,
            onToggleTheme: () {
              final newMode =
                  isDark ? ThemeMode.light : ThemeMode.dark;
              context.read<AppThemeController>().setThemeMode(newMode);
            },
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.initial,
    required this.displayName,
    required this.email,
  });
  final String initial;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with rounded square shape
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          // Streak badge
          _StreakBadge(theme: theme),
        ],
      ),
    );
  }
}

// ── Streak Badge ──────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF9FE1CB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Keep studying!',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = context.watch<TaskService>();
    final notes = context.watch<NotesService>();
    final study = context.watch<StudyService>();
    final stats = [
      ('${tasks.tasks.length}', 'Tasks'),
      ('${notes.notes.length}', 'Notes'),
      ('${study.attempts.length}', 'Quizzes'),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
          bottom:
              BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outlineVariant),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        stats[i].$1,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stats[i].$2,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Icon(
          item.icon,
          size: 20,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          item.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor:
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        onTap: onTap,
      ),
    );
  }
}

// ── Bottom actions ────────────────────────────────────────────────────────────

class _DrawerBottom extends StatelessWidget {
  const _DrawerBottom({
    required this.isDark,
    required this.onToggleTheme,
  });
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Row(
        children: [
          // Theme toggle
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onToggleTheme,
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 16,
              ),
              label: Text(isDark ? 'Light mode' : 'Dark mode'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: theme.textTheme.labelMedium,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tasks FAB bridge ─────────────────────────────────────────────────────────

abstract class TasksPageActions {
  static VoidCallback? _registered;
  static void register(VoidCallback cb) => _registered = cb;
  static void unregister() => _registered = null;
  static void openCreateTaskSheet(BuildContext context) => _registered?.call();
}

class _TasksFabCallback extends InheritedWidget {
  const _TasksFabCallback({required this.openCreate, required super.child});
  final VoidCallback openCreate;

  @override
  bool updateShouldNotify(covariant _TasksFabCallback old) =>
      openCreate != old.openCreate;
}

class TasksFabCallbackScope extends StatelessWidget {
  const TasksFabCallbackScope(
      {super.key, required this.openCreate, required this.child});
  final VoidCallback openCreate;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _TasksFabCallback(openCreate: openCreate, child: child);
}