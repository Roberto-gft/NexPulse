import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorRepCounterScreen extends StatefulWidget {
  const SensorRepCounterScreen({super.key});

  @override
  State<SensorRepCounterScreen> createState() => _SensorRepCounterScreenState();
}

class _SensorRepCounterScreenState extends State<SensorRepCounterScreen> {
  final List<String> _exercises = [
    'Sentadillas (Teléfono en bolsillo)',
    'Abdominales Crunch (Teléfono en pecho)',
    'Saltos de Tijera (En mano o bolsillo)',
    'Flexiones / Lagartijas (En espalda/suelo)',
  ];

  String _selectedExercise = 'Sentadillas (Teléfono en bolsillo)';
  int _targetReps = 15;
  int _currentReps = 0;
  double _threshold = 2.6;
  bool _isListening = false;
  double _liveMagnitude = 0.0;
  DateTime? _lastRepTime;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;

  void _toggleCounter() {
    if (_isListening) {
      _stopCounter();
    } else {
      _startCounter();
    }
  }

  void _startCounter() {
    if (_currentReps >= _targetReps) {
      _currentReps = 0;
    }
    setState(() => _isListening = true);

    _accelSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((UserAccelerometerEvent event) {
      if (!mounted || !_isListening) return;
      final mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      setState(() => _liveMagnitude = mag);

      if (mag >= _threshold) {
        final now = DateTime.now();
        if (_lastRepTime == null ||
            now.difference(_lastRepTime!).inMilliseconds > 800) {
          _lastRepTime = now;
          _onRepDetected();
        }
      }
    });
  }

  Future<void> _onRepDetected() async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.selectionClick();
    if (!mounted) return;

    setState(() {
      _currentReps++;
    });

    if (_currentReps >= _targetReps) {
      await _stopCounter();
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Meta alcanzada! $_targetReps repeticiones completadas.'),
          backgroundColor: const Color(0xFF2E9E6B),
        ),
      );
    }
  }

  Future<void> _stopCounter() async {
    await _accelSub?.cancel();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _liveMagnitude = 0.0;
    });
  }

  void _resetCounter() {
    _stopCounter();
    setState(() => _currentReps = 0);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;
    final progress = _targetReps == 0 ? 0.0 : (_currentReps / _targetReps).clamp(0.0, 1.0);
    final kcalEst = (_currentReps * 0.42).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contador IA por Sensores',
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
                  'Selecciona el ejercicio:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedExercise,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _exercises
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: _isListening
                      ? null
                      : (val) {
                    if (val != null) setState(() => _selectedExercise = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Meta de repeticiones:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: _isListening || _targetReps <= 5
                          ? null
                          : () => setState(() => _targetReps -= 5),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_targetReps',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: _isListening
                          ? null
                          : () => setState(() => _targetReps += 5),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Sensibilidad:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Alta'),
                      selected: _threshold == 1.9,
                      onSelected: _isListening ? null : (_) => setState(() => _threshold = 1.9),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Media'),
                      selected: _threshold == 2.6,
                      onSelected: _isListening ? null : (_) => setState(() => _threshold = 2.6),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Fuerte'),
                      selected: _threshold == 3.5,
                      onSelected: _isListening ? null : (_) => setState(() => _threshold = 3.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Text(
                  _isListening ? 'DETECTANDO MOVIMIENTO...' : 'LISTO PARA INICIAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _isListening ? const Color(0xFF2E9E6B) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$_currentReps / $_targetReps',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Calorías estimadas: $kcalEst kcal · Impulso: ${_liveMagnitude.toStringAsFixed(2)} m/s²',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E9E6B)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleCounter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF2E9E6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      ),
                      icon: Icon(_isListening ? Icons.stop : Icons.sensors),
                      label: Text(
                        _isListening ? 'Detener Sensor' : 'Activar Sensor',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _resetCounter,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Cero'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}