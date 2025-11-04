import 'package:flutter/material.dart';
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
      theme: ThemeData(primarySwatch: Colors.green),
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
    setState(() {
      _selectedIndex = index;
    });
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
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// -------------------- GAME SCREEN --------------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final String _word = 'APPLE'; // temporary word
  final TextEditingController _controller = TextEditingController();
  final List<String> _guesses = [];
  late SharedPreferences _prefs;

  int _wins = 0;
  int _losses = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _wins = _prefs.getInt('wins') ?? 0;
      _losses = _prefs.getInt('losses') ?? 0;
      _streak = _prefs.getInt('streak') ?? 0;
    });
  }

  Future<void> _saveStats() async {
    await _prefs.setInt('wins', _wins);
    await _prefs.setInt('losses', _losses);
    await _prefs.setInt('streak', _streak);
  }

  void _submitGuess() {
    String guess = _controller.text.toUpperCase();
    if (guess.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid word length')),
      );
      return;
    }
    if (_guesses.contains(guess)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already guessed')),
      );
      return;
    }

    setState(() {
      _guesses.add(guess);
    });

    if (guess == _word) {
      _wins++;
      _streak++;
      _saveStats();
      _showEndDialog('You won!');
    } else if (_guesses.length >= 6) {
      _losses++;
      _streak = 0;
      _saveStats();
      _showEndDialog('Try again! The word was $_word');
    }

    _controller.clear();
  }

  void _showEndDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            child: const Text('Play Again'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _guesses.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wordle Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Enter your guess'),
              onSubmitted: (_) => _submitGuess(),
            ),
            ElevatedButton(onPressed: _submitGuess, child: const Text('Submit')),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _guesses.length,
                itemBuilder: (_, i) {
                  final guess = _guesses[i];
                  return ListTile(
                    title: Text(guess),
                    trailing: Text(
                      guess == _word ? '✅' : '❌',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
            ),
          ],
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
  int wins = 0, losses = 0, streak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      wins = prefs.getInt('wins') ?? 0;
      losses = prefs.getInt('losses') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Wins: $wins'),
            Text('Losses: $losses'),
            Text('Current Streak: $streak'),
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
