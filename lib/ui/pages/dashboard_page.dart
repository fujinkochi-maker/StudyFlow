import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/auth/auth_service.dart';
import 'package:study_flow/features/tasks/task_service.dart';
import 'package:study_flow/features/study/study_service.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/theme.dart';
import 'package:study_flow/ui/components/animated_list_wrapper.dart';
import 'package:study_flow/ui/components/student_id_card.dart';
import 'package:study_flow/ui/components/task_card.dart';

// Cute pastel colors matching the Study Flow mascot style
const _kPastelPink = Color(0xFFFFB6C1);
const _kPastelLavender = Color(0xFFE6E6FA);
const _kPastelMint = Color(0xFFB5EAD7);
const _kPastelPeach = Color(0xFFFFDAC1);
const _kSoftCream = Color(0xFFFDF6F0);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // ── Cute Header with Study Flow Mascot ───────────────────────────
          SliverToBoxAdapter(
            child: _CuteHeader(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ── Student ID Card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.horizontalMd,
              child: const StudentIdCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ── Cute Stats Row ───────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(padding: AppSpacing.horizontalMd, child: _CuteStatsRow())),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // ── Progress & Streak Cards ───────────────────────────────────────
          SliverToBoxAdapter(child: Padding(padding: AppSpacing.horizontalMd, child: _CuteProgressAndStreak())),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // ── Performance Cards ───────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(padding: AppSpacing.horizontalMd, child: _CutePerformanceRow())),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // ── Upcoming Tasks Header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.horizontalMd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: _kPastelPink, size: 20),
                      const SizedBox(width: 8),
                      Text('Upcoming', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.tasks),
                    icon: Icon(Icons.arrow_forward_rounded, color: _kPastelPink),
                    label: Text('View all', style: TextStyle(color: _kPastelPink, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // ── Task List ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: Consumer<TaskService>(
              builder: (context, tasks, _) {
                final upcoming = tasks.upcoming(limit: 6);
                if (upcoming.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _CuteEmptyState(
                      title: 'All caught up!',
                      subtitle: 'Add a task to start building your streak ✨',
                    ),
                  );
                }
                return SliverList.separated(
                  itemBuilder: (context, index) {
                    final t = upcoming[index];
                    return AnimatedListWrapper(
                      index: index,
                      child: TaskCard(
                        task: t,
                        onToggleStatus: () => context.read<TaskService>().toggleStatus(t.id),
                        onEdit: () {},
                        onDelete: () => context.read<TaskService>().delete(t.id),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: upcoming.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CuteHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.horizontalMd,
      child: Row(
        children: [
          Text('Study Flow', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          Icon(Icons.notifications_none_rounded, color: theme.colorScheme.onSurface),
        ],
      ),
    );
  }
}

class _CuteStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Consumer<TaskService>(
      builder: (context, tasks, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatCard(label: 'Total tasks', value: '${tasks.tasks.length}', icon: Icons.all_inbox_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              _StatCard(label: 'Due today', value: '${tasks.dueTodayCount}', icon: Icons.today_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              _StatCard(label: 'Completed', value: '${tasks.completedCount}', icon: Icons.check_circle_rounded, color: Colors.green),
              const SizedBox(width: 10),
              _StatCard(label: 'Overdue', value: '${tasks.overdueCount}', icon: Icons.error_rounded, color: scheme.error),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressAndStreak extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<TaskService>(
                builder: (context, tasks, _) {
                  final ratio = tasks.completionRatio;
                  final percent = (ratio * 100).round();
                  return Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 26,
                            sections: [
                              PieChartSectionData(value: ratio * 100, radius: 10, showTitle: false, color: scheme.primary),
                              PieChartSectionData(value: (1 - ratio) * 100, radius: 10, showTitle: false, color: scheme.surfaceContainerHighest),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('$percent% complete', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Streak', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${context.watch<AuthService>().currentUser?.streakDays ?? 0} days', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Keep it going today', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Consumer<StudyService>(
      builder: (context, study, _) {
        final accPct = (study.overallAccuracy() * 100).round();
        final mins = (study.studySeconds / 60).round();
        return Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.percent_rounded, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text('Accuracy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('$accPct%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('${study.quizzesTaken()} quizzes taken', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_rounded, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('Focus', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('$mins min', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('Total logged time', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}