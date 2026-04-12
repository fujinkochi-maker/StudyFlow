import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/auth/auth_service.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/state/app_theme_controller.dart';
import 'package:study_flow/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
            title: Text('Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _ProfileHeader(),
                const SizedBox(height: 12),
                const _LevelAndStreak(),
                const SizedBox(height: 12),
                _ThemeCenter(),
                const SizedBox(height: 12),
                const _AccountActions(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = context.watch<AuthService>().currentUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withValues(alpha: 0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(Icons.person_rounded, color: scheme.onPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'Student', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(user?.email ?? 'Local-only profile', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.verified_rounded, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _LevelAndStreak extends StatelessWidget {
  const _LevelAndStreak();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = context.watch<AuthService>().currentUser;
    final level = user?.level ?? 1;
    final streak = user?.streakDays ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_graph_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Level', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('$level', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Keep completing tasks + quizzes', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  Text('$streak days', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Study or finish a task today', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActions extends StatefulWidget {
  const _AccountActions();

  @override
  State<_AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends State<_AccountActions> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = context.watch<AuthService>().currentUser;
    if (_nameCtrl.text.isEmpty && (user?.displayName ?? '').isNotEmpty) {
      _nameCtrl.text = user!.displayName;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context.read<AuthService>().updateProfile(displayName: _nameCtrl.text);
                      if (context.mounted) FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthService>().logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: Icon(Icons.logout_rounded, color: scheme.error),
                    label: Text('Log out', style: TextStyle(color: scheme.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCenter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ctrl = context.watch<AppThemeController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Icon(Icons.palette_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Themes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 10),
            Text('Pick a preset palette or craft your own accent color.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in AppThemePresets.all)
                  _PresetTile(
                    preset: preset,
                    selected: !ctrl.isUsingCustom && ctrl.presetId == preset.id,
                    onTap: () => context.read<AppThemeController>().setPreset(preset.id),
                  ),
                _CustomTile(
                  selected: ctrl.isUsingCustom,
                  color: ctrl.seedColor,
                  onTap: () => _openCustomColor(context),
                  onClear: ctrl.isUsingCustom ? () => context.read<AppThemeController>().clearCustomSeed() : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ModeTile(
                    title: 'Light',
                    icon: Icons.light_mode_rounded,
                    selected: ctrl.themeMode == ThemeMode.light,
                    onTap: () => context.read<AppThemeController>().setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeTile(
                    title: 'Josh',
                    icon: Icons.dark_mode_rounded,
                    selected: ctrl.themeMode == ThemeMode.dark,
                    onTap: () => context.read<AppThemeController>().setThemeMode(ThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeTile(
                    title: 'Auto',
                    icon: Icons.brightness_auto_rounded,
                    selected: ctrl.themeMode == ThemeMode.system,
                    onTap: () => context.read<AppThemeController>().setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomColor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomColorSheet(initial: context.read<AppThemeController>().seedColor),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.selected, required this.onTap});
  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: scheme.outline.withValues(alpha: selected ? 0.26 : 0.14), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final c in preset.preview)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle_rounded, color: scheme.primary, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(preset.name, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Preset', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({required this.selected, required this.color, required this.onTap, this.onClear});
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: scheme.outline.withValues(alpha: selected ? 0.26 : 0.14), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
                const SizedBox(width: 8),
                Text('Custom', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                if (selected && onClear != null)
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Pick any accent', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.title, required this.icon, required this.selected, required this.onTap});
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: selected ? scheme.onPrimary : scheme.onSurface, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({required this.initial});
  final Color initial;

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  late double _r;
  late double _g;
  late double _b;

  @override
  void initState() {
    super.initState();
    _r = widget.initial.red.toDouble();
    _g = widget.initial.green.toDouble();
    _b = widget.initial.blue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = Color.fromARGB(255, _r.round(), _g.round(), _b.round());
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Custom theme color', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close_rounded, color: scheme.onSurface)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(AppRadius.xl))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ColorSlider(label: 'Red', value: _r, active: Colors.red, onChanged: (v) => setState(() => _r = v)),
            _ColorSlider(label: 'Green', value: _g, active: Colors.green, onChanged: (v) => setState(() => _g = v)),
            _ColorSlider(label: 'Blue', value: _b, active: Colors.blue, onChanged: (v) => setState(() => _b = v)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await context.read<AppThemeController>().setCustomSeed(c);
                  if (context.mounted) context.pop();
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({required this.label, required this.value, required this.active, required this.onChanged});
  final String label;
  final double value;
  final Color active;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: active, thumbColor: active),
              child: Slider(min: 0, max: 255, value: value, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}


