import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/notes/course.dart';
import 'package:study_flow/features/notes/note.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FULL-SCREEN NOTE EDITOR
// ─────────────────────────────────────────────────────────────────────────────

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, required this.course, this.existing});

  final Course course;
  final Note? existing;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  final _bodyFocus = FocusNode();

  bool _saving = false;
  bool _hasChanges = false;
  bool _showToolbar = true;

  // Live word / char stats
  int get _wordCount =>
      _body.text.trim().isEmpty ? 0 : _body.text.trim().split(RegExp(r'\s+')).length;
  int get _charCount => _body.text.length;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _body = TextEditingController(text: widget.existing?.body ?? '');
    _title.addListener(_onChange);
    _body.addListener(_onChange);
  }

  void _onChange() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _title.removeListener(_onChange);
    _body.removeListener(_onChange);
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folderColor = widget.course.folderColor ?? scheme.primaryContainer;
    final contrastFg = folderColor.computeLuminance() > 0.45 ? Colors.black : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_hasChanges) {
          final save = await _showSaveDialog();
          if (save == true) await _save(pop: true);
          else if (save == false && mounted) Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: folderColor,
          foregroundColor: contrastFg,
          elevation: 0,
          titleSpacing: 0,
          title: TextField(
            controller: _title,
            style: TextStyle(
              color: contrastFg,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Note title…',
              hintStyle: TextStyle(color: contrastFg.withValues(alpha: 0.5)),
              border: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            // Toolbar toggle
            IconButton(
              tooltip: _showToolbar ? 'Hide toolbar' : 'Show toolbar',
              icon: Icon(
                _showToolbar ? Icons.format_clear_rounded : Icons.format_shapes_rounded,
                color: contrastFg,
              ),
              onPressed: () => setState(() => _showToolbar = !_showToolbar),
            ),
            // Save
            TextButton(
              onPressed: _saving ? null : () => _save(pop: true),
              child: Text(
                'Save',
                style: TextStyle(
                  color: contrastFg,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            if (widget.existing != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: contrastFg),
                onSelected: (v) {
                  if (v == 'delete') _confirmDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_rounded, size: 18, color: scheme.error),
                      const SizedBox(width: 10),
                      Text('Delete note', style: TextStyle(color: scheme.error)),
                    ]),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Stats bar ────────────────────────────────────────────────────
            Container(
              color: folderColor.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                Icon(Icons.folder_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(widget.course.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7))),
                const Spacer(),
                Text(
                  '$_wordCount words  •  $_charCount chars',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
              ]),
            ),

            // ── Formatting toolbar ───────────────────────────────────────────
            if (_showToolbar)
              _FormattingToolbar(
                onInsert: _insert,
                onWrap: _wrap,
                onFocusBody: () => _bodyFocus.requestFocus(),
              ),

            // ── Body editor ─────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => _bodyFocus.requestFocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
                  child: TextField(
                    controller: _body,
                    focusNode: _bodyFocus,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing your notes here…\n\nYou can use the toolbar above to format your text.',
                      hintStyle: TextStyle(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                          height: 1.7),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom safe area ─────────────────────────────────────────────
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Text helpers ──────────────────────────────────────────────────────────

  void _insert(String text) {
    final val = _body.value;
    final start = val.selection.start < 0 ? val.text.length : val.selection.start;
    final end = val.selection.end < 0 ? val.text.length : val.selection.end;
    final newText = val.text.replaceRange(start, end, text);
    _body.value = val.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _bodyFocus.requestFocus();
  }

  void _wrap(String left, String right) {
    final val = _body.value;
    final start = val.selection.start;
    final end = val.selection.end;
    if (start < 0 || end < 0 || start == end) {
      _insert('$left$right');
      return;
    }
    final selected = val.text.substring(start, end);
    final wrapped = '$left$selected$right';
    final newText = val.text.replaceRange(start, end, wrapped);
    _body.value = val.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: start + left.length,
        extentOffset: start + left.length + selected.length,
      ),
    );
    _bodyFocus.requestFocus();
  }

  // ── Save / Delete / Dialog ────────────────────────────────────────────────

  Future<void> _save({bool pop = false}) async {
    setState(() => _saving = true);
    try {
      final body = _body.text.trim();
      final title = _title.text.trim();
      final svc = context.read<NotesService>();

      if (widget.existing == null) {
        if (body.isEmpty && title.isEmpty) {
          if (pop && mounted) Navigator.of(context).pop();
          return;
        }
        await svc.addNote(
          courseId: widget.course.id,
          title: title.isEmpty ? 'Untitled' : title,
          body: body.isEmpty ? '(no content)' : body,
        );
      } else {
        await svc.updateNote(widget.existing!.copyWith(
          title: title.isEmpty ? 'Untitled' : title,
          body: body.isEmpty ? '(no content)' : body,
        ));
      }
      setState(() => _hasChanges = false);
      if (pop && mounted) Navigator.of(context).pop();
      if (!pop && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Saved!'),
          ]),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _showSaveDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Save changes?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('You have unsaved changes. Save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Don't save"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete note?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete "${widget.existing?.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<NotesService>().deleteNote(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMATTING TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────

class _FormattingToolbar extends StatelessWidget {
  const _FormattingToolbar({
    required this.onInsert,
    required this.onWrap,
    required this.onFocusBody,
  });

  final void Function(String) onInsert;
  final void Function(String left, String right) onWrap;
  final VoidCallback onFocusBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _ToolBtn(icon: Icons.title_rounded, label: 'H1',
                onTap: () => onInsert('\n# ')),
            _ToolBtn(icon: Icons.format_size_rounded, label: 'H2',
                onTap: () => onInsert('\n## ')),
            const _Divider(),
            _ToolBtn(icon: Icons.format_bold_rounded, label: 'B',
                onTap: () => onWrap('**', '**')),
            _ToolBtn(icon: Icons.format_italic_rounded, label: 'I',
                onTap: () => onWrap('_', '_')),
            _ToolBtn(icon: Icons.format_underlined_rounded, label: 'U',
                onTap: () => onWrap('__', '__')),
            _ToolBtn(icon: Icons.format_strikethrough_rounded, label: 'S',
                onTap: () => onWrap('~~', '~~')),
            const _Divider(),
            _ToolBtn(icon: Icons.format_list_bulleted_rounded, label: '•',
                onTap: () => onInsert('\n- ')),
            _ToolBtn(icon: Icons.format_list_numbered_rounded, label: '1.',
                onTap: () => onInsert('\n1. ')),
            _ToolBtn(icon: Icons.check_box_rounded, label: '☑',
                onTap: () => onInsert('\n- [ ] ')),
            const _Divider(),
            _ToolBtn(icon: Icons.code_rounded, label: '</>',
                onTap: () => onWrap('`', '`')),
            _ToolBtn(icon: Icons.format_quote_rounded, label: '"',
                onTap: () => onInsert('\n> ')),
            _ToolBtn(icon: Icons.horizontal_rule_rounded, label: '—',
                onTap: () => onInsert('\n---\n')),
            const _Divider(),
            _ToolBtn(icon: Icons.link_rounded, label: 'Link',
                onTap: () => onInsert('[text](url)')),
            _ToolBtn(icon: Icons.wb_sunny_rounded, label: 'Tip',
                onTap: () => onInsert('\n💡 ')),
            _ToolBtn(icon: Icons.warning_amber_rounded, label: 'Note',
                onTap: () => onInsert('\n⚠️ ')),
          ],
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: scheme.onSurface),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
    );
  }
}