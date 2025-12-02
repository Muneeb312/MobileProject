import 'package:flutter/material.dart';

// ------------------------------------------------------------
// HOW TO PLAY BOTTOM SHEET
// ------------------------------------------------------------
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

        // Wordle
        const ListTile(
          title: Text('Wordle'),
          subtitle: Text(
            'Guess the secret 5-letter word in 6 tries.\n'
                '- Green = correct letter & correct spot\n'
                '- Yellow = correct letter, wrong spot\n'
                '- Grey = letter not in the word',
          ),
        ),

        // Hangman
        const ListTile(
          title: Text('Hangman'),
          subtitle: Text(
            'Guess letters to reveal the word.\n'
                'You lose after 6 wrong guesses.',
          ),
        ),

        // Duordle
        const ListTile(
          title: Text('Duordle'),
          subtitle: Text(
            'Guess one 5-letter word each turn.\n'
                'Your guess applies to BOTH boards.\n'
                'Solve both words within 6 guesses.',
          ),
        ),

        // Sudoku
        const ListTile(
          title: Text('Sudoku'),
          subtitle: Text(
            'Fill the 9×9 grid so every row, column,\n'
                'and 3×3 box contains the digits 1–9.\n'
                'Random button generates a new puzzle.',
          ),
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
