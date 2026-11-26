import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MapLayerType { standard, satellite, terrain }

class GpsCoord {
  final double lat;
  final double lng;

  const GpsCoord({required this.lat, required this.lng});

  Map<String, double> toJson() => {'lat': lat, 'lng': lng};
}

class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});

  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  final MapController _mapController = MapController();

  bool _isTracking = false;
  DateTime? _startTime;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

  MapLayerType _selectedLayer = MapLayerType.standard;
  LatLng _currentCenter = const LatLng(20.2236, -99.0928);
  double _currentSpeedKmh = 0.0;
  double _maxSpeedKmh = 0.0;
  double _totalDistanceMeters = 0.0;
  final List<LatLng> _routePoints = [];

  int _steps = 0;
  int? _initialHardwareSteps;
  double _calories = 0.0;

  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;
  double _accelMagnitude = 0.0;
  double _peakAccel = 0.0;

  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;
  double _gyroTotal = 0.0;

  String _activityStatus = 'En espera';
  String _dominantActivity = 'Caminata';
  int _walkSamples = 0;
  int _jogSamples = 0;
  int _runSamples = 0;
  DateTime? _lastStepPeakTime;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<StepCount>? _stepSub;

  @override
  void initState() {
    super.initState();
    _initInitialLocationOnly();
  }

  Future<void> _initInitialLocationOnly() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentCenter = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentCenter, 16.0);
    } catch (_) {}
  }

  void _toggleWorkout() {
    if (_isTracking) {
      _stopWorkout();
    } else {
      _startWorkout();
    }
  }

  void _startWorkout() {
    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
      _steps = 0;
      _initialHardwareSteps = null;
      _totalDistanceMeters = 0.0;
      _calories = 0.0;
      _peakAccel = 0.0;
      _currentSpeedKmh = 0.0;
      _maxSpeedKmh = 0.0;
      _walkSamples = 0;
      _jogSamples = 0;
      _runSamples = 0;
      _dominantActivity = 'Caminata';
      _routePoints.clear();
      _routePoints.add(_currentCenter);
      _activityStatus = 'Reposo';
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTracking || _startTime == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position pos) {
      if (!mounted || !_isTracking) return;
      final newPoint = LatLng(pos.latitude, pos.longitude);
      double addedDist = 0.0;
      if (_routePoints.isNotEmpty) {
        addedDist = Geolocator.distanceBetween(
          _routePoints.last.latitude,
          _routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
      }
      final speedKmh = max(0.0, pos.speed * 3.6);
      setState(() {
        _currentCenter = newPoint;
        _currentSpeedKmh = speedKmh;
        if (speedKmh > _maxSpeedKmh) {
          _maxSpeedKmh = speedKmh;
        }
        if (addedDist >= 1.0 && addedDist < 120) {
          _totalDistanceMeters += addedDist;
          _routePoints.add(newPoint);
        }
      });
      _mapController.move(newPoint, _mapController.camera.zoom);
    });

    _accelSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((UserAccelerometerEvent event) {
      if (!mounted || !_isTracking) return;
      final mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      String status = 'Reposo';
      if (mag >= 8.5) {
        status = 'Corriendo';
        _runSamples++;
      } else if (mag >= 4.2) {
        status = 'Trotando';
        _jogSamples++;
      } else if (mag >= 1.35) {
        status = 'Caminando';
        _walkSamples++;
      }

      if (_runSamples >= _jogSamples &&
          _runSamples >= _walkSamples &&
          _runSamples > 0) {
        _dominantActivity = 'Carrera';
      } else if (_jogSamples >= _walkSamples && _jogSamples > 0) {
        _dominantActivity = 'Trote';
      } else {
        _dominantActivity = 'Caminata';
      }

      if (mag > 1.85) {
        final now = DateTime.now();
        if (_lastStepPeakTime == null ||
            now.difference(_lastStepPeakTime!).inMilliseconds > 330) {
          _lastStepPeakTime = now;
          _steps += 1;
          _calories = _steps * 0.045;
          if (_routePoints.length <= 1) {
            _totalDistanceMeters += 0.75;
          }
        }
      }

      setState(() {
        _accelX = event.x;
        _accelY = event.y;
        _accelZ = event.z;
        _accelMagnitude = mag;
        if (mag > _peakAccel) {
          _peakAccel = mag;
        }
        _activityStatus = status;
      });
    });

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((GyroscopeEvent event) {
      if (!mounted || !_isTracking) return;
      final total = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
        _gyroTotal = total;
      });
    });

    _stepSub = Pedometer.stepCountStream.listen(
          (StepCount event) {
        if (!mounted || !_isTracking) return;
        _initialHardwareSteps ??= event.steps;
        final hwSteps = event.steps - _initialHardwareSteps!;
        if (hwSteps > _steps) {
          setState(() {
            _steps = hwSteps;
            _calories = _steps * 0.045;
          });
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _stopWorkout() async {
    _durationTimer?.cancel();
    await _positionSub?.cancel();
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _stepSub?.cancel();

    final savedSteps = _steps;
    final savedDistance = _totalDistanceMeters;
    final savedCalories = _calories > 0
        ? _calories
        : max(0.2, _elapsed.inSeconds * 0.05);
    final savedDuration = max(1, _elapsed.inSeconds);
    final savedPeakAccel = _peakAccel;
    final savedGyroTotal = _gyroTotal;
    final savedMaxSpeed = _maxSpeedKmh;
    final savedActivity = _dominantActivity;
    final List<GpsCoord> savedRoute = _routePoints
        .map((p) => GpsCoord(lat: p.latitude, lng: p.longitude))
        .toList();

    if (savedRoute.isEmpty) {
      savedRoute.add(
        GpsCoord(
          lat: _currentCenter.latitude,
          lng: _currentCenter.longitude,
        ),
      );
    }

    await _saveWorkoutToHistory(
      steps: savedSteps,
      distanceMeters: savedDistance,
      calories: savedCalories,
      durationSeconds: savedDuration,
      peakAccel: savedPeakAccel,
      gyroTotal: savedGyroTotal,
      maxSpeedKmh: savedMaxSpeed,
      activityType: savedActivity,
      route: savedRoute,
    );

    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _elapsed = Duration.zero;
      _currentSpeedKmh = 0.0;
      _maxSpeedKmh = 0.0;
      _steps = 0;
      _totalDistanceMeters = 0.0;
      _calories = 0.0;
      _accelX = 0.0;
      _accelY = 0.0;
      _accelZ = 0.0;
      _accelMagnitude = 0.0;
      _peakAccel = 0.0;
      _gyroX = 0.0;
      _gyroY = 0.0;
      _gyroZ = 0.0;
      _gyroTotal = 0.0;
      _activityStatus = 'En espera';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorrido guardado en Historial ($savedSteps pasos · ${savedCalories.toStringAsFixed(1)} kcal)',
          ),
          backgroundColor: const Color(0xFF2E9E6B),
        ),
      );
    }
  }

  Future<void> _saveWorkoutToHistory({
    required int steps,
    required double distanceMeters,
    required double calories,
    required int durationSeconds,
    required double peakAccel,
    required double gyroTotal,
    required double maxSpeedKmh,
    required String activityType,
    required List<GpsCoord> route,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('workout_history') ?? [];
    final double avgSpeed = durationSeconds > 0
        ? (distanceMeters / durationSeconds) * 3.6
        : 0.0;

    final record = jsonEncode({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateTime.now().toIso8601String(),
      'steps': steps,
      'distance': distanceMeters,
      'calories': calories,
      'duration': durationSeconds,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeedKmh,
      'peakAccel': peakAccel,
      'gyroTotal': gyroTotal,
      'activityType': activityType,
      'route': route.map((p) => p.toJson()).toList(),
    });
    existing.insert(0, record);
    await prefs.setStringList('workout_history', existing);
  }

  String _getTileUrl() {
    switch (_selectedLayer) {
      case MapLayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapLayerType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  double _activityProgress() {
    if (!_isTracking) return 0.0;
    return (_accelMagnitude / 10.0).clamp(0.05, 1.0);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _positionSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF182226) : Colors.white;
    final sheetBg = isDark ? const Color(0xFF0E1416) : const Color(0xFFF6F8FA);
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(),
                userAgentPackageName: 'com.nexpulse.app',
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF2E9E6B),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E9E6B).withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E6B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF102A2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NP',
                                style: TextStyle(
                                  color: Color(0xFF4CE0A3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NEXPULSE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 15,
                                color: _isTracking
                                    ? const Color(0xFF2E9E6B)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _isTracking ? 'Activo' : 'Listo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF102A2E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_currentSpeedKmh.toStringAsFixed(1)} km/h',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: cardBg,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.my_location,
                            size: 20,
                            color: primaryText,
                          ),
                          onPressed: () {
                            _mapController.move(_currentCenter, 16.5);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildLayerChip(
                          label: 'Estándar',
                          icon: Icons.map_outlined,
                          type: MapLayerType.standard,
                          isDark: isDark,
                        ),
                        _buildLayerChip(
                          label: 'Satelital',
                          icon: Icons.satellite_alt,
                          type: MapLayerType.satellite,
                          isDark: isDark,
                        ),
                        _buildLayerChip(
                          label: 'Relieve',
                          icon: Icons.terrain,
                          type: MapLayerType.terrain,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.34,
            maxChildSize: 0.86,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 14,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _toggleWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTracking
                              ? const Color(0xFFD9383A)
                              : const Color(0xFF42A87C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(
                          _isTracking ? Icons.stop : Icons.play_arrow,
                          size: 26,
                        ),
                        label: Text(
                          _isTracking
                              ? 'Detener y Guardar (${_formatDuration(_elapsed)})'
                              : 'Iniciar Entrenamiento',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.directions_walk,
                            iconColor: Colors.blue,
                            title: _isTracking ? 'Pasos (Activo)' : 'Pasos',
                            value: '$_steps',
                            cardBg: cardBg,
                            borderCol: borderCol,
                            subText: subText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.straighten,
                            iconColor: Colors.teal,
                            title: 'Distancia',
                            value: _totalDistanceMeters >= 1000
                                ? '${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km'
                                : '${_totalDistanceMeters.toStringAsFixed(1)} m',
                            cardBg: cardBg,
                            borderCol: borderCol,
                            subText: subText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.local_fire_department,
                            iconColor: Colors.deepOrange,
                            title: 'Calorías',
                            value: '${_calories.toStringAsFixed(1)} kcal',
                            cardBg: cardBg,
                            borderCol: borderCol,
                            subText: subText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SensorSummaryCard(
                            icon: Icons.directions_run,
                            iconColor: Colors.indigoAccent,
                            title: 'Acelerómetro',
                            value: '${_accelMagnitude.toStringAsFixed(2)} m/s²',
                            badge: _isTracking ? _activityStatus : 'En espera',
                            badgeColor: _isTracking
                                ? Colors.blue.withValues(alpha: 0.16)
                                : (isDark
                                ? Colors.white10
                                : Colors.grey.shade200),
                            badgeTextColor:
                            _isTracking ? Colors.blueAccent : subText,
                            cardBg: cardBg,
                            borderCol: borderCol,
                            subText: subText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SensorSummaryCard(
                            icon: Icons.sync,
                            iconColor: Colors.cyan,
                            title: 'Giroscopio',
                            value: '${_gyroTotal.toStringAsFixed(2)} rad/s',
                            badge: _isTracking
                                ? (_gyroTotal > 0.5 ? 'En giro' : 'Estable')
                                : 'Pausado',
                            badgeColor: _isTracking
                                ? Colors.teal.withValues(alpha: 0.16)
                                : (isDark
                                ? Colors.white10
                                : Colors.grey.shade200),
                            badgeTextColor: _isTracking
                                ? const Color(0xFF4CE0A3)
                                : subText,
                            cardBg: cardBg,
                            borderCol: borderCol,
                            subText: subText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.analytics_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'TELEMETRÍA DE PRECISIÓN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isTracking
                                      ? Colors.blue.withValues(alpha: 0.16)
                                      : (isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _isTracking ? _activityStatus : 'Pausado',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _isTracking
                                        ? Colors.blueAccent
                                        : subText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Acelerómetro (m/s²)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Pico: ${_peakAccel.toStringAsFixed(2)} m/s²',
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _AxisTile(
                                  label: 'Eje X',
                                  value: _accelX.toStringAsFixed(2),
                                  unit: 'm/s²',
                                  tileBg: sheetBg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AxisTile(
                                  label: 'Eje Y',
                                  value: _accelY.toStringAsFixed(2),
                                  unit: 'm/s²',
                                  tileBg: sheetBg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AxisTile(
                                  label: 'Eje Z',
                                  value: _accelZ.toStringAsFixed(2),
                                  unit: 'm/s²',
                                  tileBg: sheetBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _activityProgress(),
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E9E6B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reposo',
                                style:
                                TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'Caminando',
                                style:
                                TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'Trotando',
                                style:
                                TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'Corriendo',
                                style:
                                TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Giroscopio (rad/s)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Total: ${_gyroTotal.toStringAsFixed(3)} rad/s',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _AxisTile(
                                  label: 'Pitch (X)',
                                  value: _gyroX.toStringAsFixed(3),
                                  unit: 'rad/s',
                                  tileBg: sheetBg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AxisTile(
                                  label: 'Roll (Y)',
                                  value: _gyroY.toStringAsFixed(3),
                                  unit: 'rad/s',
                                  tileBg: sheetBg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AxisTile(
                                  label: 'Yaw (Z)',
                                  value: _gyroZ.toStringAsFixed(3),
                                  unit: 'rad/s',
                                  tileBg: sheetBg,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayerChip({
    required String label,
    required IconData icon,
    required MapLayerType type,
    required bool isDark,
  }) {
    final isSelected = _selectedLayer == type;
    final unselectedColor = isDark ? Colors.white70 : Colors.black87;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLayer = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF102A2E) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF4CE0A3) : unselectedColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color cardBg;
  final Color borderCol;
  final Color subText;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.cardBg,
    required this.borderCol,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: subText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SensorSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color cardBg;
  final Color borderCol;
  final Color subText;

  const _SensorSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.cardBg,
    required this.borderCol,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: subText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
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

class _AxisTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color tileBg;

  const _AxisTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.tileBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}