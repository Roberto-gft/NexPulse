import 'package:flutter/material.dart';
import '../widgets/swipe_back_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Regresar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Política de Privacidad y Uso',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user,
                          color: Color(0xFF38BDF8), size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compromiso de Privacidad NexPulse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Al utilizar NexPulse aceptas el tratamiento local de tus datos biométricos y de telemetría física bajo los siguientes lineamientos de transparencia y seguridad.',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _PolicySectionCard(
              icon: Icons.sensors,
              title: '1. Datos y Sensores que Utiliza la Aplicación',
              content:
              'Para ofrecer métricas deportivas exactas en tiempo real, NexPulse accede únicamente mientras usas la aplicación a:\n'
                  '• Ubicación GPS: Para trazar tu ruta en el mapa interactivo, calcular distancia recorrida y velocidad en km/h.\n'
                  '• Actividad Física (Podómetro): Para contabilizar tus pasos diarios y por sesión.\n'
                  '• Acelerómetro y Giroscopio: Para detectar la intensidad del movimiento (Descanso, Caminata, Trote) y estabilidad postural.\n'
                  '• Datos de Perfil: Nombre, correo, edad, peso, estatura y longitud de zancada.',
            ),
            const _PolicySectionCard(
              icon: Icons.fingerprint,
              title: '2. Autenticación Biométrica y Contraseñas',
              content:
              '• Tu contraseña se almacena cifrada localmente en el dispositivo y nunca se transmite a servidores externos.\n'
                  '• El inicio de sesión con huella dactilar o reconocimiento facial es procesado directamente por el sistema operativo Android; NexPulse jamás lee, copia ni almacena tus datos biométricos.',
            ),
            const _PolicySectionCard(
              icon: Icons.storage_rounded,
              title: '3. Almacenamiento 100% Local y Control del Usuario',
              content:
              '• Todo tu historial de entrenamientos, rutas GPS, calorías y configuración personal se guarda exclusivamente en la memoria privada de tu teléfono.\n'
                  '• No vendemos, compartimos ni cedemos tu ubicación ni tus estadísticas físicas a terceros o redes publicitarias.\n'
                  '• Puedes actualizar tus datos, cambiar tu contraseña o eliminar la aplicación en cualquier momento para borrar toda tu información.',
            ),
            const _PolicySectionCard(
              icon: Icons.health_and_safety,
              title: '4. Condiciones y Responsabilidad de Uso',
              content:
              '• NexPulse es una herramienta de monitoreo deportivo y telemetría personal; sus estimaciones de calorías y ritmo no sustituyen una valoración médica profesional.\n'
                  '• Mantén siempre atención a tu entorno vial al caminar o correr mientras consultas el mapa en pantalla.\n'
                  '• Para el correcto funcionamiento del mapa interactivo (Estándar, Satelital y Relieve) se requiere conexión a Internet para descargar los mosaicos cartográficos.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Entendido y Regresar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PolicySectionCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0284C7), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}