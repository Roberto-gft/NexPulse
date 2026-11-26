import 'package:flutter/material.dart';
import 'package:nexpulse/screens/body_measurements_screen.dart';
import 'package:nexpulse/screens/challenges_badges_screen.dart';
import 'package:nexpulse/screens/fasting_tracker_screen.dart';
import 'package:nexpulse/screens/heart_zones_screen.dart';
import 'package:nexpulse/screens/hiit_timer_screen.dart';
import 'package:nexpulse/screens/hydration_screen.dart';
import 'package:nexpulse/screens/nutrition_screen.dart';
import 'package:nexpulse/screens/progress_report_screen.dart';
import 'package:nexpulse/screens/routines_screen.dart';
import 'package:nexpulse/screens/sensor_rep_counter_screen.dart';
import 'package:nexpulse/screens/shopping_list_screen.dart';
import 'package:nexpulse/screens/sleep_tracker_screen.dart';
import 'package:nexpulse/screens/stretching_screen.dart';
import 'package:nexpulse/screens/weight_tracker_screen.dart';
import 'package:nexpulse/utils/theme_controller.dart';

class FitnessHubTab extends StatefulWidget {
  const FitnessHubTab({super.key});

  @override
  State<FitnessHubTab> createState() => _FitnessHubTabState();
}

class _FitnessHubTabState extends State<FitnessHubTab> {
  String _selectedCategory = 'Todos';

  final List<String> _categories = const [
    'Todos',
    'Entrenamiento',
    'Nutrición',
    'Métricas',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0B1113) : const Color(0xFFF2F5F8);
    final cardBg = isDark ? const Color(0xFF151F23) : Colors.white;
    final borderCol =
    isDark ? Colors.white10 : Colors.grey.shade200.withValues(alpha: 0.85);

    final showTraining =
        _selectedCategory == 'Todos' || _selectedCategory == 'Entrenamiento';
    final showNutrition =
        _selectedCategory == 'Todos' || _selectedCategory == 'Nutrición';
    final showMetrics =
        _selectedCategory == 'Todos' || _selectedCategory == 'Métricas';

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // Cabecera Hero moderna con degradado y filtros rápidos
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D2327),
                  Color(0xFF153D37),
                  Color(0xFF21694F),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x280D2327),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFF4CE0A3).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF4CE0A3)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'NEXPULSE HUB',
                            style: TextStyle(
                              color: Color(0xFF4CE0A3),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => ThemeController.setDarkMode(!isDark),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    color: const Color(0xFF4CE0A3),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isDark ? 'Claro' : 'Oscuro',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Centro Fitness & Salud',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '14 herramientas inteligentes para entrenar, nutrirte y medir tu progreso.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final selected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF4CE0A3)
                                      : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? const Color(0xFF0D2327)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de módulos organizados por categorías
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                if (showTraining) ...[
                  const _SectionHeader(
                    icon: Icons.bolt_rounded,
                    title: 'ENTRENAMIENTO INTELIGENTE',
                    count: '4 módulos',
                  ),
                  _ModuleCard(
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF2E9E6B),
                    tag: 'Rutinas',
                    title: 'Rutinas con Cronómetro Sonoro',
                    subtitle: 'Series, técnica y alarma automática por ejercicio',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutinesScreen()),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.sensors_rounded,
                    color: Colors.teal,
                    tag: 'Sensores IA',
                    title: 'Contador IA por Sensores',
                    subtitle:
                    'Cuenta sentadillas o abdominales usando el acelerómetro',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SensorRepCounterScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.timer_rounded,
                    color: Colors.deepOrange,
                    tag: 'Cardio HIIT',
                    title: 'Temporizador HIIT / Tabata',
                    subtitle:
                    'Intervalos de alta intensidad para máxima quema calórica',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HiitTimerScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.self_improvement_rounded,
                    color: Colors.cyan,
                    tag: 'Movilidad',
                    title: 'Estiramiento y Recuperación',
                    subtitle: 'Guía post-entrenamiento con alerta sonora',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StretchingScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (showNutrition) ...[
                  const _SectionHeader(
                    icon: Icons.restaurant_rounded,
                    title: 'NUTRICIÓN Y METABOLISMO',
                    count: '4 módulos',
                  ),
                  _ModuleCard(
                    icon: Icons.restaurant_menu_rounded,
                    color: Colors.orange.shade700,
                    tag: 'Dieta & Macros',
                    title: 'Plan Alimenticio y Déficit Calórico',
                    subtitle: 'Ingredientes en gramos, preparación y macros',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NutritionScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.hourglass_bottom_rounded,
                    color: Colors.amber.shade800,
                    tag: 'Protocolos',
                    title: 'Ayuno Intermitente (16:8 / 18:6)',
                    subtitle: 'Control de ventanas y fases de quema de grasa',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FastingTrackerScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.water_drop_rounded,
                    color: Colors.blue.shade600,
                    tag: 'Hidratación',
                    title: 'Control de Hidratación Diaria',
                    subtitle: 'Registro rápido de agua y meta diaria',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HydrationScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.shopping_cart_rounded,
                    color: Colors.green.shade700,
                    tag: 'Supermercado',
                    title: 'Lista de Compras Saludables',
                    subtitle: 'Alimentos recomendados para tu dieta',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShoppingListScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (showMetrics) ...[
                  const _SectionHeader(
                    icon: Icons.insights_rounded,
                    title: 'MÉTRICAS CORPORALES Y LOGROS',
                    count: '6 módulos',
                  ),
                  _ModuleCard(
                    icon: Icons.monitor_weight_rounded,
                    color: Colors.indigoAccent,
                    tag: 'Peso & IMC',
                    title: 'Calculadora de IMC y Peso Meta',
                    subtitle: 'Índice de masa corporal y calorías recomendadas',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeightTrackerScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.straighten_rounded,
                    color: Colors.purpleAccent,
                    tag: 'Antropometría',
                    title: 'Medidas Corporales y % Grasa',
                    subtitle: 'Cintura, cadera, brazo y grasa corporal estimada',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BodyMeasurementsScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.favorite_rounded,
                    color: Colors.redAccent,
                    tag: 'Cardio PPM',
                    title: 'Zonas de Frecuencia Cardíaca',
                    subtitle: 'Rango exacto de PPM para oxidar grasa',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HeartZonesScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.bedtime_rounded,
                    color: Colors.indigo,
                    tag: 'Descanso',
                    title: 'Sueño y Recuperación Física',
                    subtitle: 'Evalúa tu descanso nocturno y fatiga',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SleepTrackerScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.emoji_events_rounded,
                    color: Colors.amber.shade700,
                    tag: 'Logros',
                    title: 'Retos y Medallas Desbloqueables',
                    subtitle: 'Insignias ganadas por tus pasos y sesiones',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChallengesBadgesScreen(),
                      ),
                    ),
                  ),
                  _ModuleCard(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF2E9E6B),
                    tag: 'Analítica',
                    title: 'Gráficas y Reporte de Progreso',
                    subtitle: 'Visualiza tu evolución y copia tu reporte',
                    cardBg: cardBg,
                    borderCol: borderCol,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgressReportScreen(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2E9E6B)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E9E6B),
                letterSpacing: 0.6,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tag;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color borderCol;
  final bool isDark;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.color,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.borderCol,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCol),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.22),
                        color.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color:
                          isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF3F6F8),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}