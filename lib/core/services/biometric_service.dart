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

  
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();

      final biometrics =  await _auth.getAvailableBiometrics();

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
  

  Future<void> enableBiometric( String email, String password,
  ) async {

      print("GUARDANDO EMAIL: $email");

      print("GUARDANDO PASSWORD: $password");

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_kBiometricEnabledKey, true);

      await prefs.setString(
          _kBiometricEmailKey,
          email,
      );

      await _secureStorage.write(
          key: _kBiometricPasswordKey,
          value: password,
      );

      print("GUARDADO FINALIZADO");

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

  Future<bool> authenticate({
    required String reason,
  }) async {
    try {

      print("=== INICIANDO AUTENTICACIÓN BIOMÉTRICA ===");

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      print("Resultado autenticación: $authenticated");

      return authenticated;

    } catch (e) {
      print(e);
      return false;
    }
  }
}
