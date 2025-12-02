import 'package:flutter/material.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  // 0 = empty; other numbers are givens.
  final List<List<int>> _puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  final List<List<int>> _solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  late List<List<int>> _current;

  @override
  void initState() {
    super.initState();
    _current = _copyBoard(_puzzle);
  }

  List<List<int>> _copyBoard(List<List<int>> src) =>
      List.generate(9, (r) => List<int>.from(src[r]));

  bool _isGiven(int r, int c) => _puzzle[r][c] != 0;

  void _clearBoard() {
    setState(() {
      _current = _copyBoard(_puzzle);
    });
  }

  void _checkBoard(BuildContext context) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_current[r][c] != _solution[r][c]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not solved yet – keep going!')),
          );
          return;
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sudoku solved! 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    itemCount: 81,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemBuilder: (context, index) {
                      final r = index ~/ 9;
                      final c = index % 9;
                      final isGiven = _isGiven(r, c);
                      final value = _current[r][c];

                      BorderSide thin = BorderSide(color: Colors.grey.shade400);
                      BorderSide thick = const BorderSide(width: 2);

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: r % 3 == 0 ? thick : thin,
                            left: c % 3 == 0 ? thick : thin,
                            right: (c == 8) ? thick : thin,
                            bottom: (r == 8) ? thick : thin,
                          ),
                          color: isGiven
                              ? Colors.grey.shade300
                              : Colors.white,
                        ),
                        child: Center(
                          child: isGiven
                              ? Text(
                            value.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                              : TextField(
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (text) {
                              setState(() {
                                if (text.isEmpty) {
                                  _current[r][c] = 0;
                                } else {
                                  final n = int.tryParse(text);
                                  _current[r][c] = (n != null && n >= 1 && n <= 9)
                                      ? n
                                      : 0;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear'),
                  onPressed: _clearBoard,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Check'),
                  onPressed: () => _checkBoard(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the grid so each row, column, and 3×3 box contains 1–9.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
