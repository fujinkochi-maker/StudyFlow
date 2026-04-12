import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/tasks/task.dart';
import 'package:study_flow/features/tasks/task_service.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/features/notes/course.dart';
import 'package:study_flow/theme.dart';
import 'package:study_flow/ui/app_shell.dart';
import 'package:study_flow/ui/components/animated_list_wrapper.dart';
import 'package:study_flow/ui/components/task_card.dart';

// ─── Course icon palette ─────────────────────────────────────────────────────

const _kCourseIcons = <IconData>[
  Icons.calculate_rounded,
  Icons.science_rounded,
  Icons.history_edu_rounded,
  Icons.language_rounded,
  Icons.palette_rounded,
  Icons.music_note_rounded,
  Icons.computer_rounded,
  Icons.sports_soccer_rounded,
  Icons.biotech_rounded,
  Icons.psychology_rounded,
  Icons.public_rounded,
  Icons.menu_book_rounded,
  Icons.architecture_rounded,
  Icons.health_and_safety_rounded,
  Icons.account_balance_rounded,
  Icons.eco_rounded,
];

// ─── Tasks Page ──────────────────────────────────────────────────────────────

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  String? _courseFilter;

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    // Register so the shell FAB can open the sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TasksPageActions.register(() => _openTaskSheet(context));
    });
  }

  @override
  void dispose() {
    TasksPageActions.unregister();
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

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
            title: const Text('Tasks'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  tabs: const [Tab(text: 'All Tasks'), Tab(text: 'By Course')],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _AllTasksTab(
                  searchCtrl: _searchCtrl,
                  statusFilter: _statusFilter,
                  priorityFilter: _priorityFilter,
                  courseFilter: _courseFilter,
                  onStatusChanged: (v) => setState(() => _statusFilter = v),
                  onPriorityChanged: (v) =>
                      setState(() => _priorityFilter = v),
                  onCourseChanged: (v) => setState(() => _courseFilter = v),
                  onClear: () => setState(() {
                    _statusFilter = null;
                    _priorityFilter = null;
                    _courseFilter = null;
                    _searchCtrl.clear();
                  }),
                  onOpenTask: (t) => _openTaskSheet(context, existing: t),
                  onDeleteTask: (t) => _confirmDelete(context, t),
                  onCreateTask: () => _openTaskSheet(context),
                ),
                _ByCourseTab(
                  onCreateTask: (courseId) =>
                      _openTaskSheet(context, preselectedCourseId: courseId),
                  onEditTask: (t) => _openTaskSheet(context, existing: t),
                  onDeleteTask: (t) => _confirmDelete(context, t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Task t) async {
    final theme = Theme.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete task?',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('"${t.title}" will be permanently removed.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon:Icon(PhosphorIcons.trash()),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<TaskService>().delete(t.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
             Icon(PhosphorIcons.checkCircle(),
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Flexible(child: Text('Task "${t.title}" deleted')),
          ]),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  Future<void> _openTaskSheet(BuildContext context,
      {Task? existing, String? preselectedCourseId}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskEditorSheet(
        existing: existing,
        preselectedCourseId: preselectedCourseId,
      ),
    );
  }
}

// ─── All Tasks Tab ───────────────────────────────────────────────────────────

class _AllTasksTab extends StatelessWidget {
  const _AllTasksTab({
    required this.searchCtrl,
    required this.statusFilter,
    required this.priorityFilter,
    required this.courseFilter,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onCourseChanged,
    required this.onClear,
    required this.onOpenTask,
    required this.onDeleteTask,
    required this.onCreateTask,
  });

  final TextEditingController searchCtrl;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final String? courseFilter;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final ValueChanged<String?> onCourseChanged;
  final VoidCallback onClear;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<Task> onDeleteTask;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: AppSpacing.horizontalMd,
        child: TextField(
          controller: searchCtrl,
          onChanged: (_) {},
          textInputAction: TextInputAction.search,
          decoration:  InputDecoration(
            hintText: 'Search tasks…',
            prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: AppSpacing.horizontalMd,
        child: _FiltersRow(
          status: statusFilter,
          priority: priorityFilter,
          courseFilter: courseFilter,
          onStatusChanged: onStatusChanged,
          onPriorityChanged: onPriorityChanged,
          onCourseChanged: onCourseChanged,
          onClear: onClear,
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: Consumer2<TaskService, NotesService>(
          builder: (context, taskSvc, notesSvc, _) {
            final query = searchCtrl.text.trim().toLowerCase();
            final items = taskSvc.tasks.where((t) {
              if (query.isNotEmpty) {
                final courseName = notesSvc.courses
                    .cast<Course?>()
                    .firstWhere((c) => c?.id == t.subject,
                        orElse: () => null)
                    ?.name
                    .toLowerCase() ??
                    '';
                final hay = '${t.title} $courseName'.toLowerCase();
                if (!hay.contains(query)) return false;
              }
              if (statusFilter != null && t.status != statusFilter) return false;
              if (priorityFilter != null && t.priority != priorityFilter) {
                return false;
              }
              if (courseFilter != null && t.subject != courseFilter) return false;
              return true;
            }).toList();

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                child: _EmptyTasks(onCreate: onCreateTask),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              itemBuilder: (context, index) {
                final t = items[index];
                return AnimatedListWrapper(
                  index: index,
                  child: TaskCard(
                    task: t,
                    onToggleStatus: () =>
                        context.read<TaskService>().toggleStatus(t.id),
                    onEdit: () => onOpenTask(t),
                    onDelete: () => onDeleteTask(t),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: items.length,
            );
          },
        ),
      ),
    ]);
  }
}

// ─── By Course Tab ───────────────────────────────────────────────────────────

class _ByCourseTab extends StatelessWidget {
  const _ByCourseTab({
    required this.onCreateTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final ValueChanged<String?> onCreateTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskService, NotesService>(
      builder: (context, taskSvc, notesSvc, _) {
        final courses = notesSvc.courses;
        final courseIds = courses.map((c) => c.id).toSet();
        final uncategorised = taskSvc.tasks
            .where((t) => !courseIds.contains(t.subject))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            Row(children: [
              Expanded(
                child: Text('Courses',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddCourseSheet(context),
                icon:  Icon(PhosphorIcons.plus(), size: 18),
                label: const Text('Add course'),
              ),
            ]),
            const SizedBox(height: 12),
            if (courses.isEmpty)
              _NoCourses(onAdd: () => _showAddCourseSheet(context))
            else ...[
              for (final course in courses) ...[
                _CourseSection(
                  course: course,
                  tasks: taskSvc.tasks
                      .where((t) => t.subject == course.id)
                      .toList(),
                  onAddTask: () => onCreateTask(course.id),
                  onEditTask: onEditTask,
                  onDeleteTask: onDeleteTask,
                ),
                const SizedBox(height: 12),
              ],
            ],
            if (uncategorised.isNotEmpty) ...[
              _CourseSection(
                course: null,
                tasks: uncategorised,
                onAddTask: () => onCreateTask(null),
                onEditTask: onEditTask,
                onDeleteTask: onDeleteTask,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showAddCourseSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CourseEditorSheet(),
    );
  }
}

// ─── Course Section ──────────────────────────────────────────────────────────

class _CourseSection extends StatefulWidget {
  const _CourseSection({
    required this.course,
    required this.tasks,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final Course? course;
  final List<Task> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  State<_CourseSection> createState() => _CourseSectionState();
}

class _CourseSectionState extends State<_CourseSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final course = widget.course;
    final iconData = course != null
        ? IconData(course.iconCodePoint, fontFamily: 'MaterialIcons')
        : PhosphorIcons.tray();
    final name = course?.name ?? 'Uncategorised';
    final done =
        widget.tasks.where((t) => t.status == TaskStatus.done).length;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border:
            Border.all(color: scheme.outline.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(children: [
        // Header
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(iconData, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${widget.tasks.length} task${widget.tasks.length == 1 ? '' : 's'}'
                        '${widget.tasks.isNotEmpty ? ' · $done done' : ''}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // ⋮ menu (real courses only)
                if (course != null) _CourseMenuButton(course: course),
                // + add task
                IconButton(
                  tooltip: 'Add task to $name',
                  icon: Icon(PhosphorIcons.plusCircle(),
                      color: scheme.primary),
                  onPressed: widget.onAddTask,
                ),
                // chevron
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: AppTokens.motionFast,
                  child:
                      Icon(PhosphorIcons.caretDown(), color: scheme.onSurfaceVariant),
                ),
              ]),
            ),
          ),
        ),

        // Task list
        AnimatedSize(
          duration: AppTokens.motionMedium,
          curve: Curves.easeOutCubic,
          child: _expanded
              ? Column(children: [
                  if (widget.tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: _EmptyCourseRow(onAdd: widget.onAddTask),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Column(children: [
                        for (var i = 0; i < widget.tasks.length; i++) ...[
                          const SizedBox(height: 6),
                          AnimatedListWrapper(
                            index: i,
                            child: TaskCard(
                              task: widget.tasks[i],
                              onToggleStatus: () =>
                                  context.read<TaskService>().toggleStatus(widget.tasks[i].id),
                              onEdit: () => widget.onEditTask(widget.tasks[i]),
                              onDelete: () => widget.onDeleteTask(widget.tasks[i]),
                            ),
                          ),
                        ],
                      ]),
                    ),
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

// ─── Course ⋮ Menu ───────────────────────────────────────────────────────────

class _CourseMenuButton extends StatelessWidget {
  const _CourseMenuButton({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Course options',
      icon:
          Icon(PhosphorIcons.dotsThreeVertical(), color: theme.colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      onSelected: (value) async {
        if (value == 'edit') {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _CourseEditorSheet(existing: course),
          );
        } else if (value == 'delete') {
          _confirmDeleteCourse(context, course);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(PhosphorIcons.pencilSimple(),
                size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 10),
            const Text('Edit course'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(PhosphorIcons.trash(),
                size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Text('Delete course',
                style: TextStyle(color: theme.colorScheme.error)),
          ]),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteCourse(
      BuildContext context, Course course) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete course?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Deleting "${course.name}" will also remove all tasks assigned to it. This can\'t be undone.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
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
      final taskSvc = context.read<TaskService>();
      final toDelete = taskSvc.tasks
          .where((t) => t.subject == course.id)
          .map((t) => t.id)
          .toList();
      for (final id in toDelete) {
        await taskSvc.delete(id);
      }
      if (context.mounted) {
        await context.read<NotesService>().deleteCourse(course.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
             Icon(PhosphorIcons.checkCircle(),
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Flexible(child: Text('Course "${course.name}" deleted')),
          ]),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }
}

// ─── Course Editor Sheet ─────────────────────────────────────────────────────

class _CourseEditorSheet extends StatefulWidget {
  const _CourseEditorSheet({this.existing});
  final Course? existing;

  @override
  State<_CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<_CourseEditorSheet> {
  late final TextEditingController _nameCtrl;
  late IconData _icon;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _icon = widget.existing != null
        ? IconData(widget.existing!.iconCodePoint, fontFamily: 'MaterialIcons')
        : _kCourseIcons.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.existing != null;

    return _BottomSheetSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(isEdit ? 'Edit course' : 'New course',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(PhosphorIcons.x(),
                    color: theme.colorScheme.onSurface),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Course name',
                hintText: 'e.g. Mathematics',
              ),
            ),
            const SizedBox(height: 16),
            Text('Icon',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _kCourseIcons)
                  _IconPickTile(
                    icon: icon,
                    selected: _icon.codePoint == icon.codePoint,
                    onTap: () => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _save(context),
                icon: Icon(isEdit ? PhosphorIcons.floppyDisk() : PhosphorIcons.plus()),
                label: Text(isEdit ? 'Save changes' : 'Create course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course name is required.')),
      );
      return;
    }

    final notesSvc = context.read<NotesService>();
    final isEdit = widget.existing != null;

    if (isEdit) {
      // Update: delete old, add new with updated info
      final oldId = widget.existing!.id;
      // Update tasks to use new course name
      final taskSvc = context.read<TaskService>();
      final now = DateTime.now();
      final newCourse = await notesSvc.addCourseAndReturn(
          name: name, icon: _icon);
      if (newCourse != null && context.mounted) {
        final tasks =
            taskSvc.tasks.where((t) => t.subject == oldId).toList();
        for (final t in tasks) {
          await taskSvc.update(
              t.copyWith(subject: newCourse.id, updatedAt: now));
        }
        await notesSvc.deleteCourse(oldId);
      }
    } else {
      await notesSvc.addCourse(name: name, icon: _icon);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
           Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(isEdit ? 'Course updated!' : 'Course "$name" created!'),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ));
    }
  }
}

class _IconPickTile extends StatelessWidget {
  const _IconPickTile(
      {required this.icon, required this.selected, required this.onTap});
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon,
            size: 22,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
      ),
    );
  }
}

// ─── Task Editor Sheet ───────────────────────────────────────────────────────

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({this.existing, this.preselectedCourseId});
  final Task? existing;
  final String? preselectedCourseId;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _selectedCourseId;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.medium;
  bool _reminder = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? '');
    // description stored separately from subject/courseId
    _description = TextEditingController();
    _dueAt = t?.dueAt;
    _priority = t?.priority ?? TaskPriority.medium;
    _reminder = t?.reminderEnabled ?? false;

    if (t != null) {
      _selectedCourseId = t.subject.isNotEmpty ? t.subject : null;
    } else if (widget.preselectedCourseId != null) {
      _selectedCourseId = widget.preselectedCourseId;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final courses = context.watch<NotesService>().courses;

    return _BottomSheetSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    existing == null ? 'New task' : 'Edit task',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(PhosphorIcons.x(),
                      color: theme.colorScheme.onSurface),
                ),
              ]),
              const SizedBox(height: 12),

              // Title
              TextField(
                controller: _title,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Finish lab report',
                ),
              ),
              const SizedBox(height: 10),

              // Description
              TextField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add a short note…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // Course
              Text('Course',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (courses.isEmpty)
                Text(
                  'No courses yet — create one in the "By Course" tab.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _CourseChip(
                      label: 'None',
                      icon: PhosphorIcons.tray(),
                      selected: _selectedCourseId == null,
                      onTap: () => setState(() => _selectedCourseId = null),
                    ),
                    for (final c in courses) ...[
                      const SizedBox(width: 8),
                      _CourseChip(
                        label: c.name,
                        icon: IconData(c.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        selected: _selectedCourseId == c.id,
                        onTap: () =>
                            setState(() => _selectedCourseId = c.id),
                      ),
                    ],
                  ]),
                ),

              const SizedBox(height: 14),

              // Due date
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDue(context),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(children: [
                        Icon(PhosphorIcons.calendarBlank(),
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dueAt == null
                                ? 'Set due date'
                                : _formatDue(context, _dueAt!),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Clear due date',
                  onPressed:
                      _dueAt == null ? null : () => setState(() => _dueAt = null),
                  icon: Icon(PhosphorIcons.backspace(),
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ]),
              const SizedBox(height: 14),

              // Priority
              Text('Priority',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments:  [
                  ButtonSegment(
                      value: TaskPriority.low,
                      label: Text('Low'),
                      icon: Icon(PhosphorIcons.leaf())),
                  ButtonSegment(
                      value: TaskPriority.medium,
                      label: Text('Med'),
                      icon: Icon(PhosphorIcons.lightning())),
                  ButtonSegment(
                      value: TaskPriority.high,
                      label: Text('High'),
                      icon: Icon(PhosphorIcons.flame())),
                ],
                selected: {_priority},
                onSelectionChanged: (s) =>
                    setState(() => _priority = s.first),
              ),
              const SizedBox(height: 10),

              // Reminders
              SwitchListTile.adaptive(
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
                title: const Text('Reminders'),
                subtitle: const Text('Bell icon on task cards'),
                secondary:  Icon(PhosphorIcons.bellRinging()),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _save(context),
                  icon:  Icon(PhosphorIcons.floppyDisk()),
                  label:
                      Text(existing == null ? 'Create task' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDue(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _dueAt ?? now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueAt ?? now));
    if (time == null || !context.mounted) return;
    setState(() => _dueAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save(BuildContext context) async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.existing;
    final courseId = _selectedCourseId ?? '';

    if (existing == null) {
      final task = Task(
        id: '${now.microsecondsSinceEpoch}',
        title: title,
        subject: courseId,
        dueAt: _dueAt,
        status: TaskStatus.todo,
        priority: _priority,
        reminderEnabled: _reminder,
        createdAt: now,
        updatedAt: now,
      );
      await context.read<TaskService>().add(task);
    } else {
      await context.read<TaskService>().update(
            existing.copyWith(
              title: title,
              subject: courseId,
              dueAt: _dueAt,
              dueAtToNull: _dueAt == null,
              priority: _priority,
              reminderEnabled: _reminder,
              updatedAt: now,
            ),
          );
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
           Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
                existing == null ? 'Task "$title" created!' : 'Task updated!'),
          ),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  String _formatDue(BuildContext context, DateTime dt) {
    final l10n = MaterialLocalizations.of(context);
    final date = l10n.formatMediumDate(dt);
    final time = l10n.formatTimeOfDay(TimeOfDay.fromDateTime(dt),
        alwaysUse24HourFormat: false);
    return '$date • $time';
  }
}

// ─── Course Chip ─────────────────────────────────────────────────────────────

class _CourseChip extends StatelessWidget {
  const _CourseChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 16,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  )),
        ]),
      ),
    );
  }
}

// ─── Filters Row ─────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.status,
    required this.priority,
    required this.courseFilter,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onCourseChanged,
    required this.onClear,
  });

  final TaskStatus? status;
  final TaskPriority? priority;
  final String? courseFilter;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final ValueChanged<String?> onCourseChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = context.watch<NotesService>().courses;
    final hasAny = status != null || priority != null || courseFilter != null;

    String courseLabel = 'Course';
    if (courseFilter != null) {
      final c = courses.cast<Course?>().firstWhere((c) => c?.id == courseFilter,
          orElse: () => null);
      courseLabel = c?.name ?? 'Course';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _FilterChip(
          label: status == null ? 'Status' : _statusLabel(status!),
          icon: PhosphorIcons.slidersHorizontal(),
          selected: status != null,
          onTap: () => _pickStatus(context),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: priority == null ? 'Priority' : _priorityLabel(priority!),
          icon: PhosphorIcons.flame(),
          selected: priority != null,
          onTap: () => _pickPriority(context),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: courseLabel,
          icon: PhosphorIcons.graduationCap(),
          selected: courseFilter != null,
          onTap: () => _pickCourse(context, courses),
        ),
        if (hasAny) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onClear,
            child: Text('Clear',
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ]),
    );
  }

  Future<void> _pickStatus(BuildContext context) async {
    final picked = await _pickEnum<TaskStatus>(
      context,
      title: 'Status',
      values: TaskStatus.values,
      labelFor: _statusLabel,
      selected: status,
    );
    if (context.mounted) onStatusChanged(picked);
  }

  Future<void> _pickPriority(BuildContext context) async {
    final picked = await _pickEnum<TaskPriority>(
      context,
      title: 'Priority',
      values: TaskPriority.values,
      labelFor: _priorityLabel,
      selected: priority,
    );
    if (context.mounted) onPriorityChanged(picked);
  }

  Future<void> _pickCourse(BuildContext context, List<Course> courses) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return _BottomSheetSurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _PickChip(
                    label: 'Any',
                    selected: courseFilter == null,
                    onTap: () => Navigator.of(context).pop(null),
                  ),
                  for (final c in courses)
                    _PickChip(
                      label: c.name,
                      selected: courseFilter == c.id,
                      onTap: () => Navigator.of(context).pop(c.id),
                    ),
                ]),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
    if (context.mounted) onCourseChanged(picked);
  }

  String _statusLabel(TaskStatus s) => switch (s) {
        TaskStatus.todo => 'To do',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.done => 'Done',
      };

  String _priorityLabel(TaskPriority p) => switch (p) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
      };
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          Icon(PhosphorIcons.caretDown(), size: 18, color: fg),
        ]),
      ),
    );
  }
}

Future<T?> _pickEnum<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required String Function(T) labelFor,
  required T? selected,
}) async {
  return showModalBottomSheet<T?>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      return _BottomSheetSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _PickChip(
                    label: 'Any',
                    selected: selected == null,
                    onTap: () => Navigator.of(context).pop(null)),
                for (final v in values)
                  _PickChip(
                      label: labelFor(v),
                      selected: selected == v,
                      onTap: () => Navigator.of(context).pop(v)),
              ]),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

class _PickChip extends StatelessWidget {
  const _PickChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Empty states ────────────────────────────────────────────────────────────

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(Icons.checklist_rounded,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No tasks yet',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 10),
          Text('Create a task and keep everything moving.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon:  Icon(PhosphorIcons.plus()),
            label: const Text('Create first task'),
          ),
        ]),
      ),
    );
  }
}

class _NoCourses extends StatelessWidget {
  const _NoCourses({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child:
                  Icon(PhosphorIcons.graduationCap(), color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No courses yet',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 10),
          Text('Add a course to organise your tasks by subject.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon:  Icon(PhosphorIcons.plus()),
            label: const Text('Add first course'),
          ),
        ]),
      ),
    );
  }
}

class _EmptyCourseRow extends StatelessWidget {
  const _EmptyCourseRow({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(PhosphorIcons.tray(),
          size: 16, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Expanded(
        child: Text('No tasks here yet',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
      TextButton.icon(
        onPressed: onAdd,
        icon:  Icon(PhosphorIcons.plus(), size: 16),
        label: const Text('Add task'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
    ]);
  }
}

// ─── Bottom sheet surface ────────────────────────────────────────────────────

class _BottomSheetSurface extends StatelessWidget {
  const _BottomSheetSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
              width: 1),
        ),
        child: child,
      ),
    );
  }
}