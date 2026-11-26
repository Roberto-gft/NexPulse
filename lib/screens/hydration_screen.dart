import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  int _currentMl = 0;
  final int _goalMl = 2500;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadHydrationData();
  }

  Future<void> _loadHydrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    setState(() {
      _currentMl = prefs.getInt('water_ml_$todayKey') ?? 0;
      _logs = prefs.getStringList('water_logs_$todayKey') ?? [];
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _addWater(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _currentMl = (_currentMl + ml).clamp(0, 10000);
      if (ml > 0) {
        _logs.insert(0, '+$ml ml registrado a las $timeStr');
      } else if (_logs.isNotEmpty) {
        _logs.removeAt(0);
      }
    });

    await prefs.setInt('water_ml_$todayKey', _currentMl);
    await prefs.setStringList('water_logs_$todayKey', _logs);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentMl / _goalMl).clamp(0.0, 1.0);
    final glasses = (_currentMl / 250).floor();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Control de Hidratación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.water_drop, size: 46, color: Colors.blue.shade600),
                const SizedBox(height: 8),
                Text(
                  '$_currentMl / $_goalMl ml',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Equivalente a $glasses vasos de 250 ml',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.blue.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addWater(250),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+250 ml'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addWater(500),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+500 ml'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentMl >= 250 ? () => _addWater(-250) : null,
                        child: const Text('-250 ml'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Registros de hoy',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          if (_logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Aún no has registrado tomas de agua hoy. ¡Toma tu primer vaso!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._logs.map(
                  (entry) => Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Icon(Icons.local_drink, color: Colors.blue.shade600),
                  title: Text(entry, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}