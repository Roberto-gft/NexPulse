import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/workout_session.dart';
import '../services/storage_service.dart';

enum HistoryMapStyle { standard, satellite, terrain }

class HistoryTab extends StatefulWidget {
  final bool isActiveTab;

  const HistoryTab({super.key, required this.isActiveTab});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final StorageService _storage = StorageService();
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActiveTab && widget.isActiveTab) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final items = await _storage.getWorkouts();
    if (!mounted) return;
    setState(() {
      _sessions = items;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$min';
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours}h $mins:$secs';
    }
    return '$mins:$secs min';
  }

  double _calculateSpeedKmh(WorkoutSession s) {
    if (s.durationSeconds <= 0) return 0.0;
    return (s.distanceMeters / s.durationSeconds) * 3.6;
  }

  String _calculatePaceMinPerKm(WorkoutSession s) {
    if (s.distanceMeters <= 10 || s.durationSeconds <= 0) return '--:-- /km';
    final double km = s.distanceMeters / 1000.0;
    final double totalMinutes = s.durationSeconds / 60.0;
    final double pace = totalMinutes / km;
    final int paceMins = pace.floor();
    final int paceSecs = ((pace - paceMins) * 60).round().clamp(0, 59);
    return '$paceMins:${paceSecs.toString().padLeft(2, '0')} /km';
  }

  void _showRouteModal(WorkoutSession session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return _DetailedRouteSheet(
          session: session,
          formattedDate: _formatDate(session.date),
          formattedDuration: _formatDuration(session.durationSeconds),
          speedKmh: _calculateSpeedKmh(session),
          paceMinPerKm: _calculatePaceMinPerKm(session),
        );
      },
    );
  }

  Widget _buildAccumulatedStatsCard() {
    final int totalSteps =
    _sessions.fold<int>(0, (sum, item) => sum + item.steps);
    final double totalDistance =
    _sessions.fold<double>(0.0, (sum, item) => sum + item.distanceMeters);
    final double totalCalories =
    _sessions.fold<double>(0.0, (sum, item) => sum + item.caloriesBurned);
    final int totalSeconds =
    _sessions.fold<int>(0, (sum, item) => sum + item.durationSeconds);
    final double avgSpeed =
    totalSeconds > 0 ? (totalDistance / totalSeconds) * 3.6 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ESTADÍSTICAS ACUMULADAS',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_sessions.length} ${_sessions.length == 1 ? 'sesión' : 'sesiones'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Pasos Totales',
                  value: '$totalSteps',
                  icon: Icons.directions_walk,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Distancia Total',
                  value: totalDistance >= 1000
                      ? '${(totalDistance / 1000).toStringAsFixed(2)} km'
                      : '${totalDistance.toStringAsFixed(1)} m',
                  icon: Icons.straighten,
                  color: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Calorías Totales',
                  value: '${totalCalories.toStringAsFixed(1)} kcal',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFFB923C),
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Vel. Promedio',
                  value: '${avgSpeed.toStringAsFixed(1)} km/h',
                  icon: Icons.speed,
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off,
                  size: 60, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'Aún no tienes entrenamientos guardados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Inicia y finaliza una rutina en la pestaña Entrenamiento para ver aquí tus estadísticas acumuladas y rutas GPS.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAccumulatedStatsCard();
          }
          final item = _sessions[index - 1];
          final speedKmh = _calculateSpeedKmh(item);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor:
                const Color(0xFF0284C7).withValues(alpha: 0.12),
                child: const Icon(
                  Icons.directions_run,
                  color: Color(0xFF0284C7),
                ),
              ),
              title: Text(
                _formatDate(item.date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Duración: ${_formatDuration(item.durationSeconds)} • ${item.steps} pasos • ${item.caloriesBurned.toStringAsFixed(1)} kcal\nDistancia: ${item.distanceMeters.toStringAsFixed(1)} m • Vel: ${speedKmh.toStringAsFixed(1)} km/h • ${item.predominantIntensity}',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, color: Color(0xFF10B981)),
                  const SizedBox(height: 2),
                  Text(
                    '${item.routePoints.length} pts',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onTap: () => _showRouteModal(item),
            ),
          );
        },
      ),
    );
  }
}

class _DetailedRouteSheet extends StatefulWidget {
  final WorkoutSession session;
  final String formattedDate;
  final String formattedDuration;
  final double speedKmh;
  final String paceMinPerKm;

  const _DetailedRouteSheet({
    required this.session,
    required this.formattedDate,
    required this.formattedDuration,
    required this.speedKmh,
    required this.paceMinPerKm,
  });

  @override
  State<_DetailedRouteSheet> createState() => _DetailedRouteSheetState();
}

class _DetailedRouteSheetState extends State<_DetailedRouteSheet> {
  final MapController _detailMapController = MapController();
  HistoryMapStyle _selectedStyle = HistoryMapStyle.standard;

  @override
  void dispose() {
    _detailMapController.dispose();
    super.dispose();
  }

  String _tileUrl(HistoryMapStyle style) {
    switch (style) {
      case HistoryMapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case HistoryMapStyle.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case HistoryMapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _recenterRoute() {
    final points = widget.session.routePoints;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _detailMapController.move(points.first, 16.5);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    if (bounds.north == bounds.south && bounds.east == bounds.west) {
      _detailMapController.move(points.first, 16.5);
      return;
    }
    _detailMapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(36),
      ),
    );
  }

  List<LatLng> _intermediateWaypoints(List<LatLng> points) {
    if (points.length <= 3) return [];
    final List<LatLng> result = [];
    final int step = (points.length / 6).ceil().clamp(1, points.length);
    for (int i = step; i < points.length - 1; i += step) {
      result.add(points[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.session.routePoints;
    final waypoints = _intermediateWaypoints(points);

    CameraFit? initialFit;
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      if (bounds.north != bounds.south || bounds.east != bounds.west) {
        initialFit = CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(36),
        );
      }
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DETALLE DEL RECORRIDO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.formattedDate,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.session.predominantIntensity,
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Selector de estilo de mapa en el historial
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _DetailMapStyleTab(
                          label: 'Estándar',
                          icon: Icons.map_outlined,
                          selected: _selectedStyle == HistoryMapStyle.standard,
                          onTap: () => setState(
                                  () => _selectedStyle = HistoryMapStyle.standard),
                        ),
                        _DetailMapStyleTab(
                          label: 'Satelital',
                          icon: Icons.satellite_alt,
                          selected: _selectedStyle == HistoryMapStyle.satellite,
                          onTap: () => setState(
                                  () => _selectedStyle = HistoryMapStyle.satellite),
                        ),
                        _DetailMapStyleTab(
                          label: 'Relieve',
                          icon: Icons.terrain,
                          selected: _selectedStyle == HistoryMapStyle.terrain,
                          onTap: () => setState(
                                  () => _selectedStyle = HistoryMapStyle.terrain),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mapa ampliado del recorrido
                  if (points.isEmpty)
                    Container(
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'No se registraron coordenadas GPS en esta sesión.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 290,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _detailMapController,
                              options: MapOptions(
                                initialCenter: points.first,
                                initialZoom: 16.5,
                                initialCameraFit: initialFit,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: _tileUrl(_selectedStyle),
                                  userAgentPackageName: 'com.nexpulse.app',
                                ),
                                if (points.length >= 2)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: points,
                                        strokeWidth: 7.5,
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.75),
                                      ),
                                      Polyline(
                                        points: points,
                                        strokeWidth: 4.5,
                                        color: const Color(0xFF38BDF8),
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    // Puntos intermedios del recorrido
                                    ...waypoints.map(
                                          (wp) => Marker(
                                        point: wp,
                                        width: 12,
                                        height: 12,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF0284C7),
                                              width: 2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Punto de Inicio
                                    Marker(
                                      point: points.first,
                                      width: 34,
                                      height: 34,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2.5),
                                        ),
                                        child: const Icon(
                                          Icons.flag,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    // Punto Final
                                    if (points.length >= 2)
                                      Marker(
                                        point: points.last,
                                        width: 34,
                                        height: 34,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 2.5),
                                          ),
                                          child: const Icon(
                                            Icons.sports_score,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: FloatingActionButton.small(
                                heroTag: 'recenter_history_route',
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                onPressed: _recenterRoute,
                                child: const Icon(Icons.fit_screen, size: 19),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Leyenda de Inicio / Fin / Puntos GPS
                  if (points.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag,
                                  color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Inicio: ${points.first.latitude.toStringAsFixed(5)}, ${points.first.longitude.toStringAsFixed(5)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.sports_score,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Fin: ${points.last.latitude.toStringAsFixed(5)}, ${points.last.longitude.toStringAsFixed(5)} (${points.length} puntos)',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Cuadrícula de métricas detalladas de la sesión
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetricTile(
                          label: 'Duración',
                          value: widget.formattedDuration,
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailMetricTile(
                          label: 'Distancia',
                          value: widget.session.distanceMeters >= 1000
                              ? '${(widget.session.distanceMeters / 1000).toStringAsFixed(2)} km'
                              : '${widget.session.distanceMeters.toStringAsFixed(1)} m',
                          icon: Icons.straighten,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetricTile(
                          label: 'Vel. Promedio',
                          value: '${widget.speedKmh.toStringAsFixed(1)} km/h',
                          icon: Icons.speed,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailMetricTile(
                          label: 'Ritmo Promedio',
                          value: widget.paceMinPerKm,
                          icon: Icons.av_timer,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetricTile(
                          label: 'Pasos Totales',
                          value: '${widget.session.steps}',
                          icon: Icons.directions_walk,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailMetricTile(
                          label: 'Calorías',
                          value:
                          '${widget.session.caloriesBurned.toStringAsFixed(1)} kcal',
                          icon: Icons.local_fire_department,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMapStyleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DetailMapStyleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0284C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
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

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}