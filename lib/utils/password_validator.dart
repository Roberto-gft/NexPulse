import 'package:flutter/material.dart';

enum PasswordStrengthLevel { weak, medium, strong }

class PasswordCheckResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordCheckResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  bool get isValid =>
      hasMinLength &&
          hasUppercase &&
          hasLowercase &&
          hasDigit &&
          hasSpecialChar;

  int get metCount => [
    hasMinLength,
    hasUppercase,
    hasLowercase,
    hasDigit,
    hasSpecialChar,
  ].where((e) => e).length;

  PasswordStrengthLevel get strengthLevel {
    if (!hasMinLength || metCount <= 2) {
      return PasswordStrengthLevel.weak;
    }
    if (metCount < 5) {
      return PasswordStrengthLevel.medium;
    }
    return PasswordStrengthLevel.strong;
  }

  String get strengthLabel {
    switch (strengthLevel) {
      case PasswordStrengthLevel.weak:
        return 'No segura';
      case PasswordStrengthLevel.medium:
        return 'Mediana';
      case PasswordStrengthLevel.strong:
        return 'Segura';
    }
  }

  Color get strengthColor {
    switch (strengthLevel) {
      case PasswordStrengthLevel.weak:
        return const Color(0xFFDC2626);
      case PasswordStrengthLevel.medium:
        return const Color(0xFFD97706);
      case PasswordStrengthLevel.strong:
        return const Color(0xFF059669);
    }
  }

  double get strengthProgress {
    switch (strengthLevel) {
      case PasswordStrengthLevel.weak:
        return 0.33;
      case PasswordStrengthLevel.medium:
        return 0.66;
      case PasswordStrengthLevel.strong:
        return 1.0;
    }
  }
}

class PasswordValidator {
  static PasswordCheckResult evaluate(String password) {
    return PasswordCheckResult(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasDigit: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar:
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\];~`]').hasMatch(password),
    );
  }
}

class PasswordRequirementsBox extends StatelessWidget {
  final String password;

  const PasswordRequirementsBox({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final res = PasswordValidator.evaluate(password);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu contraseña debe ser alfanumérica e incluir:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          _RuleItem(
            met: res.hasMinLength,
            text: 'Mínimo 8 caracteres',
          ),
          _RuleItem(
            met: res.hasUppercase,
            text: 'Al menos una letra mayúscula (A-Z)',
          ),
          _RuleItem(
            met: res.hasLowercase,
            text: 'Al menos una letra minúscula (a-z)',
          ),
          _RuleItem(
            met: res.hasDigit,
            text: 'Al menos un número (0-9)',
          ),
          _RuleItem(
            met: res.hasSpecialChar,
            text: 'Al menos un carácter especial (@, #, \$, %, &, *, etc.)',
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final bool met;
  final String text;

  const _RuleItem({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: met ? const Color(0xFF059669) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: met ? const Color(0xFF065F46) : const Color(0xFF64748B),
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final String confirmPassword;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.confirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final res = PasswordValidator.evaluate(password);
    final bool hasConfirm = confirmPassword.isNotEmpty;
    final bool matches = password == confirmPassword && hasConfirm;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: res.strengthColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: res.strengthColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seguridad: ${res.strengthLabel}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: res.strengthColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${password.length}/8+ car.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: res.hasMinLength
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: password.isEmpty ? 0.08 : res.strengthProgress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              color: res.strengthColor,
            ),
          ),
          if (hasConfirm) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  matches ? Icons.verified : Icons.error_outline,
                  size: 14,
                  color: matches
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    matches
                        ? 'Las contraseñas coinciden correctamente'
                        : 'Las contraseñas aún no coinciden',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: matches
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}