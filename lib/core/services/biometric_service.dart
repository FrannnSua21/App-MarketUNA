import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  static const _kBiometricEnabledKey = 'biometric_enabled';
  static const _kBiometricEmailKey = 'biometric_email';

  /// Indica si el dispositivo soporta biometría y tiene al menos
  /// una huella/Face ID registrada.
  Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Indica si el USUARIO activó el login biométrico dentro de tu app.
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabledKey) ?? false;
  }

  Future<void> enableBiometric(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabledKey, true);
    await prefs.setString(_kBiometricEmailKey, email);
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabledKey, false);
    await prefs.remove(_kBiometricEmailKey);
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (e) {
      return false;
    }
  }
}
