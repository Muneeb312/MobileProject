import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CrosswordScreen extends StatefulWidget {
  const CrosswordScreen({super.key});

  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  List<String> _words = [];

  // 5x5 solution / layout / current state
  late List<List<String>> _solution;
  late List<List<String>> _layout;
  late List<List<String>> _current;

  String? _wordAcross;
  String? _wordDown;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final words = await loadWordList();
    if (!mounted) return;

    setState(() {
      _words = words.where((w) => w.length == 5).toList();
    });

    _generatePuzzle();
  }

  void _generatePuzzle() {
    if (_words.isEmpty) return;

    final rand = Random();

    String across;
    String down;

    // We want wordAcross[2] == wordDown[2] so they cross cleanly in the centre.
    while (true) {
      across = _words[rand.nextInt(_words.length)];
      final middle = across[2];

      final candidates = _words.where((w) => w[2] == middle).toList();
      if (candidates.isEmpty) continue;

      down = candidates[rand.nextInt(candidates.length)];
      break;
    }

    _wordAcross = across;
    _wordDown = down;

    // Build a 5x5 full cross (no # blocks)
    _solution = List.generate(
      5,
          (_) => List<String>.filled(5, ''),
    );

    // Across in row 2 (0-index => 3rd row)
    for (int c = 0; c < 5; c++) {
      _solution[2][c] = across[c];
    }

    // Down in column 2 (3rd column)
    for (int r = 0; r < 5; r++) {
      _solution[r][2] = down[r];
    }

    // Layout = what the user sees initially:
    // - reveal centre crossing cell
    // - reveal first letter of across
    // - reveal first letter of down
    _layout = List.generate(5, (r) {
      return List.generate(5, (c) {
        final ch = _solution[r][c];

        final bool isCenter = (r == 2 && c == 2);
        final bool isAcrossFirst = (r == 2 && c == 0);
        final bool isDownFirst = (r == 0 && c == 2);

        if (isCenter || isAcrossFirst || isDownFirst) {
          return ch; // given
        }

        return ''; // blank to fill
      });
    });

    // Current board starts from layout
    _current = List.generate(
      5,
          (r) => List.generate(5, (c) {
        final cell = _layout[r][c];
        if (cell.isNotEmpty) return cell;
        return '';
      }),
    );

    setState(() {
      _isLoading = false;
    });
  }

  bool _isGiven(int r, int c) {
    final cell = _layout[r][c];
    return cell.isNotEmpty;
  }

  void _checkPuzzle(BuildContext context) {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (_current[r][c].toUpperCase() != _solution[r][c]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not quite right yet – keep trying!')),
          );
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cross filled correctly! 🎉')),
    );
  }

  void _newPuzzle() {
    setState(() {
      _isLoading = true;
    });
    _generatePuzzle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crossword')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          const int size = 5;

          double boardSize = constraints.biggest.shortestSide - 48;
          if (boardSize < 200) boardSize = 200;
          if (boardSize > 600) boardSize = 600;

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: GridView.builder(
                        physics:
                        const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                        ),
                        itemCount: size * size,
                        itemBuilder: (context, index) {
                          final r = index ~/ size;
                          final c = index % size;

                          final isGiven = _isGiven(r, c);
                          final value = _current[r][c];

                          return Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.shade400),
                              color: isGiven
                                  ? Colors.grey.shade300
                                  : Colors.white,
                            ),
                            child: Center(
                              child: isGiven
                                  ? Text(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                                  : TextField(
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                decoration:
                                const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                ),
                                onChanged: (text) {
                                  setState(() {
                                    _current[r][c] = text.isEmpty
                                        ? ''
                                        : text[0]
                                        .toUpperCase();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('New puzzle'),
                          onPressed: _newPuzzle,
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Check'),
                          onPressed: () => _checkPuzzle(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_wordAcross != null && _wordDown != null) ...[
                      Text(
                        'Across (row 3): ${_wordAcross!}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Down (col 3): ${_wordDown!}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shared middle letter: ${_wordAcross![2]}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Fill the two crossing 5-letter words from your Wordle list.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------- helpers using the same words list as your Wordle game ----------

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
