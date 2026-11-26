import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutRecord {
  final String id;
  final String date;
  final int steps;
  final double distance;
  final double calories;
  final int duration;
  final double avgSpeed;
  final double maxSpeed;
  final double peakAccel;
  final double gyroTotal;
  final String activityType;
  final List<LatLng> route;

  WorkoutRecord({
    required this.id,
    required this.date,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.duration,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.peakAccel,
    required this.gyroTotal,
    required this.activityType,
    required this.route,
  });

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    final List<LatLng> parsedRoute = [];
    final rawRoute = json['route'];
    if (rawRoute is List) {
      for (final item in rawRoute) {
        if (item is Map) {
          final lat = (item['lat'] as num?)?.toDouble();
          final lng = (item['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            parsedRoute.add(LatLng(lat, lng));
          }
        }
      }
    }

    return WorkoutRecord(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      avgSpeed: (json['avgSpeed'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 0.0,
      peakAccel: (json['peakAccel'] as num?)?.toDouble() ?? 0.0,
      gyroTotal: (json['gyroTotal'] as num?)?.toDouble() ?? 0.0,
      activityType: json['activityType']?.toString() ?? 'Caminata',
      route: parsedRoute,
    );
  }
}

class HistoryTab extends StatefulWidget {
  final bool isActiveTab;

  const HistoryTab({super.key, this.isActiveTab = false});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<WorkoutRecord> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab) {
      _loadWorkouts();
    }
  }

  Future<void> _loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('workout_history') ?? [];
    final List<WorkoutRecord> parsed = [];

    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          parsed.add(WorkoutRecord.fromJson(decoded));
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _workouts = parsed;
      _isLoading = false;
    });
  }

  Future<void> _deleteWorkout(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('workout_history') ?? [];
    if (index >= 0 && index < rawList.length) {
      rawList.removeAt(index);
      await prefs.setStringList('workout_history', rawList);
      await _loadWorkouts();
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/${dt.year} · $hour:$min';
    } catch (_) {
      return 'Recorrido registrado';
    }
  }

  String _formatDuration(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    if (mins >= 60) {
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '${hrs}h ${remMins}m ${secs}s';
    }
    return '${mins}m ${secs}s';
  }

  Color _activityColor(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('carrera') || lower.contains('correr')) {
      return Colors.deepOrange;
    }
    if (lower.contains('trote')) {
      return Colors.amber.shade700;
    }
    return const Color(0xFF2E9E6B);
  }

  IconData _activityIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('carrera') || lower.contains('correr')) {
      return Icons.directions_run_rounded;
    }
    if (lower.contains('trote')) {
      return Icons.directions_run_rounded;
    }
    return Icons.directions_walk_rounded;
  }

  void _openDetailedMapModal(WorkoutRecord workout) {
    final points = List<LatLng>.from(workout.route);
    if (points.isEmpty) {
      points.add(const LatLng(20.2236, -99.0928));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _activityColor(workout.activityType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF151F23) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.84,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _activityIcon(workout.activityType),
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalle Completo del Recorrido',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(workout.date)} · ${workout.activityType}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF2F5F8),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 240,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: points.last,
                              initialZoom: 16.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.nexpulse.app',
                              ),
                              if (points.length > 1)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: points,
                                      strokeWidth: 5.0,
                                      color: const Color(0xFF2E9E6B),
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: points.first,
                                    width: 34,
                                    height: 34,
                                    child: const Icon(
                                      Icons.trip_origin,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  Marker(
                                    point: points.last,
                                    width: 38,
                                    height: 38,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2327)
                                  .withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trip_origin,
                                  color: Colors.lightBlueAccent,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Inicio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Fin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.15,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _DetailStatBox(
                      icon: Icons.timer_outlined,
                      iconColor: Colors.teal,
                      label: 'Duración',
                      value: _formatDuration(workout.duration),
                    ),
                    _DetailStatBox(
                      icon: Icons.directions_walk_rounded,
                      iconColor: Colors.blue,
                      label: 'Pasos Totales',
                      value: '${workout.steps} pasos',
                    ),
                    _DetailStatBox(
                      icon: Icons.straighten_rounded,
                      iconColor: const Color(0xFF2E9E6B),
                      label: 'Distancia Recorrida',
                      value: workout.distance >= 1000
                          ? '${(workout.distance / 1000).toStringAsFixed(2)} km'
                          : '${workout.distance.toStringAsFixed(1)} m',
                    ),
                    _DetailStatBox(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.deepOrange,
                      label: 'Calorías Quemadas',
                      value: '${workout.calories.toStringAsFixed(1)} kcal',
                    ),
                    _DetailStatBox(
                      icon: Icons.speed_rounded,
                      iconColor: Colors.indigoAccent,
                      label: 'Velocidad Promedio',
                      value: '${workout.avgSpeed.toStringAsFixed(1)} km/h',
                    ),
                    _DetailStatBox(
                      icon: Icons.flash_on_rounded,
                      iconColor: Colors.amber.shade700,
                      label: 'Velocidad Máxima',
                      value: '${workout.maxSpeed.toStringAsFixed(1)} km/h',
                    ),
                    _DetailStatBox(
                      icon: Icons.show_chart_rounded,
                      iconColor: Colors.purpleAccent,
                      label: 'Pico Acelerómetro',
                      value: '${workout.peakAccel.toStringAsFixed(2)} m/s²',
                    ),
                    _DetailStatBox(
                      icon: Icons.sync_rounded,
                      iconColor: Colors.cyan,
                      label: 'Puntos GPS y Giro',
                      value:
                      '${points.length} pts (${workout.gyroTotal.toStringAsFixed(2)} rad/s)',
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0B1113) : const Color(0xFFF2F5F8);
    final cardBg = isDark ? const Color(0xFF151F23) : Colors.white;
    final borderCol =
    isDark ? Colors.white10 : Colors.grey.shade200.withValues(alpha: 0.85);

    final totalSteps = _workouts.fold<int>(
      0,
          (sum, item) => sum + item.steps,
    );
    final totalDistance = _workouts.fold<double>(
      0.0,
          (sum, item) => sum + item.distance,
    );
    final totalCalories = _workouts.fold<double>(
      0.0,
          (sum, item) => sum + item.calories,
    );

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // Cabecera Hero moderna con degradado y resumen acumulado
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                            'BITÁCORA GPS',
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
                            onTap: _loadWorkouts,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: Color(0xFF4CE0A3),
                                    size: 17,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Actualizar',
                                    style: TextStyle(
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
                      'Historial de Recorridos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consulta tus rutas GPS, calorías y telemetría guardada.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Barra de estadísticas acumuladas
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          _HeroSummaryStat(
                            label: 'Sesiones',
                            value: '${_workouts.length}',
                          ),
                          _HeroVerticalDivider(),
                          _HeroSummaryStat(
                            label: 'Pasos',
                            value: '$totalSteps',
                          ),
                          _HeroVerticalDivider(),
                          _HeroSummaryStat(
                            label: 'Distancia',
                            value: totalDistance >= 1000
                                ? '${(totalDistance / 1000).toStringAsFixed(2)} km'
                                : '${totalDistance.toStringAsFixed(0)} m',
                          ),
                          _HeroVerticalDivider(),
                          _HeroSummaryStat(
                            label: 'Calorías',
                            value: '${totalCalories.toStringAsFixed(1)} kcal',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Cuerpo principal
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E9E6B),
              ),
            )
                : _workouts.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderCol),
                    boxShadow: isDark
                        ? null
                        : [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.045),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E9E6B)
                              .withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 36,
                          color: Color(0xFF2E9E6B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no tienes entrenamientos guardados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia y finaliza una rutina en la pestaña Entrenamiento para ver aquí tus estadísticas acumuladas y rutas GPS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? Colors.white60
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                final w = _workouts[index];
                final accent = _activityColor(w.activityType);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderCol),
                    boxShadow: isDark
                        ? null
                        : [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.045),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _openDetailedMapModal(w),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // Cabecera de la sesión
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(
                                        alpha: 0.14),
                                    borderRadius:
                                    BorderRadius.circular(11),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _activityIcon(w.activityType),
                                        size: 15,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        w.activityType,
                                        style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDate(w.date),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar recorrido',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.redAccent
                                        .withValues(alpha: 0.10),
                                    foregroundColor: Colors.redAccent,
                                    minimumSize: const Size(34, 34),
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                  ),
                                  onPressed: () =>
                                      _deleteWorkout(index),
                                ),
                              ],
                            ),

                            // Vista previa del mapa GPS
                            if (w.route.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        height: 122,
                                        child: AbsorbPointer(
                                          child: FlutterMap(
                                            options: MapOptions(
                                              initialCenter:
                                              w.route.last,
                                              initialZoom: 15.5,
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                userAgentPackageName:
                                                'com.nexpulse.app',
                                              ),
                                              if (w.route.length > 1)
                                                PolylineLayer(
                                                  polylines: [
                                                    Polyline(
                                                      points: w.route,
                                                      strokeWidth:
                                                      4.0,
                                                      color: const Color(
                                                          0xFF2E9E6B),
                                                    ),
                                                  ],
                                                ),
                                              MarkerLayer(
                                                markers: [
                                                  Marker(
                                                    point:
                                                    w.route.last,
                                                    width: 28,
                                                    height: 28,
                                                    child: const Icon(
                                                      Icons
                                                          .location_on,
                                                      color:
                                                      Colors.red,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 8,
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                                0xFF0D2327)
                                                .withValues(
                                                alpha: 0.84),
                                            borderRadius:
                                            BorderRadius.circular(
                                                8),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                            MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .gps_fixed_rounded,
                                                size: 12,
                                                color:
                                                Color(0xFF4CE0A3),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${w.route.length} pts GPS',
                                                style:
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.5,
                                                  fontWeight:
                                                  FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Cuadrícula 2x2 de métricas limpias
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricPill(
                                    icon: Icons.timer_outlined,
                                    iconColor: Colors.teal,
                                    label: 'Duración',
                                    value:
                                    _formatDuration(w.duration),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MetricPill(
                                    icon:
                                    Icons.directions_walk_rounded,
                                    iconColor: Colors.blue,
                                    label: 'Pasos',
                                    value: '${w.steps}',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricPill(
                                    icon: Icons.straighten_rounded,
                                    iconColor:
                                    const Color(0xFF2E9E6B),
                                    label: 'Distancia',
                                    value: w.distance >= 1000
                                        ? '${(w.distance / 1000).toStringAsFixed(2)} km'
                                        : '${w.distance.toStringAsFixed(1)} m',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MetricPill(
                                    icon: Icons
                                        .local_fire_department_rounded,
                                    iconColor: Colors.deepOrange,
                                    label: 'Calorías',
                                    value:
                                    '${w.calories.toStringAsFixed(1)} kcal',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Pie con telemetría y botón de acción
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Vel. prom: ${w.avgSpeed.toStringAsFixed(1)} km/h · Pico: ${w.peakAccel.toStringAsFixed(2)} m/s²',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E9E6B)
                                        .withValues(alpha: 0.14),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ver mapa',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2E9E6B),
                                        ),
                                      ),
                                      SizedBox(width: 3),
                                      Icon(
                                        Icons
                                            .arrow_forward_ios_rounded,
                                        size: 11,
                                        color: Color(0xFF2E9E6B),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroSummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailStatBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}