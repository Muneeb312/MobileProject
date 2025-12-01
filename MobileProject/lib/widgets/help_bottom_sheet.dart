import 'package:flutter/material.dart';

Widget buildHowToPlaySheet(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Wrap(
      children: [
        const ListTile(
          title: Text('How to Play'),
          subtitle: Text('Choose a game and follow the on-screen instructions.'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Wordle'),
          subtitle: const Text('Guess the 5-letter word in 6 tries.'),
        ),
        ListTile(
          title: const Text('Hangman'),
          subtitle: const Text('Guess letters before you reach 6 wrong guesses.'),
        ),
        ListTile(
          title: const Text('Crossword & Sudoku'),
          subtitle: const Text('Placeholders for now — coming soon.'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        )
      ],
    ),
  );
}
