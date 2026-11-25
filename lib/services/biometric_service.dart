import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo cuenta con hardware biométrico y datos registrados
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!canAuthenticateWithBiometrics || !isDeviceSupported) {
        return false;
      }
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Devuelve una etiqueta descriptiva de los sensores biométricos disponibles
  Future<String> getAvailableMethodsText() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      final List<String> methods = [];
      if (available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong)) {
        methods.add('Huella Dactilar');
      }
      if (available.contains(BiometricType.face) ||
          available.contains(BiometricType.weak)) {
        methods.add('Escaneo Facial');
      }
      if (methods.isEmpty) return 'Biometría del dispositivo';
      return methods.join(' y ');
    } on PlatformException {
      return 'Huella Dactilar / Escaneo Facial';
    }
  }

  /// Lanza el diálogo nativo de autenticación biométrica de Android
  Future<bool> authenticate({required String reason}) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Seguridad Biométrica NexPulse',
            signInHint: 'Verifica tu huella o rostro para continuar',
            cancelButton: 'Cancelar',
          ),
        ],
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}