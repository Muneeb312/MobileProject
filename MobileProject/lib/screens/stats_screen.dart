// ------------------------------------------------------------
// FILE: stats_screen.dart
// PURPOSE:
//   Displays Wordle statistics persisted by StorageService,
//   including wins, losses, win rate, current streak, and
//   maximum streak. Allows manual refresh of stored values.
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // ------------------------------------------------------------
  // STATE AND STORAGE
  // ------------------------------------------------------------

  int wins = 0, losses = 0, streak = 0, maxStreak = 0;
  final StorageService storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await storage.init();
    final w = await storage.getInt('wins', 0);
    final l = await storage.getInt('losses', 0);
    final s = await storage.getInt('streak', 0);
    final m = await storage.getInt('maxStreak', 0);
    if (!mounted) return;

    setState(() {
      wins = w;
      losses = l;
      streak = s;
      maxStreak = m;
    });
  }

  double _winRate() =>
      (wins + losses) == 0 ? 0.0 : wins * 100.0 / (wins + losses);

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Wins: $wins', style: const TextStyle(fontSize: 18)),
            Text('Losses: $losses', style: const TextStyle(fontSize: 18)),
            Text(
              'Win Rate: ${_winRate().toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Current Streak: $streak',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Max Streak: $maxStreak',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadStats,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
