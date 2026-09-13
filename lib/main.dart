import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/splash_screen.dart';
import 'providers/theme_provider.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite ffi for desktop (Linux/Windows/macOS)
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: ExpenseDebtApp(),
    ),
  );
}

class ExpenseDebtApp extends ConsumerWidget {
  final Widget? home;
  const ExpenseDebtApp({super.key, this.home});

  static const Color emeraldGreen = AppColors.primaryDark;
  static const Color mintAccent = AppColors.primaryBlue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final lightBaseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.electricCyan,
        surface: AppColors.surfaceLight,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorderLight, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    final darkBaseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.electricCyan,
        secondary: const Color(0xFF60A5FA),
        surface: AppColors.cardSurfaceDark,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF071B2F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorderDark, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return MaterialApp(
      title: 'FirmLedger: Expense & Debt',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightBaseTheme,
      darkTheme: darkBaseTheme,
      home: home ?? const SplashScreen(),
    );
  }
}
