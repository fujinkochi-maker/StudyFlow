import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

/// Small design tokens used across the app.
class AppTokens {
  static const double cardBorderOpacity = 0.14;
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionMedium = Duration(milliseconds: 260);
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

/// A theme preset (palette) selectable by the user.
class AppThemePreset {
  const AppThemePreset({required this.id, required this.name, required this.seed, required this.preview});
  final String id;
  final String name;
  final Color seed;
  final List<Color> preview;
}

/// User-requested theme presets (based on the provided palette images).
class AppThemePresets {
  static const AppThemePreset jadePebble = AppThemePreset(
    id: 'default',
    name: 'Default',
    seed: Color(0xFF6C8480),
    preview: [Color(0xFF7B9669), Color(0xFFE6E6E6), Color(0xFF404E3B)],
  );

  static const AppThemePreset sorbet = AppThemePreset(
    id: 'sorbet',
    name: 'Sorbet',
    seed: Color(0xFFB7C396),
    preview: [Color(0xFFCCCCCC), Color(0xFFE0E7D7), Color(0xFFBA9A91)],
  );

  static const AppThemePreset garnet = AppThemePreset(
    id: 'garnet',
    name: 'Garnet',
    seed: Color(0xFF30525C),
    preview: [Color(0xFFF6C992), Color(0xFF30525C), Color(0xFF09A1A1)],
  );

  static const List<AppThemePreset> all = [jadePebble, sorbet, garnet];

  static AppThemePreset byId(String id) => all.firstWhere((p) => p.id == id, orElse: () => jadePebble);
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// =============================================================================
// THEMES
// =============================================================================

ThemeData buildAppTheme({required Brightness brightness, required Color seedColor}) {
  final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  final isDark = brightness == Brightness.dark;
  final background = isDark ? const Color(0xFF0E1116) : const Color(0xFFF7F8FA);
  final surface = isDark ? const Color(0xFF121722) : const Color(0xFFFFFFFF);
  final surfaceVariant = isDark ? const Color(0xFF1A2233) : const Color(0xFFF0F2F6);

  final tuned = scheme.copyWith(
    surface: surface,
    surfaceContainerHighest: surfaceVariant,
    outline: isDark ? const Color(0xFF3A465E) : const Color(0xFFD5DAE6),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: tuned,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: tuned.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.crimsonText(
        fontSize: FontSizes.titleLarge,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: tuned.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tuned.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: tuned.outline.withValues(alpha: AppTokens.cardBorderOpacity), width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tuned.surface,
      indicatorColor: tuned.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(_buildTextTheme(brightness).labelSmall),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tuned.primary,
      foregroundColor: tuned.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tuned.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: tuned.primary.withValues(alpha: 0.55), width: 1.2),
      ),
    ),
    textTheme: _buildTextTheme(brightness),
  );
}

/// Build text theme using Montserrat for headers and Roboto Mono for body
TextTheme _buildTextTheme(Brightness brightness) {
  // Headers use Montserrat (clean, geometric, modern)
  final headerStyle = GoogleFonts.montserrat;
  // Body text uses Roboto Mono (monospace, readable)
  final bodyStyle = GoogleFonts.robotoMono;

  return TextTheme(
    // Display & Headlines - Montserrat
    displayLarge: headerStyle(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    displayMedium: headerStyle(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: headerStyle(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: headerStyle(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: headerStyle(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: headerStyle(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    // Titles - Montserrat
    titleLarge: headerStyle(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: headerStyle(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: headerStyle(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w600,
    ),
    // Labels - Montserrat
    labelLarge: headerStyle(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: headerStyle(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: headerStyle(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    // Body - Roboto Mono
    bodyLarge: bodyStyle(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: bodyStyle(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: bodyStyle(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
  );
}
