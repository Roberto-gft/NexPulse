import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengesBadgesScreen extends StatefulWidget {
  const ChallengesBadgesScreen({super.key});

  @override
  State<ChallengesBadgesScreen> createState() => _ChallengesBadgesScreenState();
}

class _ChallengesBadgesScreenState extends State<ChallengesBadgesScreen> {
  int _totalSessions = 0;
  int _totalSteps = 0;
  double _totalCalories = 0.0;
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('workout_history') ?? [];

    int sessions = 0;
    int steps = 0;
    double calories = 0.0;
    double distance = 0.0;

    for (final item in rawList) {
      try {
        final map = jsonDecode(item);
        if (map is Map<String, dynamic>) {
          sessions++;
          steps += (map['steps'] as num?)?.toInt() ?? 0;
          calories += (map['calories'] as num?)?.toDouble() ?? 0.0;
          distance += (map['distance'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _totalSessions = sessions;
      _totalSteps = steps;
      _totalCalories = calories;
      _totalDistance = distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    final badges = [
      _BadgeData(
        title: 'Primer Entrenamiento',
        description: 'Completa y guarda tu primera sesión en NexPulse.',
        icon: Icons.flag,
        color: const Color(0xFF2E9E6B),
        progress: (_totalSessions / 1).clamp(0.0, 1.0),
        unlocked: _totalSessions >= 1,
      ),
      _BadgeData(
        title: 'Caminante Constante (1,000 Pasos)',
        description: 'Acumula 1,000 pasos registrados en tus recorridos.',
        icon: Icons.directions_walk,
        color: Colors.blue,
        progress: (_totalSteps / 1000).clamp(0.0, 1.0),
        unlocked: _totalSteps >= 1000,
      ),
      _BadgeData(
        title: 'Quema Calórica (250 kcal)',
        description: 'Quema un acumulado de 250 kcal entrenando.',
        icon: Icons.local_fire_department,
        color: Colors.deepOrange,
        progress: (_totalCalories / 250).clamp(0.0, 1.0),
        unlocked: _totalCalories >= 250,
      ),
      _BadgeData(
        title: 'Explorador Urbano (2 km)',
        description: 'Recorre 2,000 metros rastreados por GPS.',
        icon: Icons.explore,
        color: Colors.teal,
        progress: (_totalDistance / 2000).clamp(0.0, 1.0),
        unlocked: _totalDistance >= 2000,
      ),
      _BadgeData(
        title: 'Atleta Disciplinado (5 Sesiones)',
        description: 'Completa 5 sesiones de entrenamiento registradas.',
        icon: Icons.military_tech,
        color: Colors.amber.shade700,
        progress: (_totalSessions / 5).clamp(0.0, 1.0),
        unlocked: _totalSessions >= 5,
      ),
      _BadgeData(
        title: 'Maratonista Semanal (10,000 Pasos)',
        description: 'Alcanza los 10,000 pasos acumulados.',
        icon: Icons.emoji_events,
        color: Colors.purpleAccent,
        progress: (_totalSteps / 10000).clamp(0.0, 1.0),
        unlocked: _totalSteps >= 10000,
      ),
    ];

    final unlockedCount = badges.where((b) => b.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Retos y Medallas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102A2E), Color(0xFF2E9E6B)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.amber, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logros Desbloqueados: $unlockedCount / ${badges.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tus medallas se desbloquean automáticamente con tus entrenamientos.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...badges.map((b) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: b.unlocked ? const Color(0xFF2E9E6B) : borderCol,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: b.unlocked
                        ? b.color.withValues(alpha: 0.18)
                        : Colors.grey.withValues(alpha: 0.14),
                    child: Icon(
                      b.icon,
                      color: b.unlocked ? b.color : Colors.grey,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (b.unlocked)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF2E9E6B),
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          b.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: b.progress,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              b.unlocked ? const Color(0xFF2E9E6B) : b.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BadgeData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double progress;
  final bool unlocked;

  _BadgeData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
    required this.unlocked,
  });
}