import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../profile/models/profile_models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final BiometricService _biometricService = BiometricService();

  bool isLoading = false;
  String? errorMessage;
  bool biometricAvailable = false;
  bool biometricEnabled = false;

  AuthProvider() {
    _checkBiometricStatus();
  }

  bool get isLoggedIn => _authRepo.currentUser != null;
  String? get currentEmail => _authRepo.currentUser?.email;
  String? get currentUid => _authRepo.currentUser?.uid;

  Stream<UserProfile?> get userProfileStream {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return FirestoreService.watchUserProfile(uid);
  }

  Future<void> _checkBiometricStatus() async {
    biometricAvailable = await _biometricService.isDeviceSupported();
    biometricEnabled = await _biometricService.isBiometricEnabled();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authRepo.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authRepo.traducirError(e.code);
      return false;
    } catch (e) {
      errorMessage = 'No se pudo iniciar sesión: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// [firstName], [lastName] y [phone] son opcionales: si no los mandas,
  /// se usa la parte del correo antes de la @ como nombre inicial.
  Future<bool> register(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authRepo.register(email, password);

      final uid = _authRepo.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.createUserProfile(
          uid: uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authRepo.traducirError(e.code);
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error creando perfil en Firestore: $e');
      errorMessage =
          'La cuenta se creó, pero hubo un problema guardando tus datos. '
          'Intenta iniciar sesión de nuevo.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /*Future<bool> loginWithBiometrics() async {
    if (!isLoggedIn) return false;
    return _biometricService.authenticate(
      reason: 'Inicia sesión con tu huella digital',
    );
  }*/
  Future<bool> loginWithBiometrics() async {
    return await _biometricService.authenticate(
     reason: 'Inicia sesión con tu huella digital',
    );
  }

  Future<void> enableBiometric() async {
    final email = currentEmail;
    if (email == null) return;
    await _biometricService.enableBiometric(email);
    biometricEnabled = true;
    notifyListeners();
  }

  Future<void> disableBiometric() async {
    await _biometricService.disableBiometric();
    biometricEnabled = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepo.logout();
    notifyListeners();
  }
}
