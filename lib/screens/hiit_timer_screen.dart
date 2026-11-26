import 'dart:async';
import 'package:flutter/material.dart';

class HiitTimerScreen extends StatefulWidget {
  const HiitTimerScreen({super.key});

  @override
  State<HiitTimerScreen> createState() => _HiitTimerScreenState();
}

class _HiitTimerScreenState extends State<HiitTimerScreen> {
  int _workSeconds = 30;
  int _restSeconds = 15;
  int _totalRounds = 8;

  int _currentRound = 1;
  int _secondsLeft = 30;
  bool _isWorkPhase = true;
  bool _isRunning = false;
  Timer? _timer;

  void _applyPreset(int work, int rest, int rounds) {
    _pauseTimer();
    setState(() {
      _workSeconds = work;
      _restSeconds = rest;
      _totalRounds = rounds;
      _currentRound = 1;
      _isWorkPhase = true;
      _secondsLeft = work;
    });
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          if (_isWorkPhase) {
            _isWorkPhase = false;
            _secondsLeft = _restSeconds;
          } else {
            if (_currentRound < _totalRounds) {
              _currentRound++;
              _isWorkPhase = true;
              _secondsLeft = _workSeconds;
            } else {
              _pauseTimer();
              _currentRound = 1;
              _isWorkPhase = true;
              _secondsLeft = _workSeconds;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Circuito HIIT completado! Excelente trabajo.'),
                  backgroundColor: Color(0xFF2E9E6B),
                ),
              );
            }
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _currentRound = 1;
      _isWorkPhase = true;
      _secondsLeft = _workSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxPhaseSeconds = _isWorkPhase ? _workSeconds : _restSeconds;
    final progress = maxPhaseSeconds == 0 ? 0.0 : _secondsLeft / maxPhaseSeconds;
    final activeColor =
    _isWorkPhase ? const Color(0xFF2E9E6B) : Colors.blue.shade600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Temporizador HIIT / Tabata',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preajustes rápidos
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(20, 10, 8),
                  child: const Text('Tabata 20/10'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(30, 15, 8),
                  child: const Text('Quema 30/15'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(45, 15, 6),
                  child: const Text('Intenso 45/15'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cronómetro circular
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _isWorkPhase ? '¡TRABAJO INTENSO!' : 'DESCANSO ACTIVO',
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_secondsLeft s',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Ronda $_currentRound de $_totalRounds',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(
                        _isRunning ? 'Pausar' : 'Iniciar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _resetTimer,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reiniciar'),
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