import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key});

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  int _goalHours = 16;
  DateTime? _fastStart;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  int _completedFasts = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _fastStart == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(_fastStart!);
      });
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString('fasting_start_iso');
    final hours = prefs.getInt('fasting_goal_hours') ?? 16;
    final count = prefs.getInt('fasting_completed_count') ?? 0;

    if (!mounted) return;
    setState(() {
      _goalHours = hours;
      _completedFasts = count;
      if (iso != null && iso.isNotEmpty) {
        _fastStart = DateTime.tryParse(iso);
        if (_fastStart != null) {
          _elapsed = DateTime.now().difference(_fastStart!);
        }
      }
    });
  }

  Future<void> _startFasting() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fasting_start_iso', now.toIso8601String());
    await prefs.setInt('fasting_goal_hours', _goalHours);
    setState(() {
      _fastStart = now;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _finishFasting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fasting_start_iso');
    final achieved = _elapsed.inHours >= _goalHours;
    if (achieved) {
      _completedFasts++;
      await prefs.setInt('fasting_completed_count', _completedFasts);
    }
    setState(() {
      _fastStart = null;
      _elapsed = Duration.zero;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          achieved
              ? '¡Ayuno completado con éxito! Total acumulados: $_completedFasts'
              : 'Ayuno finalizado antes de la meta.',
        ),
        backgroundColor: const Color(0xFF2E9E6B),
      ),
    );
  }

  String _metabolicStage(int hours) {
    if (_fastStart == null) return 'Inicia tu ventana de ayuno para ver tu estado metabólico.';
    if (hours < 4) return 'Fase 1 (0-4h): Digestión y estabilización de insulina.';
    if (hours < 12) return 'Fase 2 (4-12h): Agotamiento de reservas de glucógeno.';
    if (hours < 16) return 'Fase 3 (12-16h): Lipólisis activa (quema de grasa almacenada).';
    return 'Fase 4 (16h+): Cetosis ligera y regeneración celular (autofagia).';
  }

  String _formatDuration(Duration d) {
    final hrs = d.inHours.toString().padLeft(2, '0');
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
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
    final goalSeconds = _goalHours * 3600;
    final progress = goalSeconds == 0 ? 0.0 : (_elapsed.inSeconds / goalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayuno Intermitente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [14, 16, 18, 20].map((h) {
              final selected = _goalHours == h;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text('$h:${24 - h}'),
                    selected: selected,
                    selectedColor: const Color(0xFF2E9E6B),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: _fastStart != null
                        ? null
                        : (_) => setState(() => _goalHours = h),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Text(
                  _fastStart != null ? 'AYUNO EN CURSO ($_goalHours HORAS)' : 'PROTOCOLO $_goalHours:${24 - _goalHours}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E9E6B),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E9E6B)),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(_elapsed),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${(progress * 100).round()}% de meta',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E9E6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _metabolicStage(_elapsed.inHours),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E9E6B),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _fastStart == null ? _startFasting : _finishFasting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _fastStart == null ? const Color(0xFF2E9E6B) : Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(_fastStart == null ? Icons.play_arrow : Icons.restaurant),
                    label: Text(
                      _fastStart == null ? 'Iniciar Ayuno Ahora' : 'Terminar Ayuno y Comer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderCol),
            ),
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: const Text('Ayunos completados al 100%', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                '$_completedFasts',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}