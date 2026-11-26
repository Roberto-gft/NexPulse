import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nexpulse/screens/home_screen.dart';
import 'package:nexpulse/screens/privacy_policy_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '20');
  final _weightCtrl = TextEditingController(text: '70');
  final _heightCtrl = TextEditingController(text: '170');
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _gender = 'Masculino';
  String _goal = 'Bajar de peso';
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptedPrivacy = false;
  bool _isSubmitting = false;

  bool get _hasMinLength => _passCtrl.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passCtrl.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passCtrl.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passCtrl.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\]').hasMatch(_passCtrl.text);
  bool get _passwordsMatch =>
      _passCtrl.text.isNotEmpty && _passCtrl.text == _confirmPassCtrl.text;

  bool get _isPasswordStrong =>
      _hasMinLength &&
          _hasUppercase &&
          _hasLowercase &&
          _hasNumber &&
          _hasSpecial;

  double get _formProgress {
    double p = 0.0;
    if (_nameCtrl.text.trim().isNotEmpty) p += 0.15;
    if (_emailCtrl.text.trim().contains('@')) p += 0.15;
    if (_ageCtrl.text.trim().isNotEmpty &&
        _weightCtrl.text.trim().isNotEmpty &&
        _heightCtrl.text.trim().isNotEmpty) {
      p += 0.20;
    }
    if (_isPasswordStrong) p += 0.25;
    if (_passwordsMatch) p += 0.15;
    if (_acceptedPrivacy) p += 0.10;
    return p.clamp(0.0, 1.0);
  }

  double? get _estimatedBmi {
    final w = double.tryParse(_weightCtrl.text.trim());
    final hCm = double.tryParse(_heightCtrl.text.trim());
    if (w == null || hCm == null || w <= 0 || hCm < 50) return null;
    final hM = hCm / 100.0;
    return w / (hM * hM);
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25.0) return 'Peso saludable';
    if (bmi < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  Future<void> _requestAllSensorPermissions() async {
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
    if (permanentlyDenied && mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Permisos de Sensores'),
          content: const Text(
            'Algunos permisos de sensores o ubicación están bloqueados en el sistema. Puedes activarlos manualmente desde los ajustes de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continuar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Abrir Ajustes'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _registerAccount() async {
    if (_isSubmitting) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final age = _ageCtrl.text.trim();
    final weight = _weightCtrl.text.trim();
    final height = _heightCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      _showError('Ingresa tu nombre completo y un correo electrónico válido.');
      return;
    }
    if (!_isPasswordStrong) {
      _showError('La contraseña debe cumplir todos los requisitos de seguridad.');
      return;
    }
    if (!_passwordsMatch) {
      _showError('Las contraseñas no coinciden.');
      return;
    }
    if (!_acceptedPrivacy) {
      _showError('Debes aceptar la Política de Privacidad y Uso de Datos.');
      return;
    }

    setState(() => _isSubmitting = true);

    await _requestAllSensorPermissions();

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final createdDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final userData = {
      'name': name,
      'email': email,
      'password': _passCtrl.text,
      'age': age.isEmpty ? '20' : age,
      'gender': _gender,
      'weight': weight.isEmpty ? '70' : weight,
      'height': height.isEmpty ? '170' : height,
      'goal': _goal,
      'createdAt': createdDate,
    };

    final rawAccounts = prefs.getStringList('registered_accounts') ?? [];
    rawAccounts.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded is Map && decoded['email'] == email;
      } catch (_) {
        return false;
      }
    });
    rawAccounts.add(jsonEncode(userData));
    await prefs.setStringList('registered_accounts', rawAccounts);

    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_age', userData['age']!);
    await prefs.setString('user_gender', _gender);
    await prefs.setString('user_weight', userData['weight']!);
    await prefs.setString('user_height', userData['height']!);
    await prefs.setString('user_goal', _goal);
    await prefs.setString('user_created_at', createdDate);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  InputDecoration _modernInputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    final fill = isDark ? const Color(0xFF0E1518) : const Color(0xFFF3F6F8);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13.5,
        color: isDark ? Colors.white60 : Colors.grey.shade600,
      ),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E9E6B)),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        color: isDark ? Colors.white54 : Colors.grey.shade600,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF2E9E6B),
          width: 1.8,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0B1113) : const Color(0xFFF2F5F8);
    final cardBg = isDark ? const Color(0xFF151F23) : Colors.white;
    final borderCol = isDark ? Colors.white10 : Colors.grey.shade200.withValues(alpha: 0.8);
    final bmi = _estimatedBmi;
    final progressPercent = (_formProgress * 100).round();

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // Cabecera Hero moderna con degradado y progreso dinámico
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
                padding: const EdgeInsets.fromLTRB(12, 6, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CE0A3).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF4CE0A3).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'NEXPULSE ID',
                            style: TextStyle(
                              color: Color(0xFF4CE0A3),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$progressPercent% listo',
                          style: const TextStyle(
                            color: Color(0xFF4CE0A3),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crear Cuenta NexPulse',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personaliza tu perfil biométrico y activa tus sensores.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _formProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.16),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CE0A3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido deslizable con tarjetas elevadas
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                // TARJETA 1: Datos Personales
                _SectionCard(
                  stepNumber: '1',
                  title: 'Datos Personales',
                  subtitle: 'Tu identidad dentro de NexPulse',
                  icon: Icons.person_rounded,
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        decoration: _modernInputDecoration(
                          label: 'Nombre completo',
                          icon: Icons.badge_outlined,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                        decoration: _modernInputDecoration(
                          label: 'Correo electrónico',
                          icon: Icons.alternate_email_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: _modernInputDecoration(
                          label: 'Edad',
                          icon: Icons.cake_outlined,
                          suffixText: 'años',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Género',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _GenderPill(
                            label: 'Masculino',
                            icon: Icons.male_rounded,
                            selected: _gender == 'Masculino',
                            isDark: isDark,
                            onTap: () => setState(() => _gender = 'Masculino'),
                          ),
                          const SizedBox(width: 8),
                          _GenderPill(
                            label: 'Femenino',
                            icon: Icons.female_rounded,
                            selected: _gender == 'Femenino',
                            isDark: isDark,
                            onTap: () => setState(() => _gender = 'Femenino'),
                          ),
                          const SizedBox(width: 8),
                          _GenderPill(
                            label: 'Otro',
                            icon: Icons.person_outline_rounded,
                            selected: _gender == 'Otro',
                            isDark: isDark,
                            onTap: () => setState(() => _gender = 'Otro'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // TARJETA 2: Perfil Físico y Objetivo
                _SectionCard(
                  stepNumber: '2',
                  title: 'Perfil Físico y Objetivo',
                  subtitle: 'Calibra calorías y recomendaciones',
                  icon: Icons.monitor_heart_rounded,
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _modernInputDecoration(
                                label: 'Peso',
                                icon: Icons.monitor_weight_outlined,
                                suffixText: 'kg',
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _modernInputDecoration(
                                label: 'Estatura',
                                icon: Icons.height_rounded,
                                suffixText: 'cm',
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (bmi != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E6B).withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insights_rounded,
                                size: 17,
                                color: Color(0xFF2E9E6B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'IMC inicial estimado: ${bmi.toStringAsFixed(1)} (${_bmiLabel(bmi)})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E9E6B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Objetivo Principal',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _GoalOptionCard(
                        title: 'Bajar de peso y quemar grasa',
                        subtitle: 'Déficit calórico y cardio optimizado',
                        icon: Icons.local_fire_department_rounded,
                        selected: _goal == 'Bajar de peso',
                        isDark: isDark,
                        onTap: () => setState(() => _goal = 'Bajar de peso'),
                      ),
                      const SizedBox(height: 8),
                      _GoalOptionCard(
                        title: 'Tonificar y ganar fuerza',
                        subtitle: 'Definición muscular y resistencia física',
                        icon: Icons.fitness_center_rounded,
                        selected: _goal == 'Tonificar cuerpo',
                        isDark: isDark,
                        onTap: () => setState(() => _goal = 'Tonificar cuerpo'),
                      ),
                      const SizedBox(height: 8),
                      _GoalOptionCard(
                        title: 'Mejorar resistencia cardiovascular',
                        subtitle: 'Mayor capacidad aeróbica y energía diaria',
                        icon: Icons.directions_run_rounded,
                        selected: _goal == 'Mejorar resistencia',
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _goal = 'Mejorar resistencia'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // TARJETA 3: Seguridad de la Cuenta
                _SectionCard(
                  stepNumber: '3',
                  title: 'Seguridad de la Cuenta',
                  subtitle: 'Protege tu historial y datos biométricos',
                  icon: Icons.shield_rounded,
                  cardBg: cardBg,
                  borderCol: borderCol,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        onChanged: (_) => setState(() {}),
                        decoration: _modernInputDecoration(
                          label: 'Contraseña',
                          icon: Icons.lock_outline_rounded,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0E1518)
                              : const Color(0xFFF5F8FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requisitos de seguridad:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _SecurityChip(
                                  met: _hasMinLength,
                                  label: '8+ caracteres',
                                  isDark: isDark,
                                ),
                                _SecurityChip(
                                  met: _hasUppercase,
                                  label: 'Mayúscula (A-Z)',
                                  isDark: isDark,
                                ),
                                _SecurityChip(
                                  met: _hasLowercase,
                                  label: 'Minúscula (a-z)',
                                  isDark: isDark,
                                ),
                                _SecurityChip(
                                  met: _hasNumber,
                                  label: 'Número (0-9)',
                                  isDark: isDark,
                                ),
                                _SecurityChip(
                                  met: _hasSpecial,
                                  label: 'Especial (@#\$%)',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        onChanged: (_) => setState(() {}),
                        decoration: _modernInputDecoration(
                          label: 'Confirmar contraseña',
                          icon: Icons.lock_reset_rounded,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      if (_passCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isPasswordStrong
                                ? const Color(0xFF2E9E6B).withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isPasswordStrong
                                            ? Icons.verified_user_rounded
                                            : Icons.info_outline_rounded,
                                        size: 16,
                                        color: _isPasswordStrong
                                            ? const Color(0xFF2E9E6B)
                                            : Colors.orange.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isPasswordStrong
                                            ? 'Seguridad: Óptima'
                                            : 'Seguridad: En progreso',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: _isPasswordStrong
                                              ? const Color(0xFF2E9E6B)
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_passCtrl.text.length}/8+ car.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _isPasswordStrong ? 1.0 : 0.45,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isPasswordStrong
                                        ? const Color(0xFF2E9E6B)
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                              if (_confirmPassCtrl.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _passwordsMatch
                                      ? '✓ Las contraseñas coinciden correctamente'
                                      : '✕ Las contraseñas aún no coinciden',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _passwordsMatch
                                        ? const Color(0xFF2E9E6B)
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // TARJETA 4: Política de Privacidad y Permisos
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () =>
                      setState(() => _acceptedPrivacy = !_acceptedPrivacy),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _acceptedPrivacy
                            ? const Color(0xFF2E9E6B)
                            : borderCol,
                        width: _acceptedPrivacy ? 1.5 : 1.0,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          activeColor: const Color(0xFF2E9E6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (val) =>
                              setState(() => _acceptedPrivacy = val ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, right: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: 'He leído y acepto la '),
                                      TextSpan(
                                        text:
                                        'Política de Privacidad y Uso de Datos',
                                        style: const TextStyle(
                                          color: Color(0xFF2E9E6B),
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const PrivacyPolicyScreen(),
                                              ),
                                            );
                                          },
                                      ),
                                      const TextSpan(
                                        text:
                                        ' para el monitoreo de GPS y sensores físicos.',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.sensors_rounded,
                                      size: 14,
                                      color: Color(0xFF2E9E6B),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Se solicitarán permisos de sensores al continuar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                        ),
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
                  ),
                ),
                const SizedBox(height: 20),

                // Botón CTA principal con degradado y elevación
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34B37A), Color(0xFF217A53)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E9E6B).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _registerAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 22),
                    label: Text(
                      _isSubmitting
                          ? 'Solicitando permisos...'
                          : 'Registrar Cuenta y Continuar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
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

class _SectionCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color cardBg;
  final Color borderCol;
  final bool isDark;
  final Widget child;

  const _SectionCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
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
                      '$stepNumber. $title',
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

class _GenderPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _GenderPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF2E9E6B)
        : (isDark ? const Color(0xFF0E1518) : const Color(0xFFF3F6F8));
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.grey.shade800);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2E9E6B)
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
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

class _GoalOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _GoalOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF2E9E6B).withValues(alpha: isDark ? 0.18 : 0.10)
        : (isDark ? const Color(0xFF0E1518) : const Color(0xFFF5F8FA));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E9E6B)
                : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2E9E6B)
                    : (isDark ? Colors.white10 : Colors.white),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF2E9E6B),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? const Color(0xFF2E9E6B) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityChip extends StatelessWidget {
  final bool met;
  final String label;
  final bool isDark;

  const _SecurityChip({
    required this.met,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: met
            ? const Color(0xFF2E9E6B).withValues(alpha: 0.16)
            : (isDark ? Colors.white10 : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: met
              ? const Color(0xFF2E9E6B).withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 13,
            color: met ? const Color(0xFF2E9E6B) : Colors.grey,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: met ? FontWeight.w700 : FontWeight.w500,
              color: met
                  ? const Color(0xFF2E9E6B)
                  : (isDark ? Colors.white60 : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}