import 'package:flutter/material.dart';
import 'package:study_flow/theme.dart';

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use theme brightness to determine text color, not the color brightness
    final fg = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.88), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
