import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for Clipboard (Share Result)
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WordleApp());
}

class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordle Clone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

// -------------------- MAIN NAVIGATION WRAPPER --------------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    GameScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Game'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// -------------------- HOME SCREEN --------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'WORDLE!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}

// -------------------- WORDLE CORE --------------------
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

  // First pass: greens
  for (int i = 0; i < 5; i++) {
    final g = guess[i];
    if (g == answer[i]) {
      res[i] = LetterMark(g, LetterState.correct);
      used[i] = true;
    }
  }
  // Second pass: yellows / greys (handles duplicates)
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

// A tiny built-in list. Replace with a larger curated list when ready.
const List<String> _wordList = [
  'APPLE','GRAPE','MANGO','BERRY','LEMON','PEACH','OLIVE','GUAVA','MELON','CHILI',
  'PEARL','COCOA','HONEY','BASIL','MINTY','COAST','RIVER','STONE','CLOUD','STORM',
];
final Set<String> _valid = {..._wordList}; // allow only these for now

String _dailyWord(DateTime now) {
  final start = DateTime(2021, 6, 19);
  final days = now.difference(start).inDays;
  final idx = days % _wordList.length;
  return _wordList[idx];
}

// -------------------- GAME SCREEN --------------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late String _word;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  final List<String> _guesses = [];
  final List<List<LetterMark>> _marks = [];
  final Map<String, LetterState> _kb = {}; // A..Z -> best-known state

  late SharedPreferences _prefs;
  int _wins = 0, _losses = 0, _streak = 0, _maxStreak = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _word = _dailyWord(DateTime.now());
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
      _word = _dailyWord(DateTime.now());
      _guesses.clear();
      _marks.clear();
      _kb.clear();
      _gameOver = false;
      _controller.clear();
    });
  }

  void _updateKeyboard(List<LetterMark> marks) {
    // Prefer best info: correct > present > absent
    int priority(LetterState s) {
      switch (s) {
        case LetterState.correct:
          return 3;
        case LetterState.present:
          return 2;
        case LetterState.absent:
          return 1;
      }
    }

    for (final m in marks) {
      final prev = _kb[m.char];
      if (prev == null || priority(m.state) > priority(prev)) {
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
    _showEndDialog(won ? 'You won!' : 'Try again!');
  }

  void _submitGuess() {
    final raw = _controller.text.trim().toUpperCase();
    final validForm = RegExp(r'^[A-Z]{5}$').hasMatch(raw);
    if (!validForm) {
      _toast('Enter 5 letters');
      return;
    }
    if (_guesses.contains(raw)) {
      _toast('Already guessed');
      return;
    }
    if (!_valid.contains(raw)) {
      _toast('Not in word list');
      return;
    }

    final marks = scoreGuess(raw, _word);
    setState(() {
      _guesses.add(raw);
      _marks.add(marks);
      _updateKeyboard(marks);
    });

    if (raw == _word) {
      _endGame(won: true);
    } else if (_guesses.length >= 6) {
      _endGame(won: false);
    }
    _controller.clear();
    _focus.requestFocus();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- UI helpers ----------
  Color _tileColor(LetterState s, BuildContext c) {
    switch (s) {
      case LetterState.correct:
        return Colors.green.shade600;
      case LetterState.present:
        return Colors.amber.shade700;
      case LetterState.absent:
        return Theme.of(c).colorScheme.surfaceVariant;
    }
  }

  Widget _tile(String ch, LetterState s) {
    final isEmpty = ch.isEmpty && s == LetterState.absent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 54,
      height: 54,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.transparent : _tileColor(s, context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        ch,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5),
      ),
    );
  }

  Widget _board() {
    List<Widget> buildRow(int row) {
      if (row < _marks.length) {
        return _marks[row].map((m) => _tile(m.char, m.state)).toList();
      }
      // current typing row preview
      if (row == _marks.length && _guesses.length < 6) {
        final input = _controller.text.toUpperCase();
        final chars = List<String>.generate(5, (i) => i < input.length ? input[i] : '');
        return chars.map((c) => _tile(c, LetterState.absent)).toList();
      }
      return List.generate(5, (_) => _tile('', LetterState.absent));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
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
      switch (s) {
        case LetterState.correct:
          return Colors.green.shade600;
        case LetterState.present:
          return Colors.amber.shade700;
        case LetterState.absent:
          return Colors.grey.shade500;
      }
    }

    Widget key(String ch) => Padding(
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

    return Column(
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.split('').map(key).toList(),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: !_gameOver && _controller.text.length == 5 ? _submitGuess : null,
              child: const Text('ENTER'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _controller.text.isEmpty
                  ? null
                  : () {
                _controller.text = _controller.text.substring(0, _controller.text.length - 1);
                _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                setState(() {});
              },
              child: const Text('DEL'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- End dialog with Share (date + streak) ----------
  void _showEndDialog(String message) {
    if (!mounted) return;

    String _formatDate(DateTime dt) {
      String two(int n) => n < 10 ? '0$n' : '$n';
      return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
    }

    // Build a Wordle-style emoji summary
    String buildEmojiGrid() {
      final buffer = StringBuffer();
      for (final row in _marks) {
        for (final m in row) {
          switch (m.state) {
            case LetterState.correct:
              buffer.write('🟩');
              break;
            case LetterState.present:
              buffer.write('🟨');
              break;
            case LetterState.absent:
              buffer.write('⬛');
              break;
          }
        }
        buffer.writeln();
      }
      final today = _formatDate(DateTime.now());
      buffer.writeln('Wordle Clone $today ${_guesses.length}/6 • 🔥$_streak');
      return buffer.toString();
    }

    final bool won = _guesses.isNotEmpty && _guesses.last == _word;
    final bool lost = !won;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(message),
        content: lost ? Text('Answer: $_word') : null,
        actions: [
          TextButton(
            onPressed: () async {
              final result = buildEmojiGrid();
              await Clipboard.setData(ClipboardData(text: result));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Result copied to clipboard!')),
                );
              }
            },
            child: const Text('Share Result'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              _newGame();                   // start fresh
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guessesLeft = 6 - _guesses.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Wordle Game · $guessesLeft left'),
        actions: [
          IconButton(
            tooltip: 'New Game',
            icon: const Icon(Icons.refresh),
            onPressed: () => _newGame(),
          )
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
                      labelText: 'Enter your guess',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _controller.text.length == 5 && !_gameOver ? _submitGuess : null,
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

// -------------------- STATS SCREEN --------------------
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int wins = 0, losses = 0, streak = 0, maxStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      wins = prefs.getInt('wins') ?? 0;
      losses = prefs.getInt('losses') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
      maxStreak = prefs.getInt('maxStreak') ?? 0;
    });
  }

  double _winRate() => (wins + losses) == 0 ? 0.0 : wins * 100.0 / (wins + losses);

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
            Text('Win Rate: ${_winRate().toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18)),
            Text('Current Streak: $streak', style: const TextStyle(fontSize: 18)),
            Text('Max Streak: $maxStreak', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// -------------------- SETTINGS SCREEN --------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Settings Placeholder')),
    );
  }
}
