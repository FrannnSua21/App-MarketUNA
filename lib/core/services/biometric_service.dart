import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static const _kBiometricEnabledKey = 'biometric_enabled';
  static const _kBiometricEmailKey = 'biometric_email';
  static const _kBiometricPasswordKey = 'biometric_password';

  /// Indica si el dispositivo soporta biometría y tiene al menos
  /// una huella/Face ID registrada.
  /*Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }*/
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();

      final biometrics =
          await _auth.getAvailableBiometrics();

      print("Soporta biometría: $isSupported");
      print("Biometrías disponibles: $biometrics");

      return isSupported && biometrics.isNotEmpty;

    } catch (e) {
      print("Error comprobando biometría: $e");
      return false;
    }
  }

  Future<void> testBiometric() async {
  try {
    final supported = await _auth.isDeviceSupported();

    final biometrics =
        await _auth.getAvailableBiometrics();

    print("Dispositivo soporta: $supported");
    print("Biometrías: $biometrics");

  } catch(e) {
    print("Error: $e");
  }
}


  /// Indica si el USUARIO activó el login biométrico dentro de tu app.
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabledKey) ?? false;
  }

  /*Future<void> enableBiometric(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabledKey, true);
    await prefs.setString(_kBiometricEmailKey, email);
  }*/

  Future<void> enableBiometric(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardamos que el usuario activó la biometría
    await prefs.setBool(_kBiometricEnabledKey, true);

    // Guardamos el correo en preferencias
    await prefs.setString(_kBiometricEmailKey, email);

    // Guardamos la contraseña en almacenamiento seguro
    await _secureStorage.write(
      key: _kBiometricPasswordKey,
      value: password,
    );
  }



  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_kBiometricEnabledKey, false);
    await prefs.remove(_kBiometricEmailKey);

    await _secureStorage.delete(
      key: _kBiometricPasswordKey,
    );
  }

  Future<String?> getBiometricEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBiometricEmailKey);
  }

  Future<String?> getBiometricPassword() async {
    return await _secureStorage.read(
      key: _kBiometricPasswordKey,
    );
  }

  /*Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (e) {
      return false;
    }
  }*/

  Future<bool> authenticate({required String reason}) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      print("Resultado autenticación: $authenticated");

      return authenticated;

    } catch (e) {
      print("Error autenticación biométrica: $e");
      return false;
    }
  }
}
