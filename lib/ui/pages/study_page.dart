import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/notes/course.dart';
import 'package:study_flow/features/notes/notes_service.dart';
import 'package:study_flow/features/study/flashcard.dart';
import 'package:study_flow/features/study/study_service.dart';
import 'package:study_flow/theme.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  String? _courseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Consumer2<NotesService, StudyService>(
        builder: (context, notes, study, _) {
          final courses = notes.courses;
          _courseId ??= courses.isEmpty ? null : courses.first.id;
          final selected = _courseId == null ? null : notes.courseById(_courseId!);

          return DefaultTabController(
            length: 2,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  title: const Text('Study'),
                  actions: selected != null
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _CoursePicker(
                              courses: courses,
                              selectedCourseId: selected.id,
                              onChanged: (id) => setState(() => _courseId = id),
                            ),
                          ),
                        ]
                      : null,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.horizontalMd,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: TabBar(
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                          labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                          tabs:  [
                            Tab(text: 'Quiz', icon: Icon(PhosphorIcons.question())),
                            Tab(text: 'Cards', icon: Icon(PhosphorIcons.cards())),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    children: [
                      _QuizTab(course: selected),
                      _FlashcardsTab(course: selected),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoursePicker extends StatelessWidget {
  const _CoursePicker({required this.courses, required this.selectedCourseId, required this.onChanged});
  final List<Course> courses;
  final String selectedCourseId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourseId,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            for (final c in courses)
              DropdownMenuItem(
                value: c.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconData(c.iconCodePoint, fontFamily: 'MaterialIcons'), size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizTab extends StatelessWidget {
  const _QuizTab({required this.course});
  final Course? course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = course;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      children: [
        Card(
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
                      child: Icon(PhosphorIcons.question(), color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Quiz Generator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  c == null ? 'Create a course in Notes first.' : 'Generate quizzes from your flashcards or your saved notes.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: c == null ? null : () => _startMcq(context, c.id),
                      icon:  Icon(PhosphorIcons.sparkle()),
                      label: const Text('Generate from flashcards'),
                    ),
                    OutlinedButton.icon(
                      onPressed: c == null ? null : () => _startFromNotes(context, c.id),
                      icon: Icon(PhosphorIcons.notebook()),
                      label: const Text('Generate from notes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tip', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Your quiz accuracy feeds the Performance Dashboard automatically.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startMcq(BuildContext context, String courseId) async {
    final study = context.read<StudyService>();
    final questions = study.generateMcqFromCards(courseId: courseId);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least 2 flashcards to generate a quiz.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _McqQuizSheet(courseId: courseId, questions: questions),
    );
  }

  Future<void> _startFromNotes(BuildContext context, String courseId) async {
    final study = context.read<StudyService>();
    final notes = context.read<NotesService>();
    final qa = study.generateIdFromNotes(courseId: courseId, notes: notes);
    if (qa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add more notes in this course to generate a quiz.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IdQuizSheet(courseId: courseId, items: qa),
    );
  }
}

class _FlashcardsTab extends StatelessWidget {
  const _FlashcardsTab({required this.course});
  final Course? course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = course;
    return Consumer<StudyService>(
      builder: (context, study, _) {
        final cards = c == null ? const <Flashcard>[] : study.cardsForCourse(c.id);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Icon(PhosphorIcons.cards(), color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Flashcards', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(c == null ? 'Select a course' : '${cards.length} cards in ${c.name}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: c == null ? null : () => _openCardEditor(context, courseId: c.id),
                      icon:  Icon(PhosphorIcons.plus()),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (c == null)
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Create a course in Notes, then add flashcards here.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))))
            else if (cards.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.plus(), color: scheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(child: Text('No flashcards yet. Tap Add to create your first one.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35))),
                    ],
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.92),
                  itemCount: cards.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _FlipCard(
                      front: cards[index].front,
                      back: cards[index].back,
                      onLongPress: () => _openCardEditor(context, courseId: c.id, existing: cards[index]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.handPointing(), color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Swipe like a feed. Tap to flip. Long-press to edit.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openCardEditor(BuildContext context, {required String courseId, Flashcard? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FlashcardEditorSheet(courseId: courseId, existing: existing),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back, required this.onLongPress});
  final String front;
  final String back;
  final VoidCallback onLongPress;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppTokens.motionMedium);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: InkWell(
        onTap: _flip,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final t = _anim.value;
            final angle = (t * 3.14159265);
            final showingFront = t < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
              child: Card(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: LinearGradient(colors: [scheme.primary.withValues(alpha: 0.18), scheme.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: showingFront ? Matrix4.identity() : (Matrix4.identity()..rotateY(3.14159265)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(showingFront ? PhosphorIcons.question() : PhosphorIcons.lightbulb(), color: scheme.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(showingFront ? 'Question' : 'Answer', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: scheme.onSurface))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Center(
                            child: Text(
                              showingFront ? widget.front : widget.back,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.25),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Text('Tap to flip', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _flip() {
    if (_ctrl.isAnimating) return;
    setState(() => _isFront = !_isFront);
    if (_isFront) {
      _ctrl.reverse(from: 1);
    } else {
      _ctrl.forward(from: 0);
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlashcardEditorSheet extends StatefulWidget {
  const _FlashcardEditorSheet({required this.courseId, this.existing});
  final String courseId;
  final Flashcard? existing;

  @override
  State<_FlashcardEditorSheet> createState() => _FlashcardEditorSheetState();
}

class _FlashcardEditorSheetState extends State<_FlashcardEditorSheet> {
  late final TextEditingController _front;
  late final TextEditingController _back;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _front = TextEditingController(text: widget.existing?.front ?? '');
    _back = TextEditingController(text: widget.existing?.back ?? '');
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: scheme.outline.withValues(alpha: 0.18))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.existing == null ? 'New flashcard' : 'Edit flashcard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => context.pop(), icon: Icon(PhosphorIcons.x(), color: scheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: _front, maxLines: 3, decoration: const InputDecoration(labelText: 'Front (question)', hintText: 'e.g., Derivative of sin(x)?')),
            const SizedBox(height: 12),
            TextField(controller: _back, maxLines: 3, decoration: const InputDecoration(labelText: 'Back (answer)', hintText: 'e.g., cos(x)')),
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.existing != null)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _delete,
                    icon: Icon(PhosphorIcons.trash(), color: scheme.error),
                    label: Text('Delete', style: TextStyle(color: scheme.error)),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) :Icon(PhosphorIcons.floppyDisk()),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final front = _front.text.trim();
    final back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill both sides of the card')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await context.read<StudyService>().addFlashcard(courseId: widget.courseId, front: front, back: back);
      } else {
        await context.read<StudyService>().updateFlashcard(widget.existing!.copyWith(front: front, back: back));
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    setState(() => _saving = true);
    try {
      await context.read<StudyService>().deleteFlashcard(existing.id);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _McqQuizSheet extends StatefulWidget {
  const _McqQuizSheet({required this.courseId, required this.questions});
  final String courseId;
  final List<Map<String, Object>> questions;

  @override
  State<_McqQuizSheet> createState() => _McqQuizSheetState();
}

class _McqQuizSheetState extends State<_McqQuizSheet> {
  int _index = 0;
  int _correct = 0;
  int? _picked;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final q = widget.questions[_index];
    final question = q['question'] as String;
    final options = (q['options'] as List).cast<String>();
    final correctIndex = q['correctIndex'] as int;
    final progress = '${_index + 1}/${widget.questions.length}';

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: scheme.outline.withValues(alpha: 0.18))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Quiz • $progress', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => context.pop(), icon: Icon(PhosphorIcons.x(), color: scheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Text(question, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.25)),
            const SizedBox(height: 12),
            for (int i = 0; i < options.length; i++) ...[
              _OptionTile(
                label: options[i],
                selected: _picked == i,
                state: !_done ? null : (i == correctIndex ? _OptionState.correct : (_picked == i ? _OptionState.wrong : null)),
                onTap: _done ? null : () => setState(() => _picked = i),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _picked == null ? null : () {
                      if (_done) return;
                      setState(() {
                        _done = true;
                        if (_picked == correctIndex) _correct++;
                      });
                    },
                    icon:  Icon(PhosphorIcons.check()),
                    label: const Text('Check'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !_done
                        ? null
                        : () async {
                            final isLast = _index == widget.questions.length - 1;
                            if (isLast) {
                              await context.read<StudyService>().recordAttempt(courseId: widget.courseId, total: widget.questions.length, correct: _correct);
                              if (context.mounted) context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved result: $_correct/${widget.questions.length}')));
                              return;
                            }
                            setState(() {
                              _index++;
                              _picked = null;
                              _done = false;
                            });
                          },
                    icon:  Icon(PhosphorIcons.arrowRight()),
                    label: Text(_index == widget.questions.length - 1 ? 'Finish' : 'Next'),
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

enum _OptionState { correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap, required this.state});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final _OptionState? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color border;
    final Color bg;
    final Color fg;
    if (state == _OptionState.correct) {
      border = Colors.green.withValues(alpha: 0.45);
      bg = Colors.green.withValues(alpha: 0.12);
      fg = scheme.onSurface;
    } else if (state == _OptionState.wrong) {
      border = scheme.error.withValues(alpha: 0.45);
      bg = scheme.error.withValues(alpha: 0.10);
      fg = scheme.onSurface;
    } else if (selected) {
      border = scheme.primary.withValues(alpha: 0.45);
      bg = scheme.primary.withValues(alpha: 0.10);
      fg = scheme.onSurface;
    } else {
      border = scheme.outline.withValues(alpha: 0.16);
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: border)),
        child: Row(
          children: [
            Icon(selected ? PhosphorIcons.radioButton() : PhosphorIcons.circle(), size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: fg, height: 1.25))),
          ],
        ),
      ),
    );
  }
}

class _IdQuizSheet extends StatefulWidget {
  const _IdQuizSheet({required this.courseId, required this.items});
  final String courseId;
  final List<Map<String, Object>> items;

  @override
  State<_IdQuizSheet> createState() => _IdQuizSheetState();
}

class _IdQuizSheetState extends State<_IdQuizSheet> {
  int _index = 0;
  int _correct = 0;
  final _answer = TextEditingController();
  bool _checked = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final item = widget.items[_index];
    final prompt = item['prompt'] as String;
    final expected = item['answer'] as String;
    final progress = '${_index + 1}/${widget.items.length}';

    final normalizedUser = _answer.text.trim().toLowerCase();
    final normalizedExpected = expected.trim().toLowerCase();
    final isCorrect = normalizedUser.isNotEmpty && (normalizedUser == normalizedExpected || normalizedExpected.contains(normalizedUser));

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: scheme.outline.withValues(alpha: 0.18))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Quick ID • $progress', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => context.pop(), icon: Icon(PhosphorIcons.x(), color: scheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Text(prompt, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
              controller: _answer,
              onChanged: (_) {
                if (_checked) setState(() => _checked = false);
              },
              decoration: const InputDecoration(labelText: 'Your answer'),
            ),
            if (_checked) ...[
              const SizedBox(height: 10),
              Card(
                color: (isCorrect ? Colors.green : scheme.error).withValues(alpha: 0.10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(isCorrect ? PhosphorIcons.checkCircle() : PhosphorIcons.warningCircle(), color: isCorrect ? Colors.green : scheme.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isCorrect ? 'Correct' : 'Expected: $expected',
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface, height: 1.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_checked) return;
                      setState(() {
                        _checked = true;
                        if (isCorrect) _correct++;
                      });
                    },
                    icon: Icon(PhosphorIcons.check()),
                    label: const Text('Check'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !_checked
                        ? null
                        : () async {
                            final last = _index == widget.items.length - 1;
                            if (last) {
                              await context.read<StudyService>().recordAttempt(courseId: widget.courseId, total: widget.items.length, correct: _correct);
                              if (context.mounted) context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved result: $_correct/${widget.items.length}')));
                              return;
                            }
                            setState(() {
                              _index++;
                              _checked = false;
                              _answer.clear();
                            });
                          },
                    icon: Icon(PhosphorIcons.arrowRight()),
                    label: Text(_index == widget.items.length - 1 ? 'Finish' : 'Next'),
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
