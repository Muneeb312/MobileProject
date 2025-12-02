import 'package:flutter/material.dart';
import '../widgets/help_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'WORDLE CLONE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.videogame_asset),
                label: const Text('Wordle'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(220, 50)),
                onPressed: () => Navigator.pushNamed(context, '/game'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.man),
                label: const Text('Hangman'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(220, 50)),
                onPressed: () => Navigator.pushNamed(context, '/hangman'),
              ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.abc),
            label: const Text('Crossword'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(220, 50)),
            onPressed: () {
              Navigator.pushNamed(context, '/crossword');   // 👈 navigate to crossword
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.grid_4x4),
            label: const Text('Sudoku'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(220, 50)),
            onPressed: () {
              Navigator.pushNamed(context, '/sudoku');      // 👈 navigate to sudoku
            },
          ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (c) => buildHowToPlaySheet(c),
                    isScrollControlled: false,
                  );
                },
                child: const Text('How to Play'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: const Text('Settings & Reminders'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () => Navigator.pushNamed(context, '/'), icon: const Icon(Icons.home)),
            IconButton(onPressed: () => Navigator.pushNamed(context, '/game'), icon: const Icon(Icons.videogame_asset)),
            IconButton(onPressed: () => Navigator.pushNamed(context, '/stats'), icon: const Icon(Icons.bar_chart)),
            IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings)),
          ],
        ),
      ),
    );
  }
}
