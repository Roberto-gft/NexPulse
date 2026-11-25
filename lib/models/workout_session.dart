import 'dart:convert';
import 'package:latlong2/latlong.dart';

class WorkoutSession {
  final String id;
  final DateTime date;
  final int durationSeconds;
  final int steps;
  final double distanceMeters;
  final double caloriesBurned;
  final String predominantIntensity;
  final List<LatLng> routePoints;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.steps,
    required this.distanceMeters,
    required this.caloriesBurned,
    required this.predominantIntensity,
    required this.routePoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'steps': steps,
      'distanceMeters': distanceMeters,
      'caloriesBurned': caloriesBurned,
      'predominantIntensity': predominantIntensity,
      'routePoints': routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final rawPoints = (map['routePoints'] as List<dynamic>? ?? []);
    return WorkoutSession(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']),
      durationSeconds: map['durationSeconds'] ?? 0,
      steps: map['steps'] ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      predominantIntensity: map['predominantIntensity'] ?? 'Descanso',
      routePoints: rawPoints
          .map((p) => LatLng(
        (p['lat'] as num).toDouble(),
        (p['lng'] as num).toDouble(),
      ))
          .toList(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkoutSession.fromJson(String source) =>
      WorkoutSession.fromMap(jsonDecode(source) as Map<String, dynamic>);
}