import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../utils/password_validator.dart';
import '../widgets/swipe_back_wrapper.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storage = StorageService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _strideController = TextEditingController(text: '0.74');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = 'Masculino';
  String _selectedGoal = 'Caminata saludable';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedPrivacy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _strideController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onHeightChanged(String value) {
    final cm = double.tryParse(value);
    if (cm != null && cm >= 100 && cm <= 230) {
      final estimatedStride = (cm / 100.0) * 0.415;
      _strideController.text = estimatedStride.toStringAsFixed(2);
    }
  }

  Future<void> _registerAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final passCheck = PasswordValidator.evaluate(_passwordController.text);
    if (!passCheck.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula, número y carácter especial.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes leer y aceptar la Política de Privacidad para continuar.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Aunque haya aceptado las políticas, solicita permisos generales de sensores
    await PermissionService.requestTrackingPermissions(
      context,
      forceDialog: true,
    );

    final user = UserModel(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      passwordHash: StorageService.hashPassword(_passwordController.text),
      age: int.tryParse(_ageController.text.trim()) ?? 20,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 70.0,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 170.0,
      gender: _selectedGender,
      fitnessGoal: _selectedGoal,
      strideLengthMeters:
      double.tryParse(_strideController.text.trim()) ?? 0.74,
      biometricEnabled: false, // El usuario lo activa por sí solo en Perfil
      acceptedPrivacyPolicy: true,
    );

    await _storage.saveUser(user);
    await _storage.setLoggedIn(false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cuenta creada correctamente. Ahora inicia sesión con tu correo y contraseña.',
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

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
            tooltip: 'Regresar al inicio de sesión',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Crear Cuenta NexPulse',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Completa tu perfil deportivo y biométrico para personalizar el cálculo de distancia, zancada y calorías.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '1. Información Personal',
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nombre completo',
                        hintText: 'Ej. Roberto Vizueth',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Ingresa tu nombre completo'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'Ej. roberto@nexpulse.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu correo electrónico';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Formato de correo no válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Edad (años)',
                              hintText: 'Ej. 20',
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final age = int.tryParse(v ?? '');
                              if (age == null || age < 10 || age > 110) {
                                return 'Edad válida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Género',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Masculino', child: Text('Masculino')),
                              DropdownMenuItem(
                                  value: 'Femenino', child: Text('Femenino')),
                              DropdownMenuItem(
                                  value: 'Otro', child: Text('Otro')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGender = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '2. Medidas Físicas y Objetivo',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Peso (kg)',
                              hintText: 'Ej. 70.5',
                              prefixIcon:
                              const Icon(Icons.monitor_weight_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final w = double.tryParse(v ?? '');
                              if (w == null || w < 25 || w > 300) {
                                return 'Peso válido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            onChanged: _onHeightChanged,
                            decoration: InputDecoration(
                              labelText: 'Estatura (cm)',
                              hintText: 'Ej. 175',
                              prefixIcon: const Icon(Icons.height),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final h = double.tryParse(v ?? '');
                              if (h == null || h < 100 || h > 230) {
                                return 'Estatura válida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _strideController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Longitud de zancada (metros)',
                        hintText: 'Ej. 0.74',
                        helperText:
                        'Se calcula automáticamente con tu estatura (puedes ajustarlo)',
                        prefixIcon: const Icon(Icons.straighten),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        final s = double.tryParse(v ?? '');
                        if (s == null || s < 0.3 || s > 1.8) {
                          return 'Ingresa una zancada entre 0.30 y 1.80 m';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGoal,
                      decoration: InputDecoration(
                        labelText: 'Objetivo deportivo principal',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Caminata saludable',
                            child: Text('Caminata saludable')),
                        DropdownMenuItem(
                            value: 'Running / Trote',
                            child: Text('Running / Trote')),
                        DropdownMenuItem(
                            value: 'Control de peso',
                            child: Text('Control de peso')),
                        DropdownMenuItem(
                            value: 'Rendimiento deportivo',
                            child: Text('Rendimiento deportivo')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGoal = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: '3. Seguridad de la Cuenta',
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Ej. Pulse#2026',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Crea una contraseña';
                        }
                        if (!PasswordValidator.evaluate(v).isValid) {
                          return 'No cumple con todos los requisitos de seguridad';
                        }
                        return null;
                      },
                    ),
                    PasswordRequirementsBox(password: _passwordController.text),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        hintText: 'Ej. Pulse#2026',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    PasswordStrengthIndicator(
                      password: _passwordController.text,
                      confirmPassword: _confirmPasswordController.text,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptedPrivacy,
                        activeColor: const Color(0xFF0284C7),
                        onChanged: (val) =>
                            setState(() => _acceptedPrivacy = val ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF334155),
                                  height: 1.35,
                                ),
                                children: [
                                  TextSpan(text: 'He leído y acepto la '),
                                  TextSpan(
                                    text:
                                    'Política de Privacidad y Uso de Datos',
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(
                                      text:
                                      ' para el monitoreo de GPS y sensores físicos.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _registerAccount,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text(
                    'Registrar Cuenta y Continuar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}