import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:study_flow/features/tasks/task.dart';
import 'package:study_flow/features/tasks/task_service.dart';
import 'package:study_flow/theme.dart';
import 'package:study_flow/ui/components/task_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Consumer<TaskService>(
        builder: (context, taskService, _) {
          final tasksForDate = taskService.tasks
              .where((t) =>
                  t.dueAt != null &&
                  _isSameDay(t.dueAt!, _selectedDate))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                title: const Text('Calendar'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalMd,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar<Task>(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2050),
                        focusedDay: _selectedDate,
                        selectedDayPredicate: (day) => _isSameDay(day, _selectedDate),
                        onDaySelected: (selectedDay, _) {
                          setState(() => _selectedDate = selectedDay);
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ?? const TextStyle(),
                          leftChevronIcon: Icon(PhosphorIcons.caretLeft(), color: theme.colorScheme.primary),
                          rightChevronIcon: Icon(PhosphorIcons.caretRight(), color: theme.colorScheme.primary),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          cellMargin: const EdgeInsets.all(6),
                          todayDecoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary, width: 2),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          defaultTextStyle: theme.textTheme.bodySmall ?? const TextStyle(),
                          outsideTextStyle: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        eventLoader: (day) {
                          return taskService.tasks
                              .where((t) =>
                                  t.dueAt != null &&
                                  _isSameDay(t.dueAt!, day))
                              .toList();
                        },
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w600),
                          weekendStyle: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final events = taskService.tasks
                                .where((t) =>
                                    t.dueAt != null &&
                                    _isSameDay(t.dueAt!, day))
                                .length;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(day.day.toString()),
                                if (events > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.horizontalMd,
                  child: Text(
                    'Tasks for ${_formatDate(_selectedDate)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (tasksForDate.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.horizontalMd,
                    child: Center(
                      child: Column(
                        children: [
                          Icon(PhosphorIcons.calendarBlank(), size: 48, color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks scheduled',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outlineVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasksForDate[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(
                            task: task,
                            onToggleStatus: () {
                              final newStatus = switch (task.status) {
                                TaskStatus.todo => TaskStatus.inProgress,
                                TaskStatus.inProgress => TaskStatus.done,
                                TaskStatus.done => TaskStatus.todo,
                              };
                              context.read<TaskService>().update(task.copyWith(status: newStatus));
                            },
                            onEdit: () {
                              // TODO: Open edit sheet
                            },
                            onDelete: () {
                              context.read<TaskService>().delete(task.id);
                            },
                          ),
                        );
                      },
                      childCount: tasksForDate.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
