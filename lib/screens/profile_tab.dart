import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../utils/password_validator.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final StorageService _storage = StorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _user;
  bool _isLoading = true;
  String _versionInfo = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _storage.getUser();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _user = user;
      _versionInfo = 'Versión ${info.version} (${info.buildNumber})';
      _isLoading = false;
    });
  }

  Future<void> _toggleFingerprint(bool enable) async {
    if (_user == null) return;

    if (!enable) {
      final updated = _user!.copyWith(biometricEnabled: false);
      await _storage.saveUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso con huella dactilar desactivado.'),
        ),
      );
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu dispositivo no tiene biometría o bloqueo de seguridad configurado.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final verified = await _localAuth.authenticate(
        localizedReason:
        'Coloca tu huella dactilar para activar el acceso en NexPulse',
        biometricOnly: false,
      );

      if (!verified) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se verificó la huella. Permanece desactivada.'),
          ),
        );
        return;
      }

      final updated = _user!.copyWith(biometricEnabled: true);
      await _storage.saveUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Huella dactilar activada. Ya puedes usarla al iniciar sesión.',
          ),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo activar el sensor de huella dactilar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleFaceScan(bool enable) async {
    if (_user == null) return;

    if (!enable) {
      final updated = _user!.copyWith(faceAuthEnabled: false);
      await _storage.saveUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso con escaneo facial desactivado.'),
        ),
      );
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu dispositivo no tiene reconocimiento facial o biometría configurada.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final verified = await _localAuth.authenticate(
        localizedReason:
        'Mira a la cámara para activar el escaneo facial en NexPulse',
        biometricOnly: false,
      );

      if (!verified) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('No se completó el escaneo facial. Permanece desactivado.'),
          ),
        );
        return;
      }

      final updated = _user!.copyWith(faceAuthEnabled: true);
      await _storage.saveUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escaneo facial activado. Ya puedes usarlo al iniciar sesión.',
          ),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo activar el escaneo facial.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openChangePasswordSheet() async {
    if (_user == null) return;
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Icon(Icons.lock_reset,
                              color: Color(0xFF0284C7), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Cambiar Contraseña',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: currentPassCtrl,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          hintText: 'Ej. Pulse#2026',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setModalState(
                                    () => obscureCurrent = !obscureCurrent),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu contraseña actual';
                          }
                          if (StorageService.hashPassword(v) !=
                              _user!.passwordHash) {
                            return 'La contraseña actual no es correcta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          hintText: 'Ej. Nueva#2026',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setModalState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa una nueva contraseña';
                          }
                          if (!PasswordValidator.evaluate(v).isValid) {
                            return 'La nueva contraseña no cumple los requisitos';
                          }
                          return null;
                        },
                      ),
                      PasswordRequirementsBox(password: newPassCtrl.text),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          hintText: 'Ej. Nueva#2026',
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setModalState(
                                    () => obscureConfirm = !obscureConfirm),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          if (v != newPassCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      PasswordStrengthIndicator(
                        password: newPassCtrl.text,
                        confirmPassword: confirmPassCtrl.text,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await _storage.updatePassword(newPassCtrl.text);
                          await _loadProfile();
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                              Text('Contraseña actualizada correctamente.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar Nueva Contraseña'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editStrideDialog() async {
    if (_user == null) return;
    final ctrl = TextEditingController(
      text: _user!.strideLengthMeters.toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calibrar Zancada (metros)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Longitud promedio de paso (m)',
            hintText: 'Ej. 0.74',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val >= 0.3 && val <= 1.8) {
                final updated = _user!.copyWith(strideLengthMeters: val);
                await _storage.saveUser(updated);
                await _loadProfile();
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _storage.setLoggedIn(false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF38BDF8),
                child: Text(
                  (user?.name.isNotEmpty ?? false)
                      ? user!.name[0].toUpperCase()
                      : 'N',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Atleta NexPulse',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'usuario@nexpulse.com',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user?.fitnessGoal ?? 'Caminata saludable',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (user != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos Biométricos y Físicos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileInfoBadge(
                          label: 'Edad',
                          value: '${user.age} años',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileInfoBadge(
                          label: 'Peso',
                          value: '${user.weightKg.toStringAsFixed(1)} kg',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileInfoBadge(
                          label: 'Estatura',
                          value: '${user.heightCm.toStringAsFixed(0)} cm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileInfoBadge(
                          label: 'Género',
                          value: user.gender,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileInfoBadge(
                          label: 'Zancada',
                          value:
                          '${user.strideLengthMeters.toStringAsFixed(2)} m',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),

        // Apartado 1: Huella Dactilar
        Card(
          child: SwitchListTile(
            secondary: Icon(
              Icons.fingerprint,
              color: (user?.biometricEnabled ?? false)
                  ? const Color(0xFF0284C7)
                  : const Color(0xFF64748B),
              size: 28,
            ),
            title: const Text(
              'Acceso con Huella Dactilar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              (user?.biometricEnabled ?? false)
                  ? 'Activado: puedes iniciar sesión con tu huella'
                  : 'Desactivado: actívalo aquí para usar tu huella al entrar',
            ),
            activeThumbColor: const Color(0xFF0284C7),
            value: user?.biometricEnabled ?? false,
            onChanged: _toggleFingerprint,
          ),
        ),
        const SizedBox(height: 8),

        // Apartado 2: Escaneo Facial
        Card(
          child: SwitchListTile(
            secondary: Icon(
              Icons.face,
              color: (user?.faceAuthEnabled ?? false)
                  ? const Color(0xFF10B981)
                  : const Color(0xFF64748B),
              size: 28,
            ),
            title: const Text(
              'Acceso con Escaneo Facial',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              (user?.faceAuthEnabled ?? false)
                  ? 'Activado: puedes iniciar sesión con reconocimiento facial'
                  : 'Desactivado: actívalo aquí para usar tu rostro al entrar',
            ),
            activeThumbColor: const Color(0xFF10B981),
            value: user?.faceAuthEnabled ?? false,
            onChanged: _toggleFaceScan,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: const Icon(Icons.straighten, color: Color(0xFF10B981)),
            title: const Text(
              'Calibrar Longitud de Zancada',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Actual: ${(user?.strideLengthMeters ?? 0.74).toStringAsFixed(2)} metros por paso',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editStrideDialog,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_reset, color: Color(0xFF0284C7)),
            title: const Text(
              'Cambiar Contraseña',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Actualiza tu clave alfanumérica de seguridad',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openChangePasswordSheet,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading:
            const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6366F1)),
            title: const Text(
              'Política de Privacidad y Uso',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Consulta el uso de GPS, sensores y protección de datos',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: Text(
            'NexPulse • $_versionInfo',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoBadge extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}