import 'package:flutter/material.dart';

/// The currently selected theme name ('sakura', 'midnight', ...).
/// [MeScreen] updates this and persists the choice to `profiles.theme`.
final ValueNotifier<String> themeNotifier = ValueNotifier<String>('sakura');

class HerDayThemeOption {
  final String name;
  final String label;
  final Color seed;
  final bool dark;
  const HerDayThemeOption(this.name, this.label, this.seed, this.dark);
}

class HerDayThemes {
  static const List<HerDayThemeOption> options = [
    HerDayThemeOption('sakura', '🌸 Sakura', Color(0xFFEC6A9C), false),
    HerDayThemeOption('midnight', '🌙 Midnight', Color(0xFF7C6BD9), true),
    HerDayThemeOption('strawberry', '🍓 Strawberry', Color(0xFFE5484D), false),
    HerDayThemeOption('ocean', '🌊 Ocean', Color(0xFF2E8BC7), false),
    HerDayThemeOption('nature', '🌿 Nature', Color(0xFF4C9A6C), false),
    HerDayThemeOption('minimal', '🖤 Minimal', Color(0xFF4A4A52), false),
  ];

  static HerDayThemeOption byName(String name) {
    for (final o in options) {
      if (o.name == name) return o;
    }
    return options.first;
  }

  static ThemeData build(String name) {
    final opt = byName(name);
    final scheme = ColorScheme.fromSeed(
      seedColor: opt.seed,
      brightness: opt.dark ? Brightness.dark : Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
