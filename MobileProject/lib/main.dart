import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/hangman_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'screens/crossword_screen.dart';
import 'screens/sudoku_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Extra guard: don't init notifications on macOS
  if (!Platform.isMacOS) {
    await NotificationService().init();
  }

  runApp(const WordleApp());
}

class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/game': (_) => const GameScreen(),
        '/hangman': (_) => const HangmanScreen(),
        '/stats': (_) => const StatsScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/crossword': (_) => const CrosswordScreen(),
        '/sudoku': (_) => const SudokuScreen(),
      },
    );
  }
}
