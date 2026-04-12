import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/notes/course.dart';
import 'package:study_flow/features/notes/note.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/theme.dart';
import 'package:study_flow/ui/pages/note_editor_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTES PAGE  —  Folder grid view
// ─────────────────────────────────────────────────────────────────────────────

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: Consumer<NotesService>(
        builder: (context, notes, _) {
          final courses = _query.isEmpty
              ? notes.courses
              : notes.courses
                  .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return Scaffold(
            backgroundColor: Colors.transparent,
            // ── FAB ──────────────────────────────────────────────────────────
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddCourseSheet(context),
              child: const Icon(Icons.add_rounded),
            ),
            body: CustomScrollView(
              slivers: [
                // ── App bar ──────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  title: Text('Notes',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),

                // ── Search bar ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Find a course…',
                        prefixIcon:
                            Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // ── Empty state ───────────────────────────────────────────────
                if (courses.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyFolders(onAdd: () => _showAddCourseSheet(context)),
                  )
                else
                  // ── Folder grid ───────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          final noteCount =
                              notes.notesForCourse(course.id).length;
                          return _FolderCard(
                            course: course,
                            noteCount: noteCount,
                            onTap: () => _openFolder(context, course),
                            onEdit: () =>
                                _showEditCourseSheet(context, course),
                            onDelete: () => _confirmDelete(context, course),
                          );
                        },
                        childCount: courses.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFolder(BuildContext context, Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseFolderPage(course: course),
      ),
    );
  }

  Future<void> _showAddCourseSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CourseEditorSheet(),
    );
  }

  Future<void> _showEditCourseSheet(BuildContext context, Course course) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseEditorSheet(existing: course),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Course course) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete folder?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          '"${course.name}" and all its notes will be permanently removed.',
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
                foregroundColor: theme.colorScheme.onError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<NotesService>().deleteCourse(course.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('"${course.name}" deleted'),
            ]),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOLDER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.course,
    required this.noteCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Course course;
  final int noteCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folderColor = course.folderColor ?? scheme.surfaceContainerHighest;
    final isDark = theme.brightness == Brightness.dark;

    // Compute legible label color
    final lum = folderColor.computeLuminance();
    final labelBg = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.9);
    final labelFg = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: folderColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.09),
          ),
          boxShadow: [
            BoxShadow(
              color: folderColor.withValues(alpha: isDark ? 0.25 : 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Folder tab nub at top
            Positioned(
              top: 0,
              left: 14,
              child: Container(
                width: 48,
                height: 12,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.09),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ),
            ),

            // ⋮ menu
            Positioned(
              top: 8,
              right: 8,
              child: _FolderMenu(onEdit: onEdit, onDelete: onDelete),
            ),

            // Bottom label pill
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.12), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.name.toUpperCase(),
                      style: TextStyle(
                        color: labelFg,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (noteCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$noteCount note${noteCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: labelFg.withValues(alpha: 0.55),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderMenu extends StatelessWidget {
  const _FolderMenu({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Options',
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Icon(Icons.more_horiz_rounded, size: 16, color: scheme.onSurface),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_rounded, size: 18, color: scheme.onSurface),
            const SizedBox(width: 10),
            const Text('Edit'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_rounded, size: 18, color: scheme.error),
            const SizedBox(width: 10),
            Text('Delete', style: TextStyle(color: scheme.error)),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSE EDITOR SHEET  — Add / Edit with color picker
// ─────────────────────────────────────────────────────────────────────────────

class _CourseEditorSheet extends StatefulWidget {
  const _CourseEditorSheet({this.existing});
  final Course? existing;

  @override
  State<_CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<_CourseEditorSheet> {
  late final TextEditingController _name;
  Color? _color;

  static const _presets = [
    null, // default (theme)
    Color(0xFFFFB3BA), // pink
    Color(0xFFB3D9FF), // blue
    Color(0xFFD4B3FF), // purple
    Color(0xFFB3FFD1), // green
    Color(0xFFFFF4B3), // yellow
    Color(0xFFFFD4B3), // orange
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.folderColor;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.existing != null;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Text(isEdit ? 'Edit Course' : 'Add Course',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: scheme.onSurface),
              ),
            ]),
            const SizedBox(height: 16),

            // Course name
            Text('Course Name',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g., MATH 55'),
            ),
            const SizedBox(height: 20),

            // Folder color picker
            Row(children: [
              const Icon(Icons.folder_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Folder Color',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            Row(
              children: _presets.map((c) {
                final isSelected = c == null
                    ? _color == null
                    : _color?.value == c.value;
                final displayColor = c ?? scheme.surfaceContainerHighest;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: AppTokens.motionFast,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.25),
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded,
                              size: 14,
                              color: c == null ? scheme.onSurface : Colors.black87)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Custom color label
            Text('Custom Color',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _CustomColorInput(
              color: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(isEdit ? 'Save Changes' : 'Add Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course name is required')));
      return;
    }
    final svc = context.read<NotesService>();
    if (widget.existing == null) {
      await svc.addCourseAndReturn(
          name: name, icon: Icons.folder_rounded, folderColor: _color);
    } else {
      await svc.updateCourse(widget.existing!.copyWith(
        name: name,
        folderColorValue: _color?.value,
        clearColor: _color == null,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _CustomColorInput extends StatefulWidget {
  const _CustomColorInput({required this.color, required this.onChanged});
  final Color? color;
  final ValueChanged<Color?> onChanged;

  @override
  State<_CustomColorInput> createState() => _CustomColorInputState();
}

class _CustomColorInputState extends State<_CustomColorInput> {
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(
      text: widget.color == null
          ? ''
          : '#${widget.color!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: widget.color ?? scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: _hex,
          decoration: InputDecoration(
            hintText: '#ffffff',
            hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          ),
          onChanged: (v) {
            final hex = v.replaceAll('#', '');
            if (hex.length == 6) {
              try {
                final c = Color(int.parse('FF$hex', radix: 16));
                widget.onChanged(c);
              } catch (_) {}
            } else if (hex.isEmpty) {
              widget.onChanged(null);
            }
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No folders yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Tap + to create your first course folder.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create folder'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSE FOLDER PAGE  — Note list inside a folder
// ─────────────────────────────────────────────────────────────────────────────

class CourseFolderPage extends StatefulWidget {
  const CourseFolderPage({super.key, required this.course});
  final Course course;

  @override
  State<CourseFolderPage> createState() => _CourseFolderPageState();
}

class _CourseFolderPageState extends State<CourseFolderPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folderColor =
        widget.course.folderColor ?? scheme.primaryContainer;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            onPressed: () => _importFile(context),
            tooltip: 'Import file',
            child: const Icon(Icons.attach_file_rounded),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'newNote',
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('New Note'),
          ),
        ],
      ),
      body: Consumer<NotesService>(
        builder: (context, notes, _) {
          final allNotes = notes.notesForCourse(widget.course.id);
          final filtered = _query.isEmpty
              ? allNotes
              : allNotes
                  .where((n) =>
                      n.title.toLowerCase().contains(_query.toLowerCase()) ||
                      n.body.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return CustomScrollView(
            slivers: [
              // ── Header with folder color ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: folderColor,
                foregroundColor: _contrastColor(folderColor),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.name,
                        style: TextStyle(
                          color: _contrastColor(folderColor),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        '${allNotes.length} note${allNotes.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: _contrastColor(folderColor).withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'New note',
                    onPressed: () => _openEditor(context),
                    icon: Icon(Icons.add_rounded,
                        color: _contrastColor(folderColor)),
                  ),
                ],
              ),

              // ── Search ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search notes…',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: scheme.onSurfaceVariant),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Notes list ────────────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _EmptyNotes(
                    hasSearch: _query.isNotEmpty,
                    onAdd: () => _openEditor(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _NoteTile(
                      note: filtered[i],
                      folderColor: folderColor,
                      onTap: () => _openEditor(context, existing: filtered[i]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.45 ? Colors.black : Colors.white;
  }

  void _openEditor(BuildContext context, {Note? existing}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NoteEditorPage(
        course: widget.course,
        existing: existing,
      ),
    ));
  }

  Future<void> _importFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        lockParentWindow: true,
        dialogTitle: 'Select file',
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileName = file.name;
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      String title = fileName;
      String body = '📎 Imported ${ext.toUpperCase()} file: $fileName';
      final filePath = file.path;

      if (mounted) {
        await context.read<NotesService>().addNote(
          courseId: widget.course.id,
          title: title,
          body: body,
          attachedFilePath: filePath,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Flexible(child: Text('"$fileName" imported')),
            ]),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Import failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

// ── Note tile ─────────────────────────────────────────────────────────────────

class _NoteTile extends StatelessWidget {
  const _NoteTile(
      {required this.note, required this.folderColor, required this.onTap});
  final Note note;
  final Color folderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeAgo = _timeAgo(note.updatedAt);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: folderColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.sticky_note_2_rounded,
                    color: folderColor.computeLuminance() > 0.8
                        ? scheme.primary
                        : folderColor,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      note.body.replaceAll('\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.3),
                    ),
                    const SizedBox(height: 5),
                    Text(timeAgo,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              if (note.hasAttachedFile)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  tooltip: 'Open file',
                  onPressed: () async {
                    final path = note.attachedFilePath;
                    if (path != null) {
                      final result = await OpenFile.open(path);
                      if (result.type != ResultType.done && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open file: ${result.message}')),
                        );
                      }
                    }
                  },
                )
              else
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Empty notes ───────────────────────────────────────────────────────────────

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.hasSearch, required this.onAdd});
  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.note_alt_outlined,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No notes match your search' : 'No notes yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (!hasSearch) ...[
              Text('Tap "New Note" to start writing.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Start writing'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}