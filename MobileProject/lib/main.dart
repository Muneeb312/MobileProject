// ------------------------------------------------------------
// FILE: main.dart
// PURPOSE:
//   Application entry point. Sets up app initialization,
//   notification service (platform-dependent), and global routes
//   for all screens.
//
// NOTE:
//   NotificationService is not initialized on macOS, because it
//   requires platform-specific configuration not supported there.
// ------------------------------------------------------------

import 'dart:io' show Platform;
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/hangman_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/duordle_screen.dart';
import 'screens/sudoku_screen.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const WordleApp());

  // Initialize notifications on supported platforms only.
  if (!Platform.isMacOS) {
    await NotificationService().init();
  }
}

// ------------------------------------------------------------
// APP ROOT WIDGET
// ------------------------------------------------------------

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
        '/duordle': (_) => const DuordleScreen(),
        '/sudoku': (_) => const SudokuScreen(),
      },
    );
  }
}
