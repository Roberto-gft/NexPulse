import 'package:flutter/material.dart';

class HeartZonesScreen extends StatefulWidget {
  const HeartZonesScreen({super.key});

  @override
  State<HeartZonesScreen> createState() => _HeartZonesScreenState();
}

class _HeartZonesScreenState extends State<HeartZonesScreen> {
  double _age = 20;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    final int maxHr = (220 - _age).round();
    final zones = [
      _HrZone(
        name: 'Zona 1 · Calentamiento (50-60%)',
        minBpm: (maxHr * 0.50).round(),
        maxBpm: (maxHr * 0.60).round(),
        benefit: 'Recuperación activa, mejora circulación y movilidad.',
        color: Colors.blue,
      ),
      _HrZone(
        name: 'Zona 2 · Quema de Grasa (60-70%)',
        minBpm: (maxHr * 0.60).round(),
        maxBpm: (maxHr * 0.70).round(),
        benefit: 'Zona óptima para oxidar grasa corporal y ganar resistencia base.',
        color: const Color(0xFF2E9E6B),
      ),
      _HrZone(
        name: 'Zona 3 · Aeróbica / Cardio (70-80%)',
        minBpm: (maxHr * 0.70).round(),
        maxBpm: (maxHr * 0.80).round(),
        benefit: 'Fortalece corazón, pulmones y gasto calórico sostenido.',
        color: Colors.amber.shade700,
      ),
      _HrZone(
        name: 'Zona 4 · Umbral Anaeróbico (80-90%)',
        minBpm: (maxHr * 0.80).round(),
        maxBpm: (maxHr * 0.90).round(),
        benefit: 'Ideal para intervalos HIIT y aumento de velocidad.',
        color: Colors.deepOrange,
      ),
      _HrZone(
        name: 'Zona 5 · Esfuerzo Máximo (90-100%)',
        minBpm: (maxHr * 0.90).round(),
        maxBpm: maxHr,
        benefit: 'Sprints cortos de máxima potencia muscular.',
        color: Colors.redAccent,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Zonas de Frecuencia Cardíaca',
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tu Edad: ${_age.round()} años',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FC Máx: $maxHr PPM',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _age,
                  min: 14,
                  max: 80,
                  divisions: 66,
                  activeColor: const Color(0xFF2E9E6B),
                  onChanged: (val) => setState(() => _age = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...zones.map((z) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 54,
                    decoration: BoxDecoration(
                      color: z.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          z.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          z.benefit,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${z.minBpm}-${z.maxBpm}\nPPM',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: z.color,
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

class _HrZone {
  final String name;
  final int minBpm;
  final int maxBpm;
  final String benefit;
  final Color color;

  _HrZone({
    required this.name,
    required this.minBpm,
    required this.maxBpm,
    required this.benefit,
    required this.color,
  });
}