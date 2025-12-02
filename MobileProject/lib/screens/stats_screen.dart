import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int wins = 0, losses = 0, streak = 0, maxStreak = 0;
  final StorageService storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await storage.init();
    final w = await storage.getInt('wins', 0);
    final l = await storage.getInt('losses', 0);
    final s = await storage.getInt('streak', 0);
    final m = await storage.getInt('maxStreak', 0);
    if (!mounted) return;
    setState(() {
      wins = w; losses = l; streak = s; maxStreak = m;
    });
  }

  double _winRate() => (wins + losses) == 0 ? 0.0 : wins * 100.0 / (wins + losses);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Performance Report",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ------------------------------------------
            // Data Table
            // ------------------------------------------
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DataTable(
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Metric',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Value',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true, // Aligns numbers to the right
                    ),
                  ],
                  rows: [
                    DataRow(cells: [
                      const DataCell(Text('Total Games')),
                      DataCell(Text('${wins + losses}')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Wins')),
                      DataCell(Text('$wins')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Losses')),
                      DataCell(Text('$losses')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Win Rate')),
                      DataCell(Text('${_winRate().toStringAsFixed(1)}%')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Current Streak')),
                      DataCell(Text('$streak')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Best Streak')),
                      DataCell(Text('$maxStreak')),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
}