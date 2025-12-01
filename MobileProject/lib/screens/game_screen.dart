import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

// ------------------------------------------------------------
// WORDLE LOGIC
// ------------------------------------------------------------

enum LetterState { correct, present, absent }

class LetterMark {
  final String char;
  final LetterState state;
  const LetterMark(this.char, this.state);
}

List<LetterMark> scoreGuess(String guess, String answer) {
  guess = guess.toUpperCase();
  answer = answer.toUpperCase();
  final res = List<LetterMark>.filled(5, const LetterMark('', LetterState.absent), growable: false);
  final answerChars = answer.split('');
  final used = List<bool>.filled(5, false);

  // Greens
  for (int i = 0; i < 5; i++) {
    if (guess[i] == answer[i]) {
      res[i] = LetterMark(guess[i], LetterState.correct);
      used[i] = true;
    }
  }

  // Yellows / Greys
  for (int i = 0; i < 5; i++) {
    if (res[i].state == LetterState.correct) continue;
    final g = guess[i];
    int idx = -1;

    for (int j = 0; j < 5; j++) {
      if (!used[j] && answerChars[j] == g) {
        idx = j;
        break;
      }
    }

    if (idx != -1) {
      used[idx] = true;
      res[i] = LetterMark(g, LetterState.present);
    } else {
      res[i] = LetterMark(g, LetterState.absent);
    }
  }
  return res;
}

Future<List<String>> loadWordList() async {
  final raw = await rootBundle.loadString('assets/words.txt');
  return raw
      .split(RegExp(r'[\s,]+'))
      .map((w) => w.trim().toUpperCase())
      .where((w) => w.isNotEmpty)
      .toList();
}

String getRandomWord(List<String> words) {
  final r = Random();
  return words[r.nextInt(words.length)];
}

// ------------------------------------------------------------
// WORDLE GAME SCREEN
// ------------------------------------------------------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _word = '';
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<String> _guesses = [];
  List<List<LetterMark>> _marks = [];
  Map<String, LetterState> _kb = {};

  List<String> _words = [];
  Set<String> _valid = {};

  late SharedPreferences _prefs;
  int _wins = 0, _losses = 0, _streak = 0, _maxStreak = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  void _loadGameData() async {
    final words = await loadWordList();
    if (!mounted) return;

    setState(() {
      _words = words;
      _valid = {...words};
      _word = getRandomWord(_words);
    });

    _loadStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _wins = _prefs.getInt('wins') ?? 0;
      _losses = _prefs.getInt('losses') ?? 0;
      _streak = _prefs.getInt('streak') ?? 0;
      _maxStreak = _prefs.getInt('maxStreak') ?? 0;
    });
  }

  Future<void> _saveStats() async {
    await _prefs.setInt('wins', _wins);
    await _prefs.setInt('losses', _losses);
    await _prefs.setInt('streak', _streak);
    await _prefs.setInt('maxStreak', _maxStreak);
  }

  void _newGame() {
    setState(() {
      String next = getRandomWord(_words);
      if (_words.length > 1) {
        while (next == _word) {
          next = getRandomWord(_words);
        }
      }
      _word = next;

      _guesses = [];
      _marks = [];
      _kb = {};
      _gameOver = false;
      _controller.clear();
    });
  }

  void _updateKeyboard(List<LetterMark> marks) {
    int p(LetterState s) {
      if (s == LetterState.correct) return 3;
      if (s == LetterState.present) return 2;
      return 1;
    }

    for (final m in marks) {
      final prev = _kb[m.char];
      if (prev == null || p(m.state) > p(prev)) {
        _kb[m.char] = m.state;
      }
    }
  }

  void _endGame({required bool won}) async {
    if (_gameOver) return;

    _gameOver = true;
    if (won) {
      _wins++;
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;
    } else {
      _losses++;
      _streak = 0;
    }

    await _saveStats();
    _showEndDialog(won ? "You won!" : "Try again!");
  }

  void _submitGuess() {
    final g = _controller.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{5}$').hasMatch(g)) {
      _toast("Enter 5 letters");
      return;
    }
    if (_guesses.contains(g)) {
      _toast("Already guessed");
      return;
    }
    if (_valid.isNotEmpty && !_valid.contains(g)) {
      _toast("Not in word list");
      return;
    }

    final marks = scoreGuess(g, _word);

    setState(() {
      _guesses.add(g);
      _marks.add(marks);
      _updateKeyboard(marks);
    });

    if (g == _word) {
      _endGame(won: true);
    } else if (_guesses.length >= 6) {
      _endGame(won: false);
    }

    _controller.clear();
    _focus.requestFocus();
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _tileColor(LetterState s) {
    switch (s) {
      case LetterState.correct:
        return Colors.green.shade600;
      case LetterState.present:
        return Colors.amber.shade700;
      case LetterState.absent:
        return Colors.grey.shade600;
    }
  }

  Widget _tile(String ch, LetterState s) {
    final isEmpty = ch.isEmpty && s == LetterState.absent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 54,
      height: 54,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.transparent : _tileColor(s),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: Text(
        ch,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _board() {
    List<Widget> buildRow(int r) {
      if (r < _marks.length) {
        return _marks[r].map((m) => _tile(m.char, m.state)).toList();
      }

      if (r == _marks.length && _guesses.length < 6) {
        final txt = _controller.text.toUpperCase();
        return List.generate(5, (i) {
          return _tile(i < txt.length ? txt[i] : "", LetterState.absent);
        });
      }

      return List.generate(5, (_) => _tile("", LetterState.absent));
    }

    return Column(
      children: List.generate(
        6,
            (r) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildRow(r),
        ),
      ),
    );
  }

  Widget _keyboard() {
    const rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];

    Color keyColor(LetterState? s) {
      if (s == null) return Colors.grey.shade300;
      if (s == LetterState.correct) return Colors.green.shade600;
      if (s == LetterState.present) return Colors.amber.shade700;
      return Colors.grey.shade600;
    }

    Widget key(String ch) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          onTap: _gameOver || _controller.text.length >= 5
              ? null
              : () {
            _controller.text += ch;
            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
            setState(() {});
          },
          child: Container(
            width: 34,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: keyColor(_kb[ch]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(ch, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.split("").map(key).toList(),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: !_gameOver && _controller.text.length == 5 ? _submitGuess : null,
              child: const Text("ENTER"),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _controller.text.isEmpty
                  ? null
                  : () {
                _controller.text =
                    _controller.text.substring(0, _controller.text.length - 1);
                _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                setState(() {});
              },
              child: const Text("DEL"),
            ),
          ],
        )
      ],
    );
  }

  // ------------------------------------------------------------
  // END OF GAME DIALOG
  // ------------------------------------------------------------
  void _showEndDialog(String message) {
    final won = _guesses.isNotEmpty && _guesses.last == _word;

    String emojiGrid() {
      final b = StringBuffer();
      for (final row in _marks) {
        for (final m in row) {
          if (m.state == LetterState.correct) b.write("🟩");
          else if (m.state == LetterState.present) b.write("🟨");
          else b.write("⬛");
        }
        b.writeln();
      }
      return b.toString();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(message),
        content: !won ? Text("Answer: $_word") : null,
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: emojiGrid()));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Result copied!")),
                );
              }
            },
            child: const Text("Share"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _newGame();
            },
            child: const Text("Play Again"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final guessesLeft = 6 - _guesses.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Wordle · $guessesLeft guesses"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                _board(),
                const SizedBox(height: 16),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    maxLength: 5,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Enter your guess",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _controller.text.length == 5 && !_gameOver
                            ? _submitGuess
                            : null,
                      ),
                    ),
                    onSubmitted: (_) => _submitGuess(),
                  ),
                ),

                const SizedBox(height: 8),
                _keyboard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
