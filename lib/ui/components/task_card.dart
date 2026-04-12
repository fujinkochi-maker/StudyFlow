import 'package:flutter/material.dart';
import 'package:study_flow/features/tasks/task.dart';
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
      TaskStatus.todo => Icons.radio_button_unchecked_rounded,
      TaskStatus.inProgress => Icons.timelapse_rounded,
      TaskStatus.done => Icons.check_circle_rounded,
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

    return Card(
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
                          Pill(label: task.subject, color: scheme.primary, icon: Icons.sell_rounded),
                          Pill(label: _priorityLabel(task.priority), color: priorityColor, icon: Icons.local_fire_department_rounded),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_rounded, size: 16, color: dueColor),
                              const SizedBox(width: 6),
                              Text(dueText, style: theme.textTheme.bodySmall?.copyWith(color: dueColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          if (task.reminderEnabled)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_active_rounded, size: 16, color: scheme.primary),
                                const SizedBox(width: 6),
                                Text('Reminder', style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, color: scheme.onSurface), const SizedBox(width: 8), const Text('Edit')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: scheme.error), const SizedBox(width: 8), Text('Delete', style: TextStyle(color: scheme.error))])),
                  ],
                ),
              ],
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
