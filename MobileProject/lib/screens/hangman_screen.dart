// ------------------------------------------------------------
// FILE: hangman_screen.dart
// PURPOSE:
//   Implements a simple Hangman game. Loads words from the
//   shared word list, tracks guessed letters, wrong attempts,
//   and displays an on-screen letter grid for input.
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  // ------------------------------------------------------------
  // GAME STATE
  // ------------------------------------------------------------

  late String secretWord;
  List<String> lettersGuessed = [];
  int maxAttempts = 6;
  bool isLoading = true;
  final Random rnd = Random();

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadRandomWord();
  }

  // ------------------------------------------------------------
  // WORD LOADING AND GAME LOGIC
  // ------------------------------------------------------------

  Future<void> _loadRandomWord() async {
    final fileText = await rootBundle.loadString('assets/words.txt');
    final allWords = fileText
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      secretWord = allWords[rnd.nextInt(allWords.length)];
      lettersGuessed.clear();
      isLoading = false;
    });
  }

  void guessLetter(String letter) {
    if (lettersGuessed.contains(letter)) return;

    setState(() => lettersGuessed.add(letter));

    if (isWordGuessed()) {
      _showEndDialog("🎉 You Won!", "The word was: $secretWord");
    } else if (wrongGuesses() >= maxAttempts) {
      _showEndDialog("❌ You Lost!", "The word was: $secretWord");
    }
  }

  int wrongGuesses() =>
      lettersGuessed.where((l) => !secretWord.contains(l)).length;

  bool isWordGuessed() =>
      secretWord.split('').every((c) => lettersGuessed.contains(c));

  // ------------------------------------------------------------
  // END-OF-GAME DIALOG
  // ------------------------------------------------------------

  void _showEndDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isLoading = true;
              });
              _loadRandomWord();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------

  Widget buildLetterButton(String letter) {
    final used = lettersGuessed.contains(letter);
    return Padding(
      padding: const EdgeInsets.all(3),
      child: ElevatedButton(
        onPressed: used ? null : () => guessLetter(letter),
        child: Text(letter),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayWord = secretWord
        .split('')
        .map((c) => lettersGuessed.contains(c) ? c : '_')
        .join(' ');

    return Scaffold(
      appBar: AppBar(title: const Text('Hangman')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Word:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              displayWord,
              style: const TextStyle(fontSize: 32, letterSpacing: 4),
            ),
            const SizedBox(height: 16),
            Text('Wrong guesses: ${wrongGuesses()} / $maxAttempts'),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                    .split('')
                    .map(buildLetterButton)
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
