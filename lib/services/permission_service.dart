import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/privacy_policy_screen.dart';

class PermissionService {
  static Future<bool> requestTrackingPermissions(
      BuildContext context, {
        bool forceDialog = false,
      }) async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final activityStatus = await Permission.activityRecognition.status;
    final sensorsStatus = await Permission.sensors.status;

    if (!forceDialog &&
        locationStatus.isGranted &&
        activityStatus.isGranted &&
        (sensorsStatus.isGranted || sensorsStatus.isRestricted)) {
      return true;
    }

    if (!context.mounted) return false;

    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          title: const Row(
            children: [
              Icon(Icons.sensors, color: Color(0xFFBEF264), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Activar Sensores Deportivos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para medir tus rutas, pasos y movimiento en cualquier dispositivo, autoriza el acceso a todos los sensores:',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const _PermissionRow(
                icon: Icons.location_on,
                iconColor: Color(0xFF34D399),
                title: 'Ubicación GPS Precisa',
                subtitle: 'Trazar tu ruta y velocidad exacta en el mapa.',
              ),
              const SizedBox(height: 12),
              const _PermissionRow(
                icon: Icons.directions_walk,
                iconColor: Color(0xFFBEF264),
                title: 'Podómetro y Actividad Física',
                subtitle: 'Contar tus pasos en tiempo real.',
              ),
              const SizedBox(height: 12),
              const _PermissionRow(
                icon: Icons.screen_rotation_alt,
                iconColor: Color(0xFFF97316),
                title: 'Acelerómetro y Giroscopio',
                subtitle: 'Detectar ritmo e intensidad de carrera.',
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Leer Política de Privacidad completa →',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Omitir',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBEF264),
                foregroundColor: const Color(0xFF0B0F17),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Permitir Todo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (accepted != true) return false;

    final statuses = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    final locGranted =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    final actGranted =
        statuses[Permission.activityRecognition]?.isGranted ?? false;

    return locGranted && actGranted;
  }

  /// Verifica tanto los permisos como los interruptores físicos del Panel de Control
  /// en cualquier marca de teléfono (Samsung, Xiaomi, Motorola, etc.).
  static Future<bool> ensureHardwareAndPermissionsReady(
      BuildContext context,
      ) async {
    // 1. Verificar si el interruptor maestro de Ubicación del teléfono está encendido
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      final bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Color(0xFFF97316)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ubicación Desactivada',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'El interruptor de Ubicación o Sensores está apagado en el panel de control de tu teléfono. Actívalo para mostrar tu posición en el mapa.',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBEF264),
                foregroundColor: const Color(0xFF0B0F17),
              ),
              child: const Text(
                'Encender Ubicación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    // 2. Solicitar permisos de ubicación, actividad física y sensores
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    final locStatus = statuses[Permission.locationWhenInUse];
    if (locStatus == null || !locStatus.isGranted) {
      if (locStatus != null && locStatus.isPermanentlyDenied && context.mounted) {
        await openAppSettings();
      }
      return false;
    }

    // 3. Verificar que en Samsung / Android 12+ esté activa la ubicación PRECISA
    final accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy == LocationAccuracyStatus.reduced && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Activa "Ubicación precisa" en los permisos para rastrear tu ruta.',
          ),
          action: SnackBarAction(
            label: 'Ajustes',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }

    return true;
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _PermissionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: subtitle,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}