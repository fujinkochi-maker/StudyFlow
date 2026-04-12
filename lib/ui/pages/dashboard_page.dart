import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/tasks/task_service.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/theme.dart';
import 'package:study_flow/ui/components/animated_list_wrapper.dart';
import 'package:study_flow/ui/components/student_id_card.dart';
import 'package:study_flow/ui/components/task_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(PhosphorIcons.bell(), color: theme.colorScheme.onSurface),
                tooltip: 'Reminders',
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // ── Student ID Card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.horizontalMd,
              child: const StudentIdCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: Padding(padding: AppSpacing.horizontalMd, child: _StatsRow())),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: Padding(padding: AppSpacing.horizontalMd, child: _ProgressAndStreak())),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.horizontalMd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.tasks),
                    icon: Icon(PhosphorIcons.arrowRight(), color: theme.colorScheme.primary),
                    label: Text('View all', style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: Consumer<TaskService>(
              builder: (context, tasks, _) {
                final upcoming = tasks.upcoming(limit: 6);
                if (upcoming.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      title: 'All caught up',
                      subtitle: 'Add a task to start building your streak.',
                      icon: PhosphorIcons.checkCircle(),
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

class _StatsRow extends StatelessWidget {
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
              _StatCard(label: 'Total tasks', value: '${tasks.tasks.length}', icon: PhosphorIcons.tray(), color: scheme.primary),
              const SizedBox(width: 10),
              _StatCard(label: 'Due today', value: '${tasks.dueTodayCount}', icon: PhosphorIcons.calendarCheck(), color: Colors.orange),
              const SizedBox(width: 10),
              _StatCard(label: 'Completed', value: '${tasks.completedCount}', icon: PhosphorIcons.checkCircle(), color: Colors.green),
              const SizedBox(width: 10),
              _StatCard(label: 'Overdue', value: '${tasks.overdueCount}', icon: PhosphorIcons.warningCircle(), color: scheme.error),
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
                      Icon(PhosphorIcons.flame(), color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Streak', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('0 days', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
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