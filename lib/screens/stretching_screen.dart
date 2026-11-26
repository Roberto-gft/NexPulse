import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StretchPose {
  final String name;
  final String targetMuscle;
  final String guide;
  final int seconds;
  bool done;

  StretchPose({
    required this.name,
    required this.targetMuscle,
    required this.guide,
    this.seconds = 30,
    this.done = false,
  });
}

class StretchingScreen extends StatefulWidget {
  const StretchingScreen({super.key});

  @override
  State<StretchingScreen> createState() => _StretchingScreenState();
}

class _StretchingScreenState extends State<StretchingScreen> {
  final List<StretchPose> _poses = [
    StretchPose(
      name: 'Estiramiento de Cuádriceps de Pie',
      targetMuscle: 'Muslos y Flexores de Cadera',
      guide: 'Sujeta tu tobillo derecho detrás de ti llevando el talón al glúteo durante 30 segundos.',
    ),
    StretchPose(
      name: 'Flexión al Frente (Isquiotibiales)',
      targetMuscle: 'Parte posterior de piernas y espalda baja',
      guide: 'Con piernas rectas, inclina el torso suavemente intentando tocar las puntas de los pies.',
    ),
    StretchPose(
      name: 'Estiramiento de Gemelos en Pared',
      targetMuscle: 'Pantorrillas y Tendón de Aquiles',
      guide: 'Apoya manos en la pared, lleva una pierna atrás con el talón pegado al suelo.',
    ),
    StretchPose(
      name: 'Postura de Cobra Abdominal',
      targetMuscle: 'Abdomen y Zona Lumbar',
      guide: 'Boca abajo, apoya las palmas y eleva el pecho suavemente respirando profundo.',
    ),
    StretchPose(
      name: 'Apertura de Hombros y Pecho',
      targetMuscle: 'Pectorales y Deltoides',
      guide: 'Entrelaza tus manos detrás de la espalda y estira los brazos abriendo el pecho.',
    ),
  ];

  int _activeIndex = 0;
  int _secondsLeft = 30;
  bool _running = false;
  Timer? _timer;

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.mediumImpact();
        if (!mounted) return;
        setState(() {
          _poses[_activeIndex].done = true;
          if (_activeIndex < _poses.length - 1) {
            _activeIndex++;
            _secondsLeft = _poses[_activeIndex].seconds;
          } else {
            _running = false;
            _timer?.cancel();
            _secondsLeft = 30;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;
    final currentPose = _poses[_activeIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estiramiento y Recuperación',
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
              border: Border.all(color: const Color(0xFF2E9E6B)),
            ),
            child: Column(
              children: [
                Text(
                  'ESTIRAMIENTO ${_activeIndex + 1} DE ${_poses.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E9E6B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentPose.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  currentPose.guide,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 14),
                Text(
                  '00:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _running ? Colors.orange : const Color(0xFF2E9E6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    _running ? 'Pausar Sesión' : 'Iniciar Guía Sonora',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(_poses.length, (i) {
            final p = _poses[i];
            return Card(
              color: cardBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: i == _activeIndex ? const Color(0xFF2E9E6B) : borderCol,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  p.done ? Icons.check_circle : Icons.self_improvement,
                  color: p.done ? const Color(0xFF2E9E6B) : Colors.grey,
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(p.targetMuscle, style: const TextStyle(fontSize: 12)),
                onTap: () {
                  _timer?.cancel();
                  setState(() {
                    _running = false;
                    _activeIndex = i;
                    _secondsLeft = p.seconds;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}