# Mobile Word Games App

This Flutter application contains multiple classic word and logic games.  
It demonstrates UI development, game logic, persistent storage, notifications, and navigation in Flutter.

## Features

### Wordle
- Fully implemented Wordle clone.
- Random 5-letter words fetched from an online API, with offline fallback.
- Letter scoring (correct, present, absent).
- On-screen keyboard with color updates.
- Emoji-style shareable result grid.
- Tracks game stats:
    - Wins
    - Losses
    - Current streak
    - Maximum streak
- Stats stored locally using SharedPreferences.

### Duordle
- Variant of Wordle with two boards at once.
- One guess applies to both the left and right word.
- Separate scoring for each board.
- Win only if both words are solved within 6 guesses.

### Hangman
- Classic letter-guessing game.
- Random words loaded from `assets/words.txt`.
- Tracks wrong guesses.
- Win/loss dialog with "Play Again" and "Back" options.

### Sudoku
- 9×9 Sudoku board with editable and fixed cells.
- 3×3 box borders highlighted.
- "Check" button validates the board against the solution.
- "Clear" button resets the puzzle.
- "Randomize" button provides a new randomized puzzle.

### Settings & Notifications
- Date and time picker for scheduling reminders.
- Stored using SharedPreferences.
- Displays a confirmation notification when a reminder is set.
- Option to reset gameplay statistics.

### Stats Page
- Displays:
    - Total wins
    - Total losses
    - Win rate
    - Current streak
    - Maximum streak
- Data refreshed from SharedPreferences.

### How to Play (Bottom Sheet)
Located in `widgets/help_bottom_sheet.dart`:
- Describes how Wordle, Hangman, Duordle, and Sudoku work.
- Accessible from the Home screen.

---

## Project Structure

lib/
├── main.dart
├── screens/
│ ├── home_screen.dart
│ ├── game_screen.dart
│ ├── duordle_screen.dart
│ ├── hangman_screen.dart
│ ├── sudoku_screen.dart
│ ├── stats_screen.dart
│ └── settings_screen.dart
├── services/
│ ├── notification_service.dart
│ └── storage_service.dart
├── widgets/
│ └── help_bottom_sheet.dart
assets/
└── words.txt
pubspec.yaml
README.md

---

## Technologies Used
- Flutter / Dart
- Material 3
- HTTP API requests
- Local asset loading
- SharedPreferences
- Local notifications

---

## Running the App

1. Install Flutter and run:
   flutter pub get
   flutter run
2. Ensure the asset is included in `pubspec.yaml`:
   assets:
          assets/words.txt

---

## Notes
- Notifications are disabled automatically on macOS due to OS limitations.
- API fallback ensures games still work offline.

