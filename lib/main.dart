import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'l10n/strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  S.setLocale('zh');
  runApp(const KgmConverterApp());
}

class KgmConverterApp extends StatelessWidget {
  const KgmConverterApp({super.key});

  static const _primary = Color(0xFF0D9488);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _primaryContainer = Color(0xFFA7F3D0);
  static const _onPrimaryContainer = Color(0xFF00201B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KGM Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          primary: _primary,
          onPrimary: _onPrimary,
          primaryContainer: _primaryContainer,
          onPrimaryContainer: _onPrimaryContainer,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          primary: _primary,
          onPrimary: _onPrimary,
          primaryContainer: const Color(0xFF005046),
          onPrimaryContainer: const Color(0xFFA7F3D0),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
