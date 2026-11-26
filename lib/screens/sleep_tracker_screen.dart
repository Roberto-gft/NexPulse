import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  double _hoursSlept = 7.5;
  String _quality = 'Reparador';
  List<String> _sleepLogs = [];

  @override
  void initState() {
    super.initState();
    _loadSleep();
  }

  Future<void> _loadSleep() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sleepLogs = prefs.getStringList('sleep_logs') ?? [];
    });
  }

  Future<void> _saveSleep() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final score = _recoveryScore();
    final entry =
        '${now.day}/${now.month}/${now.year} · ${_hoursSlept.toStringAsFixed(1)} hrs ($_quality) · Recuperación $score%';
    _sleepLogs.insert(0, entry);
    await prefs.setStringList('sleep_logs', _sleepLogs);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro de sueño guardado correctamente.'),
        backgroundColor: Color(0xFF2E9E6B),
      ),
    );
  }

  int _recoveryScore() {
    int base = ((_hoursSlept / 8.0) * 80).round().clamp(30, 85);
    if (_quality == 'Reparador') base += 15;
    if (_quality == 'Normal') base += 5;
    return base.clamp(20, 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;
    final score = _recoveryScore();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sueño y Recuperación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                const Icon(Icons.bedtime, size: 42, color: Colors.indigoAccent),
                const SizedBox(height: 8),
                Text(
                  'Recuperación Física: $score%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hoursSlept >= 7
                      ? 'Descanso óptimo: niveles bajos de cortisol favorecen la pérdida de grasa.'
                      : 'Dormir menos de 7 horas aumenta la grelina (hormona del apetito).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                Text(
                  'Horas dormidas: ${_hoursSlept.toStringAsFixed(1)} h',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: _hoursSlept,
                  min: 4.0,
                  max: 11.0,
                  divisions: 14,
                  activeColor: Colors.indigoAccent,
                  onChanged: (v) => setState(() => _hoursSlept = v),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: ['Cansado', 'Normal', 'Reparador'].map((q) {
                    return ChoiceChip(
                      label: Text(q),
                      selected: _quality == q,
                      onSelected: (_) => setState(() => _quality = q),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _saveSleep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Registrar Descanso de Hoy'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._sleepLogs.map(
                (e) => Card(
              color: cardBg,
              elevation: 0,
              child: ListTile(
                leading:
                const Icon(Icons.nights_stay, color: Colors.indigoAccent),
                title: Text(e, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}