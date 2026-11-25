import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/user_model.dart';
import '../models/workout_session.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';

enum _MapLayerStyle { standard, satellite, terrain }

class _MovementActivity {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MovementActivity({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class TrackerTab extends StatefulWidget {
  final bool isActiveTab;

  const TrackerTab({super.key, this.isActiveTab = true});

  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final StorageService _storage = StorageService();

  static const LatLng _defaultCenter = LatLng(20.1169, -98.7333);

  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [];
  _MapLayerStyle _mapStyle = _MapLayerStyle.standard;
  bool _isMapReady = false;
  bool _followUser = true;

  // Estado de GPS y sensores
  bool _gpsLocked = false;
  String _gpsStatusText = 'Buscando GPS...';
  double _currentSpeedKmh = 0.0;
  bool _pedometerReady = false;
  bool _accelReady = false;
  bool _gyroReady = false;

  // Estado del entrenamiento y conteo híbrido instantáneo
  bool _isTracking = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  int? _lastHardwareSteps;
  int? _initialPedometerSteps;
  int _hardwareSessionSteps = 0;
  int _realtimeAccelSteps = 0;
  int _sessionSteps = 0;
  double _distanceMeters = 0.0;
  double _caloriesBurned = 0.0;

  // Filtro de pasos instantáneo por acelerómetro
  double _gravityEstimate = 9.81;
  bool _stepPeakArmed = true;
  DateTime _lastStepTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  // Telemetría de precisión: Acelerómetro (X, Y, Z, Magnitud neta, Pico)
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;
  double _accelMagnitude = 0.0;
  double _smoothedAccel = 0.0;
  double _peakAccel = 0.0;

  // Telemetría de precisión: Giroscopio (X, Y, Z, Velocidad angular)
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;
  double _gyroMagnitude = 0.0;

  DateTime _lastAccelUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastGyroUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  UserModel? _user;

  Timer? _workoutTimer;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAthleteProfile();
    _startMotionSensors();
    _startPedometerStream();
    _bootstrapSensorsAndGps();
  }

  @override
  void didUpdateWidget(covariant TrackerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab) {
      _bootstrapSensorsAndGps(silentDialog: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workoutTimer?.cancel();
    _positionSub?.cancel();
    _stepSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startMotionSensors();
      _startPedometerStream();
      _bootstrapSensorsAndGps(silentDialog: true);
    }
  }

  Future<void> _loadAthleteProfile() async {
    final user = await _storage.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _bootstrapSensorsAndGps({bool silentDialog = false}) async {
    bool ready;
    if (silentDialog) {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      final perm = await Geolocator.checkPermission();
      ready = serviceOn &&
          (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse);
    } else {
      ready = await PermissionService.ensureHardwareAndPermissionsReady(context);
    }

    if (!mounted) return;

    if (!ready) {
      setState(() {
        _gpsLocked = false;
        _gpsStatusText = 'GPS Apagado (Toca aquí)';
      });
      return;
    }

    _startMotionSensors();
    _startPedometerStream();
    await _startGpsStream();
  }

  Future<void> _startGpsStream() async {
    setState(() {
      if (!_gpsLocked) _gpsStatusText = 'Conectando satélites...';
    });

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final pos = LatLng(lastKnown.latitude, lastKnown.longitude);
        setState(() {
          _currentPosition = pos;
          _gpsLocked = true;
          _gpsStatusText = 'GPS Activo';
        });
        if (_isMapReady && _followUser) {
          _mapController.move(pos, 17.0);
        }
      }
    } catch (_) {}

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 7));
      _onNewPosition(current);
    } catch (_) {
      try {
        final fallback = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: true,
          ),
        ).timeout(const Duration(seconds: 7));
        _onNewPosition(fallback);
      } catch (_) {
        if (mounted && !_gpsLocked) {
          setState(() => _gpsStatusText = 'Buscando señal GPS...');
        }
      }
    }

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        intervalDuration: const Duration(seconds: 2),
      ),
    ).listen(
      _onNewPosition,
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _gpsLocked = false;
          _gpsStatusText = 'Sin señal GPS';
        });
      },
    );
  }

  void _onNewPosition(Position position) {
    if (!mounted) return;
    final newPoint = LatLng(position.latitude, position.longitude);
    final speedKmh = position.speed >= 0 ? (position.speed * 3.6) : 0.0;

    setState(() {
      _gpsLocked = true;
      _gpsStatusText = 'GPS Activo';
      _currentSpeedKmh = speedKmh < 0.4 ? 0.0 : speedKmh;

      if (_isTracking && !_isPaused) {
        if (_routePoints.isNotEmpty) {
          final prev = _routePoints.last;
          final segmentMeters = Geolocator.distanceBetween(
            prev.latitude,
            prev.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
          if (segmentMeters >= 1.5 && segmentMeters <= 80.0) {
            _distanceMeters += segmentMeters;
            _routePoints.add(newPoint);
          }
        } else {
          _routePoints.add(newPoint);
        }
        _recalculateCalories();
      }

      _currentPosition = newPoint;
    });

    if (_isMapReady && _followUser) {
      _mapController.move(newPoint, 17.0);
    }
  }

  void _startPedometerStream() {
    _stepSub?.cancel();
    _stepSub = Pedometer.stepCountStream.listen(
          (StepCount event) {
        if (!mounted) return;
        _lastHardwareSteps = event.steps;

        setState(() {
          _pedometerReady = true;
          if (_isTracking && !_isPaused) {
            _initialPedometerSteps ??= event.steps;
            final delta = event.steps - _initialPedometerSteps!;
            if (delta >= 0) {
              _hardwareSessionSteps = delta;
              if (_hardwareSessionSteps > _realtimeAccelSteps) {
                _realtimeAccelSteps = _hardwareSessionSteps;
              }
              _sessionSteps =
                  math.max(_hardwareSessionSteps, _realtimeAccelSteps);
              _syncDistanceFromStepsIfNoGpsMovement();
              _recalculateCalories();
            }
          } else if (!_isTracking) {
            _initialPedometerSteps = event.steps;
          }
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _pedometerReady = false);
      },
    );
  }

  void _startMotionSensors() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
          (AccelerometerEvent event) {
        if (!mounted) return;
        final magnitude = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        // Filtro pasa-altos para aislar cada pisada sin depender de la inclinación
        _gravityEstimate = (0.90 * _gravityEstimate) + (0.10 * magnitude);
        final stepWave = magnitude - _gravityEstimate;
        final dynamicAccel = stepWave.abs();
        _smoothedAccel = (_smoothedAccel * 0.78) + (dynamicAccel * 0.22);

        bool stepDetectedNow = false;
        if (_isTracking && !_isPaused) {
          final now = DateTime.now();
          if (_stepPeakArmed &&
              stepWave > 1.55 &&
              now.difference(_lastStepTimestamp).inMilliseconds >= 280) {
            _stepPeakArmed = false;
            _lastStepTimestamp = now;
            _realtimeAccelSteps += 1;
            _sessionSteps =
                math.max(_hardwareSessionSteps, _realtimeAccelSteps);
            _syncDistanceFromStepsIfNoGpsMovement();
            _recalculateCalories();
            stepDetectedNow = true;
          } else if (!_stepPeakArmed && stepWave < 0.55) {
            _stepPeakArmed = true;
          }
        }

        final now = DateTime.now();
        if (stepDetectedNow ||
            now.difference(_lastAccelUiUpdate).inMilliseconds >= 180) {
          _lastAccelUiUpdate = now;
          setState(() {
            _accelReady = true;
            _accelX = event.x;
            _accelY = event.y;
            _accelZ = event.z;
            _accelMagnitude = dynamicAccel;
            if (dynamicAccel > _peakAccel) {
              _peakAccel = dynamicAccel;
            }
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _accelReady = false);
      },
    );

    _gyroSub?.cancel();
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
          (GyroscopeEvent event) {
        if (!mounted) return;
        final rot = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        final now = DateTime.now();
        if (now.difference(_lastGyroUiUpdate).inMilliseconds >= 200) {
          _lastGyroUiUpdate = now;
          setState(() {
            _gyroReady = true;
            _gyroX = event.x;
            _gyroY = event.y;
            _gyroZ = event.z;
            _gyroMagnitude = rot;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _gyroReady = false);
      },
    );
  }

  _MovementActivity _detectMovementActivity() {
    if (_smoothedAccel >= 4.2 || _currentSpeedKmh >= 9.0) {
      return const _MovementActivity(
        label: 'Corriendo',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEA580C),
        bgColor: Color(0xFFFFEDD5),
      );
    }
    if (_smoothedAccel >= 1.9 || _currentSpeedKmh >= 5.2) {
      return const _MovementActivity(
        label: 'Trotando',
        icon: Icons.directions_run_rounded,
        color: Color(0xFF4D7C0F),
        bgColor: Color(0xFFECFCCB),
      );
    }
    if (_smoothedAccel >= 0.55 || _currentSpeedKmh >= 1.2) {
      return const _MovementActivity(
        label: 'Caminando',
        icon: Icons.directions_walk_rounded,
        color: Color(0xFF0284C7),
        bgColor: Color(0xFFE0F2FE),
      );
    }
    return const _MovementActivity(
      label: 'En reposo',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF475569),
      bgColor: Color(0xFFF1F5F9),
    );
  }

  void _syncDistanceFromStepsIfNoGpsMovement() {
    final stride = _user?.strideLengthMeters ?? 0.74;
    final stepDistance = _sessionSteps * stride;
    if (stepDistance > _distanceMeters) {
      _distanceMeters = stepDistance;
    }
  }

  void _recalculateCalories() {
    final weight = _user?.weightKg ?? 70.0;
    final km = _distanceMeters / 1000.0;
    _caloriesBurned = km * weight * 0.95;
  }

  String _calculatePredominantIntensity() {
    if (_smoothedAccel >= 4.2 || _currentSpeedKmh >= 9.0) {
      return 'Alta';
    }
    if (_smoothedAccel >= 1.9 || _currentSpeedKmh >= 5.2) {
      return 'Moderada';
    }
    return 'Ligera';
  }

  void _startWorkout() async {
    final ready = await PermissionService.ensureHardwareAndPermissionsReady(
      context,
    );
    if (!ready || !mounted) return;

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _hardwareSessionSteps = 0;
      _realtimeAccelSteps = 0;
      _sessionSteps = 0;
      _distanceMeters = 0.0;
      _caloriesBurned = 0.0;
      _peakAccel = 0.0;
      _stepPeakArmed = true;
      // Fija de inmediato la referencia base del podómetro sin esperar 15 s
      _initialPedometerSteps = _lastHardwareSteps;
      _routePoints.clear();
      if (_currentPosition != null) {
        _routePoints.add(_currentPosition!);
      }
      _followUser = true;
    });

    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTracking || _isPaused) return;
      setState(() => _elapsedSeconds += 1);
    });
  }

  void _togglePauseWorkout() {
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _stepPeakArmed = true;
        if (_lastHardwareSteps != null) {
          _initialPedometerSteps = _lastHardwareSteps! - _hardwareSessionSteps;
        }
      }
    });
  }

  Future<void> _finishAndSaveWorkout() async {
    _workoutTimer?.cancel();

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      durationSeconds: _elapsedSeconds,
      steps: _sessionSteps,
      distanceMeters: _distanceMeters,
      caloriesBurned: _caloriesBurned,
      predominantIntensity: _calculatePredominantIntensity(),
      routePoints: List<LatLng>.from(_routePoints),
    );

    await _storage.saveWorkout(session);

    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _isPaused = false;
      _elapsedSeconds = 0;
      _hardwareSessionSteps = 0;
      _realtimeAccelSteps = 0;
      _sessionSteps = 0;
      _distanceMeters = 0.0;
      _caloriesBurned = 0.0;
      _peakAccel = 0.0;
      _routePoints.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrenamiento guardado en tu Historial deportivo.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(1)} m';
  }

  String _tileUrlForStyle() {
    switch (_mapStyle) {
      case _MapLayerStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case _MapLayerStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case _MapLayerStyle.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? _defaultCenter;
    final activity = _detectMovementActivity();

    return Stack(
      children: [
        // 1. MAPA A PANTALLA COMPLETA
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16.5,
            onMapReady: () {
              _isMapReady = true;
              if (_currentPosition != null) {
                _mapController.move(_currentPosition!, 17.0);
              }
            },
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _followUser) {
                setState(() => _followUser = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrlForStyle(),
              userAgentPackageName: 'com.nexpulse.app',
            ),
            if (_routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.5,
                    color: const Color(0xFFF97316),
                  ),
                ],
              ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // 2. CÁPSULAS FLOTANTES SUPERIORES
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0F17),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'NEXPULSE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0B0F17),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _bootstrapSensorsAndGps(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _gpsLocked
                                    ? Icons.gps_fixed_rounded
                                    : Icons.gps_not_fixed_rounded,
                                size: 16,
                                color: _gpsLocked
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF97316),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _gpsStatusText,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B0F17),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_currentSpeedKmh.toStringAsFixed(1)} km/h',
                                  style: const TextStyle(
                                    color: Color(0xFFBEF264),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white.withValues(alpha: 0.96),
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          setState(() => _followUser = true);
                          await _bootstrapSensorsAndGps();
                          if (_currentPosition != null && _isMapReady) {
                            _mapController.move(_currentPosition!, 17.2);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Icon(
                            Icons.my_location_rounded,
                            size: 20,
                            color: _followUser
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _LayerChip(
                        icon: Icons.map_outlined,
                        label: 'Estándar',
                        selected: _mapStyle == _MapLayerStyle.standard,
                        onTap: () =>
                            setState(() => _mapStyle = _MapLayerStyle.standard),
                      ),
                      _LayerChip(
                        icon: Icons.satellite_alt_rounded,
                        label: 'Satelital',
                        selected: _mapStyle == _MapLayerStyle.satellite,
                        onTap: () => setState(
                                () => _mapStyle = _MapLayerStyle.satellite),
                      ),
                      _LayerChip(
                        icon: Icons.terrain_rounded,
                        label: 'Relieve',
                        selected: _mapStyle == _MapLayerStyle.terrain,
                        onTap: () =>
                            setState(() => _mapStyle = _MapLayerStyle.terrain),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. PANEL INFERIOR DESLIZABLE CON TELEMETRÍA DE ALTA PRECISIÓN
        DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.78,
          snap: true,
          snapSizes: const [0.25, 0.45, 0.78],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Desliza arriba para telemetría de ejes X, Y, Z',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // TARJETA PRINCIPAL DE CRONÓMETRO Y CONTROLES
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F17),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ENTRENAMIENTO EN VIVO',
                              style: TextStyle(
                                color: Color(0xFFBEF264),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isTracking
                                    ? (_isPaused
                                    ? const Color(0xFFF97316)
                                    .withValues(alpha: 0.22)
                                    : const Color(0xFF10B981)
                                    .withValues(alpha: 0.22))
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isTracking
                                    ? (_isPaused ? 'Pausado' : 'En Curso')
                                    : 'En Espera',
                                style: TextStyle(
                                  color: _isTracking
                                      ? (_isPaused
                                      ? const Color(0xFFFB923C)
                                      : const Color(0xFF34D399))
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_isTracking)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _startWorkout,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text(
                                'Iniciar Entrenamiento',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _togglePauseWorkout,
                                  icon: Icon(
                                    _isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                  ),
                                  label: Text(
                                    _isPaused ? 'Reanudar' : 'Pausar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF97316),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _finishAndSaveWorkout,
                                  icon: const Icon(Icons.stop_rounded),
                                  label: const Text(
                                    'Finalizar',
                                    style:
                                    TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFBEF264),
                                    foregroundColor: const Color(0xFF0B0F17),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // FILA 1: PASOS, DISTANCIA Y CALORÍAS
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBox(
                          icon: Icons.directions_walk_rounded,
                          iconColor: const Color(0xFF0284C7),
                          label: (_pedometerReady || _accelReady)
                              ? 'Pasos (Listo)'
                              : 'Pasos',
                          value: '$_sessionSteps',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricBox(
                          icon: Icons.straighten_rounded,
                          iconColor: const Color(0xFF10B981),
                          label: 'Distancia',
                          value: _formatDistance(_distanceMeters),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricBox(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFF97316),
                          label: 'Calorías',
                          value: '${_caloriesBurned.toStringAsFixed(1)} kcal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // FILA 2: RESUMEN RÁPIDO CON DETECTOR DE ACCIÓN EN ACELERÓMETRO
                  Row(
                    children: [
                      Expanded(
                        child: _SensorSummaryCard(
                          icon: activity.icon,
                          accentColor: activity.color,
                          badgeBg: activity.bgColor,
                          title: 'Acelerómetro',
                          value: '${_accelMagnitude.toStringAsFixed(2)} m/s²',
                          actionLabel: activity.label,
                          isReady: _accelReady,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SensorSummaryCard(
                          icon: Icons.screen_rotation_alt_rounded,
                          accentColor: const Color(0xFF0284C7),
                          badgeBg: const Color(0xFFE0F2FE),
                          title: 'Giroscopio',
                          value: '${_gyroMagnitude.toStringAsFixed(2)} rad/s',
                          actionLabel: _gyroReady
                              ? (_gyroMagnitude > 0.6
                              ? 'Giro activo'
                              : 'Estable')
                              : 'Iniciando...',
                          isReady: _gyroReady,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECCIÓN EXPANDIDA: PRECISIÓN POR EJES X, Y, Z
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics_outlined,
                                    size: 18, color: Color(0xFF0B0F17)),
                                SizedBox(width: 6),
                                Text(
                                  'TELEMETRÍA DE PRECISIÓN',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0B0F17),
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: activity.bgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(activity.icon,
                                      size: 13, color: activity.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: activity.color,
                                    ),
                                  ),
                                ],
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                            Text(
                              'Pico: ${_peakAccel.toStringAsFixed(2)} m/s²',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _AxisTile(
                                axis: 'Eje X',
                                value: _accelX.toStringAsFixed(2),
                                unit: 'm/s²',
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _AxisTile(
                                axis: 'Eje Y',
                                value: _accelY.toStringAsFixed(2),
                                unit: 'm/s²',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _AxisTile(
                                axis: 'Eje Z',
                                value: _accelZ.toStringAsFixed(2),
                                unit: 'm/s²',
                                color: const Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_smoothedAccel / 6.5).clamp(0.05, 1.0),
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(activity.color),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reposo',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                            Text('Caminando',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                            Text('Trotando',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                            Text('Corriendo',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Giroscopio (rad/s)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                            Text(
                              'Total: ${_gyroMagnitude.toStringAsFixed(3)} rad/s',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _AxisTile(
                                axis: 'Pitch (X)',
                                value: _gyroX.toStringAsFixed(3),
                                unit: 'rad/s',
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _AxisTile(
                                axis: 'Roll (Y)',
                                value: _gyroY.toStringAsFixed(3),
                                unit: 'rad/s',
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _AxisTile(
                                axis: 'Yaw (Z)',
                                value: _gyroZ.toStringAsFixed(3),
                                unit: 'rad/s',
                                color: const Color(0xFF059669),
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
    );
  }
}

class _LayerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LayerChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0B0F17) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? const Color(0xFFBEF264)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final Color badgeBg;
  final String title;
  final String value;
  final String actionLabel;
  final bool isReady;

  const _SensorSummaryCard({
    required this.icon,
    required this.accentColor,
    required this.badgeBg,
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isReady ? badgeBg : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    actionLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isReady ? accentColor : const Color(0xFFD97706),
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
  final String axis;
  final String value;
  final String unit;
  final Color color;

  const _AxisTile({
    required this.axis,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            axis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}