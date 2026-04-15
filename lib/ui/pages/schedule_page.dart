import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/schedule/class_schedule.dart';
import 'package:study_flow/features/schedule/schedule_service.dart';
import 'package:study_flow/services/haptic_service.dart';
import 'package:study_flow/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Page - Weekly Timetable View
// ─────────────────────────────────────────────────────────────────────────────

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Show Mon-Fri by default (common school week)
  final List<DayOfWeek> _weekDays = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
  ];

  // Time range for the timetable (7 AM to 8 PM)
  final int _startHour = 7;
  final int _endHour = 20;
  final double _hourHeight = 80; // Height per hour in pixels

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: Consumer<ScheduleService>(
        builder: (context, service, child) {
          return CustomScrollView(
            slivers: [
              // Sliver App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(PhosphorIcons.list(), color: scheme.onSurface),
                  onPressed: () {
                    final scaffold = Scaffold.maybeOf(context);
                    if (scaffold != null && scaffold.hasDrawer) {
                      scaffold.openDrawer();
                    } else {
                      final parentScaffold = context.findAncestorStateOfType<ScaffoldState>();
                      parentScaffold?.openDrawer();
                    }
                  },
                ),
                title: Text(
                  'Schedule',
                  style: TextStyle(
                    fontFamily: 'CrimsonText',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  FilledButton.tonalIcon(
                    onPressed: () => _showAddClassDialog(context),
                    icon: Icon(PhosphorIcons.plus(), size: 18),
                    label: const Text('Add Class'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

                // Current Class Widget
                SliverToBoxAdapter(
                  child: _CurrentClassWidget(
                    schedules: service.schedules,
                    onAdd: () => _showAddClassDialog(context),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Weekly Timetable
                SliverFillRemaining(
                  child: _WeeklyTimetable(
                    weekDays: _weekDays,
                    schedules: service.schedules,
                    startHour: _startHour,
                    endHour: _endHour,
                    hourHeight: _hourHeight,
                    onEdit: (schedule) => _showEditClassDialog(context, schedule),
                    onDelete: (schedule) => _confirmDelete(context, schedule),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final today = DayOfWeek.fromDateTime(DateTime.now());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ClassEditorSheet(
        initialDay: today,
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, ClassSchedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ClassEditorSheet(schedule: schedule),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClassSchedule schedule) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete class?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Remove "${schedule.courseName}" from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<ScheduleService>().delete(schedule.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Flexible(child: Text('Class removed', style: TextStyle(color: Colors.white))),
          ]),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// ─── Current Class Widget ───────────────────────────────────────────────────

class _CurrentClassWidget extends StatelessWidget {
  final List<ClassSchedule> schedules;
  final VoidCallback onAdd;

  const _CurrentClassWidget({required this.schedules, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final today = DayOfWeek.fromDateTime(now);

    // Find current or next class
    ClassSchedule? currentClass;
    ClassSchedule? nextClass;

    for (final schedule in schedules) {
      if (schedule.dayOfWeek != today) continue;

      final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
      final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

      // Check if class is currently ongoing
      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        currentClass = schedule;
        break;
      }
      // Find next class
      if (startMinutes > currentMinutes) {
        if (nextClass == null) {
          nextClass = schedule;
        } else {
          final nextStart = nextClass.startTime.hour * 60 + nextClass.startTime.minute;
          if (startMinutes < nextStart) {
            nextClass = schedule;
          }
        }
      }
    }

    final displayClass = currentClass ?? nextClass;
    if (displayClass == null) return const SizedBox.shrink();

    final isCurrent = currentClass != null;
    final color = Color(displayClass.colorValue);

    return GestureDetector(
      onLongPress: () => _showOptions(context, displayClass),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                PhosphorIcons.student(),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.green.withValues(alpha: 0.2) : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      isCurrent ? 'Happening Now' : 'Up Next',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? Colors.green : scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayClass.courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${displayClass.timeRange}${displayClass.room != null ? ' • ${displayClass.room}' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, ClassSchedule schedule) {
    final scheme = Theme.of(context).colorScheme;
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.pencilSimple(), color: scheme.onSurface),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditDialog(context, schedule);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: scheme.error),
              title: Text('Delete', style: TextStyle(color: scheme.error)),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(context, schedule);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ClassSchedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ClassEditorSheet(schedule: schedule),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClassSchedule schedule) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete class?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Remove "${schedule.courseName}" from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<ScheduleService>().delete(schedule.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Flexible(child: Text('Class removed', style: TextStyle(color: Colors.white))),
          ]),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// ─── Weekly Timetable ─────────────────────────────────────────────────────────

class _WeeklyTimetable extends StatelessWidget {
  final List<DayOfWeek> weekDays;
  final List<ClassSchedule> schedules;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final Function(ClassSchedule) onEdit;
  final Function(ClassSchedule) onDelete;

  const _WeeklyTimetable({
    required this.weekDays,
    required this.schedules,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalHours = endHour - startHour;
    final totalHeight = totalHours * hourHeight;

    return Column(
      children: [
        // Day headers with dates
        Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: weekDays.map((day) {
              final isToday = day == DayOfWeek.fromDateTime(DateTime.now());
              final date = _getDateForDay(day);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isToday ? scheme.primary : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.displayName.substring(0, 3).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isToday ? scheme.onPrimary : scheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isToday ? scheme.onPrimary : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Timetable grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              height: totalHeight,
              child: Row(
                children: [
                  // Days columns with classes (no time column)
                  Expanded(
                    child: Row(
                      children: weekDays.map((day) {
                        final daySchedules = schedules
                            .where((s) => s.dayOfWeek == day)
                            .toList()
                          ..sort((a, b) {
                            final aMin = a.startTime.hour * 60 + a.startTime.minute;
                            final bMin = b.startTime.hour * 60 + b.startTime.minute;
                            return aMin.compareTo(bMin);
                          });

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Stack(
                              children: [
                                // Hour grid lines
                                Column(
                                  children: List.generate(totalHours, (index) {
                                    return Container(
                                      height: hourHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: scheme.outlineVariant.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                // Classes positioned by time
                                ...daySchedules.map((schedule) {
                                  final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
                                  final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
                                  final top = ((startMinutes - startHour * 60) / 60) * hourHeight;
                                  final height = ((endMinutes - startMinutes) / 60) * hourHeight;
                                  final color = Color(schedule.colorValue);

                                  final startTimeStr = _formatTime(schedule.startTime);

                                  return Positioned(
                                    top: top,
                                    left: 1,
                                    right: 1,
                                    height: height,
                                    child: GestureDetector(
                                      onLongPress: () => _showOptions(context, schedule),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              color.withValues(alpha: 0.95),
                                              color.withValues(alpha: 0.75),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(AppRadius.lg),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Time at top
                                            Row(
                                              children: [
                                                Icon(
                                                  PhosphorIcons.clock(),
                                                  size: 10,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  startTimeStr,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Course name
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  schedule.courseName,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            // Room info if available
                                            if (schedule.room != null && schedule.room!.isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                    PhosphorIcons.mapPin(),
                                                    size: 10,
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      schedule.room!,
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white.withValues(alpha: 0.95),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _getDateForDay(DayOfWeek day) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final targetWeekday = day.index + 1; // DayOfWeek is 0-indexed, DateTime is 1-indexed
    final diff = targetWeekday - todayWeekday;
    final date = now.add(Duration(days: diff));
    return '${date.day}';
  }

  void _showOptions(BuildContext context, ClassSchedule schedule) {
    final scheme = Theme.of(context).colorScheme;
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.pencilSimple(), color: scheme.onSurface),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                onEdit(schedule);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: scheme.error),
              title: Text('Delete', style: TextStyle(color: scheme.error)),
              onTap: () {
                Navigator.of(context).pop();
                onDelete(schedule);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Class Editor Sheet ─────────────────────────────────────────────────────

class _ClassEditorSheet extends StatefulWidget {
  final ClassSchedule? schedule;
  final DayOfWeek? initialDay;

  const _ClassEditorSheet({this.schedule, this.initialDay});

  @override
  State<_ClassEditorSheet> createState() => _ClassEditorSheetState();
}

class _ClassEditorSheetState extends State<_ClassEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _buildingCtrl;
  late final TextEditingController _professorCtrl;
  
  late DayOfWeek _dayOfWeek;
  late DateTime _startTime;
  late DateTime _endTime;
  late int _colorValue;

  final _colors = [
    0xFFE57373, // Red
    0xFF81C784, // Green
    0xFF64B5F6, // Blue
    0xFFFFB74D, // Orange
    0xFFBA68C8, // Purple
    0xFF4DB6AC, // Teal
    0xFFFF8A65, // Coral
    0xFFA1887F, // Brown
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _nameCtrl = TextEditingController(text: s?.courseName ?? '');
    _codeCtrl = TextEditingController(text: s?.courseCode ?? '');
    _roomCtrl = TextEditingController(text: s?.room ?? '');
    _buildingCtrl = TextEditingController(text: s?.building ?? '');
    _professorCtrl = TextEditingController(text: s?.professor ?? '');
    _dayOfWeek = s?.dayOfWeek ?? widget.initialDay ?? DayOfWeek.monday;
    _startTime = s?.startTime ?? DateTime(2024, 1, 1, 9, 0);
    _endTime = s?.endTime ?? DateTime(2024, 1, 1, 10, 30);
    _colorValue = s?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _roomCtrl.dispose();
    _buildingCtrl.dispose();
    _professorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isEdit = widget.schedule != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset + bottomPadding),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Class' : 'Add Class',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(PhosphorIcons.x()),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Course Name
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Course Name *',
                  hintText: 'e.g. Mathematics',
                ),
              ),
              const SizedBox(height: 12),

              // Course Code
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g. MATH101',
                ),
              ),
              const SizedBox(height: 16),

              // Day Selector
              Text('Day', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DayOfWeek.values.map((day) {
                  final isSelected = day == _dayOfWeek;
                  return ChoiceChip(
                    label: Text(day.displayName),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _dayOfWeek = day),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Time Pickers
              Row(
                children: [
                Expanded(
                  child: _TimePickerButton(
                    label: 'Start Time',
                    time: _startTime,
                    onTap: () => _pickTime(context, isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerButton(
                    label: 'End Time',
                    time: _endTime,
                    onTap: () => _pickTime(context, isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Room & Building
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buildingCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Building',
                      hintText: 'e.g. Science',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _roomCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      hintText: 'e.g. 101A',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Professor
            TextField(
              controller: _professorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Professor',
                hintText: 'e.g. Dr. Smith',
              ),
            ),
            const SizedBox(height: 16),

            // Color Picker
            Text('Color', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = color),
                  child: AnimatedContainer(
                    duration: AppTokens.motionFast,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                    child: isSelected ? Icon(PhosphorIcons.check(), color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _save(context),
                icon: Icon(isEdit ? PhosphorIcons.floppyDisk() : PhosphorIcons.plus()),
                label: Text(isEdit ? 'Save Changes' : 'Add Class'),
              ),
            ),
          ],
        ),
      ),
    ),
  ),);
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked != null) {
      setState(() {
        final newTime = DateTime(2024, 1, 1, picked.hour, picked.minute);
        if (isStart) {
          _startTime = newTime;
          if (_startTime.isAfter(_endTime) || _startTime.isAtSameMomentAs(_endTime)) {
            _endTime = _startTime.add(const Duration(minutes: 90));
          }
        } else {
          _endTime = newTime;
        }
      });
    }
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course name is required.')),
      );
      return;
    }

    final service = context.read<ScheduleService>();
    final isEdit = widget.schedule != null;

    if (isEdit) {
      await service.update(widget.schedule!.copyWith(
        courseName: name,
        courseCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        dayOfWeek: _dayOfWeek,
        startTime: _startTime,
        endTime: _endTime,
        room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
        building: _buildingCtrl.text.trim().isEmpty ? null : _buildingCtrl.text.trim(),
        professor: _professorCtrl.text.trim().isEmpty ? null : _professorCtrl.text.trim(),
        colorValue: _colorValue,
      ));
    } else {
      await service.addSchedule(
        courseName: name,
        courseCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        dayOfWeek: _dayOfWeek,
        startTime: _startTime,
        endTime: _endTime,
        room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
        building: _buildingCtrl.text.trim().isEmpty ? null : _buildingCtrl.text.trim(),
        professor: _professorCtrl.text.trim().isEmpty ? null : _professorCtrl.text.trim(),
        colorValue: _colorValue,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            isEdit ? 'Class updated' : 'Class added',
            style: const TextStyle(color: Colors.white),
          ),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// ─── Time Picker Button ─────────────────────────────────────────────────────

class _TimePickerButton extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatted = _formatTime(time);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
