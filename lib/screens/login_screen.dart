import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'privacy_policy_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final StorageService _storage = StorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _obscurePassword = true;
  bool _isLoading = false;
  UserModel? _savedUser;
  String _appVersionLabel = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _storage.setLoggedIn(false);
    final user = await _storage.getUser();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _savedUser = user;
      _emailController.clear();
      _passwordController.clear();
      _appVersionLabel = 'v${info.version} (${info.buildNumber})';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = await _storage.getUser();
    if (!mounted) return;

    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cuentas registradas. Crea una cuenta primero.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    final inputHash = StorageService.hashPassword(_passwordController.text);
    if (user.email.toLowerCase() == _emailController.text.trim().toLowerCase() &&
        user.passwordHash == inputHash) {
      await _storage.setLoggedIn(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo o contraseña incorrectos.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _loginWithBiometricPrompt(String reasonMessage) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este dispositivo no tiene biometría disponible.'),
          ),
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reasonMessage,
        biometricOnly: false,
      );

      if (authenticated) {
        await _storage.setLoggedIn(true);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la verificación biométrica.'),
        ),
      );
    }
  }

  InputDecoration _buildFieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: const Color(0xFFF4F6F9),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF475569), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0B0F17), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFingerprint =
        _savedUser != null && _savedUser!.biometricEnabled;
    final bool showFaceScan =
        _savedUser != null && _savedUser!.faceAuthEnabled;
    final bool hasAnyBiometric = showFingerprint || showFaceScan;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F17),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomPaint(
                        painter: _SportsRouteHeaderPainter(),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF111827),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFBEF264)
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(11),
                                            child: Image.asset(
                                              'assets/images/logo.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'NEXPULSE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.8,
                                              ),
                                            ),
                                            Text(
                                              'RUNNING & FITNESS CLUB',
                                              style: TextStyle(
                                                color: Color(0xFFBEF264),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFBEF264),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _appVersionLabel,
                                            style: const TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Cada paso cuenta.\nSupera tu marca.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 31,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Registra tus carreras, rutas GPS, ritmo y calorías en cada entrenamiento.',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13.5,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _SportTag(
                                      icon: Icons.directions_run_rounded,
                                      label: 'PASOS',
                                      accent: Color(0xFFBEF264),
                                    ),
                                    _SportTag(
                                      icon: Icons.route_rounded,
                                      label: 'RUTAS GPS',
                                      accent: Color(0xFFF97316),
                                    ),
                                    _SportTag(
                                      icon:
                                      Icons.local_fire_department_rounded,
                                      label: 'CALORÍAS',
                                      accent: Color(0xFF34D399),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0B0F17),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (_savedUser != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFCCB),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Atleta: ${_savedUser!.name.split(' ').first}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF3F6212),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'CORREO ELECTRÓNICO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF475569),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: _buildFieldDecoration(
                                    hintText: 'Ej. roberto@nexpulse.com',
                                    prefixIcon: Icons.alternate_email_rounded,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Ingresa tu correo electrónico';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Ingresa un correo válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'CONTRASEÑA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF475569),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: _buildFieldDecoration(
                                    hintText: 'Ej. Pulse#2026',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Ingresa tu contraseña';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),
                                FilledButton(
                                  onPressed:
                                  _isLoading ? null : _loginWithCredentials,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B0F17),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 28),
                                      const Text(
                                        'Comenzar Entrenamiento',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFBEF264),
                                          borderRadius:
                                          BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Color(0xFF0B0F17),
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasAnyBiometric) ...[
                                  const SizedBox(height: 18),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'ACCESO RÁPIDO DE ATLETA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF94A3B8),
                                            letterSpacing: 0.9,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      if (showFingerprint)
                                        Expanded(
                                          child: _BiometricQuickTile(
                                            icon: Icons.fingerprint_rounded,
                                            label: 'Huella Dactilar',
                                            accentColor:
                                            const Color(0xFFEA580C),
                                            badgeBg: const Color(0xFFFFEDD5),
                                            onTap: () =>
                                                _loginWithBiometricPrompt(
                                                  'Coloca tu huella dactilar para ingresar a NexPulse',
                                                ),
                                          ),
                                        ),
                                      if (showFingerprint && showFaceScan)
                                        const SizedBox(width: 10),
                                      if (showFaceScan)
                                        Expanded(
                                          child: _BiometricQuickTile(
                                            icon: Icons.face_retouching_natural,
                                            label: 'Escaneo Facial',
                                            accentColor:
                                            const Color(0xFF4D7C0F),
                                            badgeBg: const Color(0xFFECFCCB),
                                            onTap: () =>
                                                _loginWithBiometricPrompt(
                                                  'Mira a la cámara para ingresar con escaneo facial a NexPulse',
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                                const Spacer(),
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '¿Nuevo corredor?',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              'Configura tu perfil y zancada',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const RegisterScreen(),
                                            ),
                                          );
                                          _initScreen();
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                          const Color(0xFFBEF264),
                                          foregroundColor:
                                          const Color(0xFF0B0F17),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Crear Cuenta',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const PrivacyPolicyScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Política de Privacidad y Condiciones de Uso',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SportTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _SportTag({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricQuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final Color badgeBg;
  final VoidCallback onTap;

  const _BiometricQuickTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.badgeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportsRouteHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Carriles curvos estilo pista de atletismo
    final trackPaint = Paint()
      ..color = const Color(0xFFBEF264).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final offset = i * 16.0;
      final trackPath = Path()
        ..moveTo(size.width * 0.45 + offset, 0)
        ..quadraticBezierTo(
          size.width * 0.55 + offset,
          size.height * 0.55,
          size.width + offset,
          size.height * 0.85,
        );
      canvas.drawPath(trackPath, trackPaint);
    }

    // Trazado de ruta GPS deportiva
    final routePaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final startPoint = Offset(size.width * 0.62, size.height * 0.68);
    final midPoint = Offset(size.width * 0.78, size.height * 0.42);
    final endPoint = Offset(size.width * 0.91, size.height * 0.52);

    final routePath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.46,
        size.width * 0.72,
        size.height * 0.58,
        midPoint.dx,
        midPoint.dy,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.30,
        endPoint.dx,
        endPoint.dy,
      );

    canvas.drawPath(routePath, routePaint);

    // Marcador de inicio (Volt Lime) y meta (Naranja Deportivo)
    final startDot = Paint()
      ..color = const Color(0xFFBEF264).withValues(alpha: 0.45);
    final endDot = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.55);

    canvas.drawCircle(startPoint, 4.5, startDot);
    canvas.drawCircle(endPoint, 5.0, endDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}