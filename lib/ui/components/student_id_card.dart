import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/student_id/student_id_service.dart';
import 'package:study_flow/theme.dart';

// ─── Public entry-point widget ────────────────────────────────────────────────

class StudentIdCard extends StatelessWidget {
  const StudentIdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentIdService>(
      builder: (context, svc, _) => _StudentIdCardView(svc: svc),
    );
  }
}

// ─── Card view ────────────────────────────────────────────────────────────────

class _StudentIdCardView extends StatefulWidget {
  const _StudentIdCardView({required this.svc});
  final StudentIdService svc;

  @override
  State<_StudentIdCardView> createState() => _StudentIdCardViewState();
}

class _StudentIdCardViewState extends State<_StudentIdCardView> {
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  bool _isHovering = false;

  StudentIdService get svc => widget.svc;

  void _onPointerMove(PointerEvent event, Size size) {
    final x = event.localPosition.dx;
    final y = event.localPosition.dy;
    
    // Calculate rotation based on pointer position (-1 to 1 range)
    final rotateY = ((x / size.width) - 0.5) * 0.5; // Left/Right tilt
    final rotateX = ((y / size.height) - 0.5) * -0.5; // Up/Down tilt (inverted)
    
    setState(() {
      _rotateX = rotateX;
      _rotateY = rotateY;
    });
  }

  void _onPointerEnter() {
    setState(() => _isHovering = true);
  }

  void _onPointerExit() {
    setState(() {
      _isHovering = false;
      _rotateX = 0.0;
      _rotateY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve background
    Widget background;
    if (svc.bgMode == 'image' && svc.bgImageBase64 != null) {
      final bytes = base64Decode(svc.bgImageBase64!);
      background = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    } else {
      background = Container(
        decoration: BoxDecoration(
          color: svc.bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );
    }

    // Card text color based on background brightness
    final bgLuminance = svc.bgColor.computeLuminance();
    final cardFg = (svc.bgMode == 'image' || bgLuminance < 0.4) ? Colors.white : Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) => _onPointerEnter(),
          onExit: (_) => _onPointerExit(),
          onHover: (event) => _onPointerMove(event, constraints.biggest),
          child: GestureDetector(
            onLongPress: () => _openCustomize(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(_rotateX)
                ..rotateY(_rotateY),
              transformAlignment: Alignment.center,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                      blurRadius: _isHovering ? 30 : 20,
                      offset: Offset(
                        _rotateY * 20, // shadow follows tilt
                        6 + (_rotateX * 10),
                      ),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Stack(
                    children: [
                      // Background layer
                      Positioned.fill(child: background),

                      // Overlay for readability when using image bg
                      if (svc.bgMode == 'image' && svc.bgImageBase64 != null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.18), Colors.black.withValues(alpha: 0.04)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),

                      // Card content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: photo + barcode
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _PhotoBox(photoBase64: svc.photoBase64, fg: cardFg),
                                _Barcode(fg: cardFg),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Right: header + fields
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo / Title row
                                  _LogoWidget(
                                    logoMode: svc.logoMode,
                                    logoAssetPath: svc.logoAssetPath,
                                    logoBase64: svc.logoBase64,
                                    cardFg: cardFg,
                                  ),
                                  // Dashed divider
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    child: _DashedLine(color: cardFg.withValues(alpha: 0.35)),
                                  ),
                                  // Fields grid
                                  Row(
                                    children: [
                                      Expanded(child: _IdField(label: 'NAME', value: svc.name, fg: cardFg)),
                                      Expanded(child: _IdField(label: 'BIRTHDAY', value: svc.birthday, fg: cardFg)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _IdField(label: 'SCHOOL', value: svc.school, fg: cardFg)),
                                      Expanded(child: _IdField(label: 'YEAR LEVEL', value: svc.yearLevel, fg: cardFg)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCustomize(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CustomizeSheet(),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.photoBase64, required this.fg});
  final String? photoBase64;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;
    if (photoBase64 != null) {
      final bytes = base64Decode(photoBase64!);
      child = Image.memory(bytes, fit: BoxFit.cover);
    } else {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.user(), color: fg.withValues(alpha: 0.4), size: 28),
          const SizedBox(height: 4),
          Text('No Photo', style: TextStyle(color: fg.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Container(
      width: 88,
      height: 110,
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: fg.withValues(alpha: 0.20), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

class _Barcode extends StatelessWidget {
  const _Barcode({required this.fg});
  final Color fg;

  @override
  Widget build(BuildContext context) {
    // Minimal decorative barcode using thin/thick alternating lines
    return SizedBox(
      width: 88,
      height: 22,
      child: CustomPaint(painter: _BarcodePainter(fg)),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.color);
  final Color color;

  static const _pattern = [2, 1, 3, 1, 2, 1, 1, 3, 1, 2, 1, 1, 3, 1, 2, 1, 1, 2, 3, 1, 1, 2, 1, 3, 1, 2, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final total = _pattern.fold<int>(0, (a, b) => a + b).toDouble();
    double x = 0;
    bool fill = true;
    for (final w in _pattern) {
      final barW = (w / total) * size.width;
      if (fill) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barW - 0.5, size.height), paint);
      }
      x += barW;
      fill = !fill;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.color != color;
}

class _IdField extends StatelessWidget {
  const _IdField({required this.label, required this.value, required this.fg});
  final String label;
  final String value;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: fg.withValues(alpha: 0.55), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: cardFg, fontSize: 11, fontWeight: FontWeight.w900, height: 1.15),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color get cardFg => fg;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashPainter(color)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ─── Logo Widget ──────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  const _LogoWidget({
    required this.logoMode,
    required this.logoAssetPath,
    required this.logoBase64,
    required this.cardFg,
  });

  final String logoMode;
  final String? logoAssetPath;
  final String? logoBase64;
  final Color cardFg;

  @override
  Widget build(BuildContext context) {
    // Custom uploaded logo - big header style
    if (logoMode == 'custom' && logoBase64 != null) {
      final bytes = base64Decode(logoBase64!);
      return SizedBox(
        height: 70,
        width: double.infinity,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }

    // Premade asset logo - big header style
    if (logoMode == 'asset' && logoAssetPath != null) {
      return SizedBox(
        height: 70,
        width: double.infinity,
        child: Image.asset(logoAssetPath!, fit: BoxFit.contain),
      );
    }

    // Default text - bigger header style
    return Text(
      'Student ID',
      style: TextStyle(
        fontFamily: 'CrimsonText',
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        fontSize: 28,
        color: cardFg,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ─── Customize Sheet ──────────────────────────────────────────────────────────

class _CustomizeSheet extends StatefulWidget {
  const _CustomizeSheet();

  @override
  State<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends State<_CustomizeSheet> {
  late TextEditingController _name;
  late TextEditingController _birthday;
  late TextEditingController _school;
  late TextEditingController _yearLevel;

  late String _bgMode;
  late Color _bgColor;
  String? _photoBase64;
  String? _bgImageBase64;
  bool _saving = false;

  // Logo state
  late String _logoMode;
  String? _logoAssetPath;
  String? _logoBase64;

  static const _presets = [
    Color(0xFFFFFFFF),
    Color(0xFFE8EEF7),
    Color(0xFFE8E8F7),
    Color(0xFFF7E8EE),
    Color(0xFFFFF8E1),
    Color(0xFFE8F7EE),
  ];

  @override
  void initState() {
    super.initState();
    final svc = context.read<StudentIdService>();
    _name = TextEditingController(text: svc.name);
    _birthday = TextEditingController(text: svc.birthday);
    _school = TextEditingController(text: svc.school);
    _yearLevel = TextEditingController(text: svc.yearLevel);
    _bgMode = svc.bgMode;
    _bgColor = svc.bgColor;
    _photoBase64 = svc.photoBase64;
    _bgImageBase64 = svc.bgImageBase64;
    _logoMode = svc.logoMode;
    _logoAssetPath = svc.logoAssetPath;
    _logoBase64 = svc.logoBase64;
  }

  @override
  void dispose() {
    _name.dispose();
    _birthday.dispose();
    _school.dispose();
    _yearLevel.dispose();
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
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Expanded(
                        child: Text('Customize Student ID',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(PhosphorIcons.x(), color: scheme.onSurface),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    // ── Text fields ──────────────────────────────────────────
                    _SheetLabel('Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(hintText: 'YOUR NAME'),
                    ),
                    const SizedBox(height: 14),

                    _SheetLabel('Birthday'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _birthday,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(hintText: 'DD-MM-YYYY'),
                    ),
                    const SizedBox(height: 14),

                    _SheetLabel('School / Course'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _school,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'YOUR SCHOOL'),
                    ),
                    const SizedBox(height: 14),

                    _SheetLabel('Year Level'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _yearLevel,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '1'),
                    ),
                    const SizedBox(height: 20),

                    // ── Profile image ─────────────────────────────────────────
                    _SheetLabel('Profile Image'),
                    const SizedBox(height: 8),
                    _PhotoUploadButton(
                      hasPhoto: _photoBase64 != null,
                      onPickImage: _pickPhoto,
                      onClear: () => setState(() => _photoBase64 = null),
                    ),
                    const SizedBox(height: 20),

                    // ── Logo ──────────────────────────────────────────────────
                    _SheetLabel('Logo'),
                    const SizedBox(height: 8),

                    // Logo grid: Upload + Premade logos
                    _LogoGrid(
                      selectedMode: _logoMode,
                      selectedAsset: _logoAssetPath,
                      customLogoBase64: _logoBase64,
                      onSelectText: () => setState(() {
                        _logoMode = 'text';
                        _logoAssetPath = null;
                        _logoBase64 = null;
                      }),
                      onSelectAsset: (path) => setState(() {
                        _logoMode = 'asset';
                        _logoAssetPath = path;
                        _logoBase64 = null;
                      }),
                      onUploadCustom: _pickLogo,
                      onClearCustom: () => setState(() => _logoBase64 = null),
                    ),
                    const SizedBox(height: 20),

                    // ── Background ────────────────────────────────────────────
                    _SheetLabel('Background'),
                    const SizedBox(height: 10),

                    // Mode toggle
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Row(children: [
                        _ModeTab(
                          label: 'Color',
                          selected: _bgMode == 'color',
                          onTap: () => setState(() => _bgMode = 'color'),
                        ),
                        _ModeTab(
                          label: 'Image',
                          selected: _bgMode == 'image',
                          onTap: () => setState(() => _bgMode = 'image'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    if (_bgMode == 'color') ...[
                      // Color preview
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selected Color',
                                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                            Text(
                              '#${_bgColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text('Quick Presets',
                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Row(
                        children: _presets.map((c) {
                          final selected = _bgColor.value == c.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _bgColor = c),
                              child: AnimatedContainer(
                                duration: AppTokens.motionFast,
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.3),
                                    width: selected ? 2.5 : 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      // RGB sliders for custom color
                      _ColorSlider(label: 'R', value: _bgColor.red.toDouble(), active: Colors.red,
                          onChanged: (v) => setState(() => _bgColor = _bgColor.withRed(v.round()))),
                      _ColorSlider(label: 'G', value: _bgColor.green.toDouble(), active: Colors.green,
                          onChanged: (v) => setState(() => _bgColor = _bgColor.withGreen(v.round()))),
                      _ColorSlider(label: 'B', value: _bgColor.blue.toDouble(), active: Colors.blue,
                          onChanged: (v) => setState(() => _bgColor = _bgColor.withBlue(v.round()))),
                    ] else ...[
                      // Image background picker
                      _PhotoUploadButton(
                        hasPhoto: _bgImageBase64 != null,
                        label: _bgImageBase64 != null ? 'Change Background Image' : 'Upload Background Image',
                        onPickImage: _pickBgImage,
                        onClear: () => setState(() => _bgImageBase64 = null),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(PhosphorIcons.floppyDisk()),
                        label: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image picking using file_picker ──

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      final bytes = result.files.first.bytes!;
      final base64 = base64Encode(bytes);
      setState(() => _photoBase64 = base64);
    }
  }

  Future<void> _pickBgImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      final bytes = result.files.first.bytes!;
      final base64 = base64Encode(bytes);
      setState(() => _bgImageBase64 = base64);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      final bytes = result.files.first.bytes!;
      final base64 = base64Encode(bytes);
      setState(() => _logoBase64 = base64);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<StudentIdService>().update(
        name: _name.text,
        birthday: _birthday.text,
        school: _school.text,
        yearLevel: _yearLevel.text,
        photoBase64: _photoBase64,
        clearPhoto: _photoBase64 == null,
        bgMode: _bgMode,
        bgColor: _bgMode == 'color' ? _bgColor : null,
        bgImageBase64: _bgImageBase64,
        clearBgImage: _bgImageBase64 == null,
        logoMode: _logoMode,
        logoAssetPath: _logoAssetPath,
        logoBase64: _logoBase64,
        clearLogo: _logoMode == 'text',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(PhosphorIcons.check(), color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Student ID updated!'),
            ]),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Logo Grid Widget ─────────────────────────────────────────────────────────

class _LogoGrid extends StatelessWidget {
  const _LogoGrid({
    required this.selectedMode,
    required this.selectedAsset,
    required this.customLogoBase64,
    required this.onSelectText,
    required this.onSelectAsset,
    required this.onUploadCustom,
    required this.onClearCustom,
  });

  final String selectedMode;
  final String? selectedAsset;
  final String? customLogoBase64;
  final VoidCallback onSelectText;
  final ValueChanged<String> onSelectAsset;
  final VoidCallback onUploadCustom;
  final VoidCallback onClearCustom;

  // Define your premade logo assets here
  static const _premadeLogos = [
    'assets/logos/FURIA_logo.png',
    'assets/logos/CCS_logo.png',
    'assets/logos/ROSE_logo.png',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCustomLogo = customLogoBase64 != null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        // Upload custom logo option
        _LogoOption(
          isSelected: selectedMode == 'custom' && hasCustomLogo,
          onTap: hasCustomLogo 
              ? () {
                  // If already has custom logo, selecting it just sets mode
                  if (selectedMode != 'custom') {
                    onUploadCustom();
                  }
                }
              : onUploadCustom,
          child: hasCustomLogo && selectedMode == 'custom'
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.memory(
                    base64Decode(customLogoBase64!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _UploadPlaceholder(),
                  ),
                )
              : _UploadPlaceholder(),
        ),

        // Text option (Student ID)
        _LogoOption(
          isSelected: selectedMode == 'text',
          onTap: onSelectText,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Student ID',
              style: TextStyle(
                fontFamily: 'CrimsonText',
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                fontSize: 20,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),

        // Premade logo assets
        for (final logoPath in _premadeLogos)
          _LogoOption(
            isSelected: selectedMode == 'asset' && selectedAsset == logoPath,
            onTap: () => onSelectAsset(logoPath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                logoPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: scheme.surfaceContainerHighest,
                  child: Center(
                    child: Text(
                      logoPath.split('/').last.replaceAll('.png', ''),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(PhosphorIcons.upload(), size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          'Upload a custom logo',
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LogoOption extends StatelessWidget {
  const _LogoOption({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Sheet helpers ─────────────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTokens.motionFast,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoUploadButton extends StatelessWidget {
  const _PhotoUploadButton({
    required this.hasPhoto,
    required this.onPickImage,
    required this.onClear,
    this.label = 'Upload Photo',
  });
  final bool hasPhoto;
  final String label;
  final VoidCallback onPickImage;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onPickImage,
          icon: Icon(PhosphorIcons.upload(), size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF82),
            side: const BorderSide(color: Color(0xFF4CAF82), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          ),
        ),
      ),
      if (hasPhoto) ...[
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Remove',
          onPressed: onClear,
          icon: Icon(PhosphorIcons.trash(), color: scheme.error),
        ),
      ],
    ]);
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
    return Row(children: [
      SizedBox(
        width: 16,
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: active, thumbColor: active),
          child: Slider(min: 0, max: 255, value: value, onChanged: onChanged),
        ),
      ),
      SizedBox(
        width: 32,
        child: Text(value.round().toString(),
            style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.right),
      ),
    ]);
  }
}

/// Temporary dialog — replace with image_picker in production.
class _Base64InputDialog extends StatefulWidget {
  const _Base64InputDialog({required this.title});
  final String title;

  @override
  State<_Base64InputDialog> createState() => _Base64InputDialogState();
}

class _Base64InputDialogState extends State<_Base64InputDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        maxLines: 4,
        decoration: const InputDecoration(hintText: 'Paste base64 image string…'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}