import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nexpulse/screens/login_screen.dart';
import 'package:nexpulse/screens/privacy_policy_screen.dart';
import 'package:nexpulse/utils/theme_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _userName = 'Atleta NexPulse';
  String _userEmail = 'usuario@nexpulse.app';
  String _userAge = '20';
  String _userGender = 'Masculino';
  String _userWeight = '70';
  String _userHeight = '170';
  String _userGoal = 'Bajar de peso';
  String _createdAt = 'Cuenta activa';

  int _dailyStepsGoal = 8000;
  int _dailyKcalGoal = 450;

  bool _fingerprintEnabled = false;
  bool _faceIdEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ??
          prefs.getString('name') ??
          'Atleta NexPulse';
      _userEmail = prefs.getString('user_email') ??
          prefs.getString('email') ??
          'usuario@nexpulse.app';
      _userAge = prefs.getString('user_age') ?? '20';
      _userGender = prefs.getString('user_gender') ?? 'Masculino';
      _userWeight = prefs.getString('user_weight') ?? '70';
      _userHeight = prefs.getString('user_height') ?? '170';
      _userGoal = prefs.getString('user_goal') ?? 'Bajar de peso';
      _createdAt = prefs.getString('user_created_at') ?? 'Sesión verificada';
      _dailyStepsGoal = prefs.getInt('goal_daily_steps') ?? 8000;
      _dailyKcalGoal = prefs.getInt('goal_daily_kcal') ?? 450;
      _fingerprintEnabled =
          prefs.getBool('biometric_fingerprint_enabled') ?? false;
      _faceIdEnabled = prefs.getBool('biometric_face_enabled') ?? false;
    });
  }

  Future<void> _toggleFingerprint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!value) {
      await prefs.setBool('biometric_fingerprint_enabled', false);
      if (!mounted) return;
      setState(() => _fingerprintEnabled = false);
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        _showMessage(
          'Este dispositivo no tiene sensor biométrico disponible.',
          isError: true,
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason:
        'Coloca tu huella dactilar para activarla en NexPulse',
      );

      if (authenticated) {
        await prefs.setBool('biometric_fingerprint_enabled', true);
        if (!mounted) return;
        setState(() => _fingerprintEnabled = true);
        _showMessage('Huella dactilar activada correctamente.');
      }
    } catch (_) {
      _showMessage('No se pudo verificar la huella dactilar.', isError: true);
    }
  }

  Future<void> _toggleFaceRecognition(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!value) {
      await prefs.setBool('biometric_face_enabled', false);
      if (!mounted) return;
      setState(() => _faceIdEnabled = false);
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        _showMessage(
          'Este dispositivo no soporta reconocimiento biométrico.',
          isError: true,
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason:
        'Verifica tu rostro para activar el reconocimiento facial en NexPulse',
      );

      if (authenticated) {
        await prefs.setBool('biometric_face_enabled', true);
        if (!mounted) return;
        setState(() => _faceIdEnabled = true);
        _showMessage('Reconocimiento facial activado correctamente.');
      }
    } catch (_) {
      _showMessage(
        'No se pudo verificar el reconocimiento facial.',
        isError: true,
      );
    }
  }

  Future<void> _requestSensorsAgain() async {
    await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.sensors,
    ].request();
    _showMessage('Permisos de sensores verificados.');
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E9E6B),
      ),
    );
  }

  double _calculateBmi() {
    final w = double.tryParse(_userWeight) ?? 70.0;
    final hCm = double.tryParse(_userHeight) ?? 170.0;
    final hM = hCm / 100.0;
    if (hM <= 0) return 0.0;
    return w / (hM * hM);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25.0) return 'Saludable';
    if (bmi < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  Future<void> _openEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _userName);
    final ageCtrl = TextEditingController(text: _userAge);
    final weightCtrl = TextEditingController(text: _userWeight);
    final heightCtrl = TextEditingController(text: _userHeight);
    String selectedGoal = _userGoal;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Editar Especificaciones',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad (años)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estatura (cm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: [
                    'Bajar de peso',
                    'Tonificar cuerpo',
                    'Mejorar resistencia',
                  ].contains(selectedGoal)
                      ? selectedGoal
                      : 'Bajar de peso',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bajar de peso',
                      child: Text('Bajar de peso'),
                    ),
                    DropdownMenuItem(
                      value: 'Tonificar cuerpo',
                      child: Text('Tonificar cuerpo'),
                    ),
                    DropdownMenuItem(
                      value: 'Mejorar resistencia',
                      child: Text('Mejorar resistencia'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) selectedGoal = v;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E9E6B),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', nameCtrl.text.trim());
                await prefs.setString('user_age', ageCtrl.text.trim());
                await prefs.setString('user_weight', weightCtrl.text.trim());
                await prefs.setString('user_height', heightCtrl.text.trim());
                await prefs.setString('user_goal', selectedGoal);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadProfile();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal_daily_steps', _dailyStepsGoal);
    await prefs.setInt('goal_daily_kcal', _dailyKcalGoal);
    _showMessage('Metas diarias actualizadas correctamente.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0B1113) : const Color(0xFFF2F5F8);
    final cardBg = isDark ? const Color(0xFF151F23) : Colors.white;
    final borderCol =
    isDark ? Colors.white10 : Colors.grey.shade200.withValues(alpha: 0.85);
    final bmi = _calculateBmi();

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // Cabecera Hero con identidad del usuario y resumen biométrico
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
                            'PERFIL DE ATLETA',
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
                            onTap: _openEditProfileDialog,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF4CE0A3),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Editar',
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4CE0A3),
                              width: 2.2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF2E9E6B),
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'N',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '● Sesión Activa · $_createdAt',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4CE0A3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barra rápida de métricas corporales dentro del Hero
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 10,
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
                          _HeroMetric(
                            label: 'Edad',
                            value: '$_userAge a',
                          ),
                          _HeroDivider(),
                          _HeroMetric(
                            label: 'Peso',
                            value: '$_userWeight kg',
                          ),
                          _HeroDivider(),
                          _HeroMetric(
                            label: 'Estatura',
                            value: '$_userHeight cm',
                          ),
                          _HeroDivider(),
                          _HeroMetric(
                            label: 'IMC',
                            value: bmi.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                // Tarjeta 1: Ficha Biométrica y Objetivo (sin recortes de texto)
                _ProfileCard(
                  icon: Icons.badge_rounded,
                  title: 'Especificaciones de la Cuenta',
                  subtitle: 'Datos físicos vinculados a tu perfil',
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SpecTile(
                              icon: Icons.wc_rounded,
                              label: 'Género',
                              value: _userGender,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SpecTile(
                              icon: Icons.analytics_rounded,
                              label: 'Estado IMC',
                              value:
                              '${bmi.toStringAsFixed(1)} · ${_bmiCategory(bmi)}',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SpecTile(
                        icon: Icons.flag_rounded,
                        label: 'Objetivo Principal',
                        value: _userGoal,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta 2: Seguridad Biométrica (Huella Dactilar y Reconocimiento Facial)
                _ProfileCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Seguridad Biométrica',
                  subtitle: 'Activa acceso rápido con los sensores de tu equipo',
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _BiometricRow(
                        icon: Icons.fingerprint_rounded,
                        title: 'Huella Dactilar',
                        subtitle: _fingerprintEnabled
                            ? 'Activada para acceso rápido'
                            : 'Toca para registrar y activar tu huella',
                        enabled: _fingerprintEnabled,
                        isDark: isDark,
                        onChanged: _toggleFingerprint,
                      ),
                      const SizedBox(height: 10),
                      _BiometricRow(
                        icon: Icons.face_retouching_natural_rounded,
                        title: 'Reconocimiento Facial',
                        subtitle: _faceIdEnabled
                            ? 'Activado para verificación facial'
                            : 'Toca para activar el desbloqueo facial',
                        enabled: _faceIdEnabled,
                        isDark: isDark,
                        onChanged: _toggleFaceRecognition,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta 3: Metas Diarias Personalizadas
                _ProfileCard(
                  icon: Icons.track_changes_rounded,
                  title: 'Metas Diarias Personalizadas',
                  subtitle: 'Ajusta tus objetivos de actividad diaria',
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _GoalStepperTile(
                        icon: Icons.directions_walk_rounded,
                        label: 'Meta diaria de pasos',
                        valueText: '$_dailyStepsGoal pasos',
                        isDark: isDark,
                        canDecrease: _dailyStepsGoal > 2000,
                        onDecrease: () =>
                            setState(() => _dailyStepsGoal -= 1000),
                        onIncrease: () =>
                            setState(() => _dailyStepsGoal += 1000),
                      ),
                      const SizedBox(height: 10),
                      _GoalStepperTile(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Meta de quema activa',
                        valueText: '$_dailyKcalGoal kcal',
                        isDark: isDark,
                        canDecrease: _dailyKcalGoal > 150,
                        onDecrease: () =>
                            setState(() => _dailyKcalGoal -= 50),
                        onIncrease: () =>
                            setState(() => _dailyKcalGoal += 50),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34B37A), Color(0xFF217A53)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _saveGoals,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 19),
                          label: const Text(
                            'Guardar Metas Diarias',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta 4: Apariencia, Permisos y Privacidad
                _ProfileCard(
                  icon: Icons.tune_rounded,
                  title: 'Preferencias y Privacidad',
                  subtitle: 'Tema visual, sensores y términos legales',
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    children: [
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController.themeMode,
                        builder: (context, mode, _) {
                          final darkEnabled = mode == ThemeMode.dark;
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0E1518)
                                  : const Color(0xFFF5F8FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SwitchListTile(
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E9E6B)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  darkEnabled
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  color: const Color(0xFF2E9E6B),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Modo Oscuro',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                darkEnabled
                                    ? 'Activado (interfaz oscura)'
                                    : 'Desactivado (interfaz clara)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: darkEnabled,
                              activeThumbColor: const Color(0xFF2E9E6B),
                              onChanged: (val) =>
                                  ThemeController.setDarkMode(val),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.sensors_rounded,
                        title: 'Permisos de Sensores y GPS',
                        subtitle:
                        'Verificar o activar ubicación, podómetro y movimiento',
                        isDark: isDark,
                        onTap: _requestSensorsAgain,
                      ),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Política de Privacidad',
                        subtitle:
                        'Consultar términos de uso de sensores y datos biométricos',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Cerrar Sesión
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
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

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color borderCol;
  final bool isDark;
  final Widget child;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.borderCol,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E9E6B), Color(0xFF1A6B47)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E9E6B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2E9E6B)),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  value,
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

class _BiometricRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _BiometricRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF2E9E6B).withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? const Color(0xFF2E9E6B).withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        secondary: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF2E9E6B)
                : const Color(0xFF2E9E6B).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : const Color(0xFF2E9E6B),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF2E9E6B).withValues(alpha: 0.18)
                    : Colors.grey.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                enabled ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: enabled ? const Color(0xFF2E9E6B) : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        value: enabled,
        activeThumbColor: const Color(0xFF2E9E6B),
        onChanged: onChanged,
      ),
    );
  }
}

class _GoalStepperTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueText;
  final bool isDark;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _GoalStepperTile({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.isDark,
    required this.canDecrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E9E6B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFF2E9E6B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canDecrease ? onDecrease : null,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.white,
              foregroundColor: const Color(0xFF2E9E6B),
            ),
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onIncrease,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E6B),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9E6B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF2E9E6B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}