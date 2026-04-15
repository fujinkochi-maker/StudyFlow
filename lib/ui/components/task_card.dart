import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:study_flow/features/tasks/task.dart';
import 'package:study_flow/services/haptic_service.dart';
import 'package:study_flow/theme.dart';
import 'package:study_flow/ui/components/pill.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onToggleStatus, required this.onEdit, required this.onDelete});

  final Task task;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dueText = task.dueAt == null ? 'No due date' : _formatDue(context, task.dueAt!);
    final dueColor = task.isOverdue ? scheme.error : scheme.onSurfaceVariant;
    final statusIcon = switch (task.status) {
      TaskStatus.todo => PhosphorIcons.circle(),
      TaskStatus.inProgress => PhosphorIcons.clock(),
      TaskStatus.done => PhosphorIcons.checkCircle(),
    };
    final statusColor = switch (task.status) {
      TaskStatus.todo => scheme.onSurfaceVariant,
      TaskStatus.inProgress => scheme.primary,
      TaskStatus.done => Colors.green,
    };

    final priorityColor = switch (task.priority) {
      TaskPriority.low => Colors.green,
      TaskPriority.medium => Colors.orange,
      TaskPriority.high => Colors.red,
    };

    return GestureDetector(
      onLongPress: () => _showTaskOptions(context, scheme),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onToggleStatus,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Pill(label: task.subject, color: scheme.primary, icon: PhosphorIcons.tag()),
                          Pill(label: _priorityLabel(task.priority), color: priorityColor, icon: PhosphorIcons.fire()),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.calendarBlank(), size: 16, color: dueColor),
                              const SizedBox(width: 6),
                              Text(dueText, style: theme.textTheme.bodySmall?.copyWith(color: dueColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          if (task.reminderEnabled)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIcons.bellRinging(), size: 16, color: scheme.primary),
                                const SizedBox(width: 6),
                                Text('Reminder', style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showTaskOptions(BuildContext context, ColorScheme scheme) {
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
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: scheme.error),
              title: Text('Delete', style: TextStyle(color: scheme.error)),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority p) => switch (p) { TaskPriority.low => 'Low', TaskPriority.medium => 'Medium', TaskPriority.high => 'High' };

  String _formatDue(BuildContext context, DateTime dt) {
    final l10n = MaterialLocalizations.of(context);
    final date = l10n.formatMediumDate(dt);
    final time = l10n.formatTimeOfDay(TimeOfDay.fromDateTime(dt), alwaysUse24HourFormat: false);
    return '$date • $time';
  }
}
