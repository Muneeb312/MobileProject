// ------------------------------------------------------------
// FILE: duordle_screen.dart
// PURPOSE:
//   Implements a "Duordle" game mode: two Wordle-style boards
//   played in parallel. A single guess is applied to both target
//   words, with separate boards and evaluations.
//
// DEPENDS ON:
//   game_screen.dart for LetterState, LetterMark, scoreGuess,
//   loadWordList, fetchRandomWordFromApi, and getRandomWord.
// ------------------------------------------------------------

import 'package:flutter/material.dart';

// Reuse Wordle logic and helpers from the main game screen.
import 'game_screen.dart';

class DuordleScreen extends StatefulWidget {
  const DuordleScreen({super.key});

  @override
  State<DuordleScreen> createState() => _DuordleScreenState();
}

class _DuordleScreenState extends State<DuordleScreen> {
  // ------------------------------------------------------------
  // GAME STATE
  // ------------------------------------------------------------

  // Two target words for the left and right boards.
  String _wordLeft = '';
  String _wordRight = '';

  // Shared guess input, separate marks for each board.
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<String> _guesses = [];
  List<List<LetterMark>> _marksLeft = [];
  List<List<LetterMark>> _marksRight = [];
  Map<String, LetterState> _kb = {};

  // Dictionary and validation set.
  List<String> _words = [];
  Set<String> _valid = {};

  // Flags for loading and game status.
  bool _isLoading = true;
  bool _gameOver = false;
  bool _leftSolved = false;
  bool _rightSolved = false;

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // GAME INITIALIZATION / WORD SELECTION
  // ------------------------------------------------------------

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);

    // 1. Load local dictionary.
    final words = await loadWordList();
    _words = words;
    _valid = {...words};

    // 2. Pick two answers, trying HTTP first, then falling back to local.
    final left = await _randomAnswer();
    final right = await _randomAnswer(exclude: left);

    if (!mounted) return;

    setState(() {
      _wordLeft = left;
      _wordRight = right;
      _valid.add(_wordLeft);
      _valid.add(_wordRight);

      _isLoading = false;
      _guesses = [];
      _marksLeft = [];
      _marksRight = [];
      _kb = {};
      _gameOver = false;
      _leftSolved = false;
      _rightSolved = false;
      _controller.clear();
    });
  }

  Future<String> _randomAnswer({String? exclude}) async {
    // Try API first.
    String? apiWord = await fetchRandomWordFromApi();
    String chosen;

    if (apiWord != null &&
        apiWord.length == 5 &&
        RegExp(r'^[A-Z]+$').hasMatch(apiWord)) {
      chosen = apiWord.toUpperCase();
    } else {
      // Fallback to local random word.
      chosen = getRandomWord(_words);
    }

    // Ensure distinct words if an exclude word is provided.
    if (exclude != null && chosen == exclude && _words.length > 1) {
      String alt = getRandomWord(_words);
      int safety = 0;
      while (alt == exclude && safety < 20) {
        alt = getRandomWord(_words);
        safety++;
      }
      chosen = alt;
    }

    _valid.add(chosen);
    return chosen;
  }

  // ------------------------------------------------------------
  // GAME LOGIC
  // ------------------------------------------------------------

  void _updateKeyboard(List<LetterMark> marks) {
    int rank(LetterState s) {
      if (s == LetterState.correct) return 3;
      if (s == LetterState.present) return 2;
      return 1;
    }

    for (final m in marks) {
      final prev = _kb[m.char];
      if (prev == null || rank(m.state) > rank(prev)) {
        _kb[m.char] = m.state;
      }
    }
  }

  void _submitGuess() {
    if (_gameOver) return;

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

    final marksL = scoreGuess(g, _wordLeft);
    final marksR = scoreGuess(g, _wordRight);

    setState(() {
      _guesses.add(g);
      _marksLeft.add(marksL);
      _marksRight.add(marksR);
      _updateKeyboard(marksL);
      _updateKeyboard(marksR);
    });

    if (g == _wordLeft) _leftSolved = true;
    if (g == _wordRight) _rightSolved = true;

    if (_leftSolved && _rightSolved) {
      _endGame(won: true);
    } else if (_guesses.length >= 6) {
      _endGame(won: false);
    }

    _controller.clear();
    _focus.requestFocus();
  }

  void _endGame({required bool won}) {
    if (_gameOver) return;
    _gameOver = true;
    _showEndDialog(won ? "You solved both!" : "Out of guesses!");
  }

  // ------------------------------------------------------------
  // UI HELPERS (TOASTS, TILES, BOARDS, KEYBOARD)
  // ------------------------------------------------------------

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.transparent : _tileColor(s),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: Text(
        ch,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _board(List<List<LetterMark>> marks) {
    List<Widget> buildRow(int r) {
      if (r < marks.length) {
        return marks[r].map((m) => _tile(m.char, m.state)).toList();
      }

      if (r == marks.length && _guesses.length < 6) {
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
        padding: const EdgeInsets.all(3),
        child: InkWell(
          onTap: _gameOver || _controller.text.length >= 5
              ? null
              : () {
            _controller.text += ch;
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
            setState(() {});
          },
          child: Container(
            width: 30,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: keyColor(_kb[ch]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ch,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
              onPressed:
              !_gameOver && _controller.text.length == 5 ? _submitGuess : null,
              child: const Text("ENTER"),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _controller.text.isEmpty
                  ? null
                  : () {
                _controller.text = _controller.text.substring(
                  0,
                  _controller.text.length - 1,
                );
                _controller.selection = TextSelection.collapsed(
                  offset: _controller.text.length,
                );
                setState(() {});
              },
              child: const Text("DEL"),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // END-OF-GAME DIALOG
  // ------------------------------------------------------------

  void _showEndDialog(String message) {
    String emojiBoard(List<List<LetterMark>> marks) {
      final b = StringBuffer();
      for (final row in marks) {
        for (final m in row) {
          if (m.state == LetterState.correct) {
            b.write("🟩");
          } else if (m.state == LetterState.present) {
            b.write("🟨");
          } else {
            b.write("⬛");
          }
        }
        b.writeln();
      }
      return b.toString();
    }

    final gridLeft = emojiBoard(_marksLeft);
    final gridRight = emojiBoard(_marksRight);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(message),
        content: Text(
          "Left:  $_wordLeft\nRight: $_wordRight\n\n"
              "Left board:\n$gridLeft\nRight board:\n$gridRight",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadGameData();
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
        title: Text("Duordle · $guessesLeft guesses"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGameData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                // Two boards side-by-side on wide screens, stacked on narrow.
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Text("Left"),
                              const SizedBox(height: 8),
                              _board(_marksLeft),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            children: [
                              const Text("Right"),
                              const SizedBox(height: 8),
                              _board(_marksRight),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const Text("Left"),
                          const SizedBox(height: 8),
                          _board(_marksLeft),
                          const SizedBox(height: 16),
                          const Text("Right"),
                          const SizedBox(height: 8),
                          _board(_marksRight),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    maxLength: 5,
                    buildCounter: (
                        _,
                        {
                          required int currentLength,
                          required bool isFocused,
                          int? maxLength,
                        }
                        ) =>
                    null,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Enter a guess (applies to both)",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed:
                        _controller.text.length == 5 && !_gameOver
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
