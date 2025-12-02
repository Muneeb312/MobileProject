// ------------------------------------------------------------
// FILE: settings_screen.dart
// PURPOSE:
//   Provides app settings such as choosing a daily reminder
//   date/time and resetting stored Wordle statistics.
//   Uses StorageService for persistence and NotificationService
//   to confirm reminder selections.
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ------------------------------------------------------------
  // STATE AND STORAGE
  // ------------------------------------------------------------

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final storage = StorageService();

  @override
  void initState() {
    super.initState();
    storage.init();
  }

  // ------------------------------------------------------------
  // REMINDER PICKER
  // ------------------------------------------------------------

  Future<void> _pickDateTime() async {
    // Pick calendar date.
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    // Pick time of day.
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });

    // Save reminder values.
    await storage.setInt('reminder_year', date.year);
    await storage.setInt('reminder_month', date.month);
    await storage.setInt('reminder_day', date.day);
    await storage.setInt('reminder_hour', time.hour);
    await storage.setInt('reminder_minute', time.minute);

    // Confirmation notification (local preview only).
    await NotificationService().showNotification(
      id: 0,
      title: 'Reminder set',
      body: 'Reminder for ${DateFormat.yMMMd().format(date)} '
          'at ${time.format(context)}',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for '
              '${DateFormat.yMMMd().format(date)} ${time.format(context)}',
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------

  String friendly() {
    if (_selectedDate == null || _selectedTime == null) {
      return 'No reminder set';
    }
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return DateFormat.yMMMd().add_jm().format(dt);
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Daily reminder tile.
            ListTile(
              title: const Text('Daily Reminder'),
              subtitle: Text(friendly()),
              trailing: FilledButton(
                onPressed: _pickDateTime,
                child: const Text('Pick'),
              ),
            ),

            const SizedBox(height: 16),

            // Reset statistics tile.
            ListTile(
              title: const Text('Reset Stats'),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  await storage.setInt('wins', 0);
                  await storage.setInt('losses', 0);
                  await storage.setInt('streak', 0);
                  await storage.setInt('maxStreak', 0);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stats reset')),
                  );
                },
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
