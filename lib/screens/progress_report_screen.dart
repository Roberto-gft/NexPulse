import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionSummary {
  final int steps;
  final double calories;
  final double distance;
  final double maxSpeed;

  const SessionSummary({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.maxSpeed,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  List<SessionSummary> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('workout_history') ?? [];
    final List<SessionSummary> parsedList = [];

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          parsedList.add(SessionSummary.fromJson(decoded));
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _sessions = parsedList);
  }

  Future<void> _copyReport() async {
    final totalSteps = _sessions.fold<int>(0, (sum, e) => sum + e.steps);
    final totalKcal = _sessions.fold<double>(0.0, (sum, e) => sum + e.calories);
    final totalDist = _sessions.fold<double>(0.0, (sum, e) => sum + e.distance);

    final report = '''
REPORTE DE RENDIMIENTO NEXPULSE
-------------------------------
Sesiones completadas: ${_sessions.length}
Pasos acumulados: $totalSteps
Distancia total: ${totalDist.toStringAsFixed(1)} m
Calorías quemadas: ${totalKcal.toStringAsFixed(1)} kcal
''';

    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporte copiado al portapapeles listo para compartir.'),
        backgroundColor: Color(0xFF2E9E6B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    final recent = _sessions.take(7).toList().reversed.toList();
    double maxKcal = 10.0;
    int maxSteps = 0;
    double maxSpeed = 0.0;

    for (final s in _sessions) {
      maxKcal = max(maxKcal, s.calories);
      maxSteps = max(maxSteps, s.steps);
      maxSpeed = max(maxSpeed, s.maxSpeed);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gráficas y Reporte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CALORÍAS QUEMADAS (ÚLTIMAS SESIONES)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                if (recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Registra un entrenamiento para visualizar tu gráfica.',
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(recent.length, (i) {
                        final kcal = recent[i].calories;
                        final barHeight =
                        ((kcal / maxKcal) * 110).clamp(12.0, 110.0);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              kcal.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 26,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E9E6B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'S${i + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RÉCORDS PERSONALES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                  const Icon(Icons.directions_walk, color: Colors.blue),
                  title: const Text('Máximo de pasos en una sesión'),
                  trailing: Text(
                    '$maxSteps',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                  const Icon(Icons.speed, color: Colors.deepOrange),
                  title: const Text('Velocidad máxima GPS'),
                  trailing: Text(
                    '${maxSpeed.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _copyReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E9E6B),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.copy),
              label: const Text(
                'Copiar Reporte de Progreso',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}