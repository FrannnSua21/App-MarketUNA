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


  String? _lastPassword;
  String _role = "user";
  UserProfile? _profile;

  AuthProvider() {
    _checkBiometricStatus();
  }

  bool get isLoggedIn => _authRepo.currentUser != null;
  String? get currentEmail => _authRepo.currentUser?.email;
  String? get currentUid => _authRepo.currentUser?.uid;

  String get role => _role;

  UserProfile? get profile => _profile;

  bool get isAdmin => _role == "admin";

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

      _lastPassword = password;

      final user = _authRepo.currentUser;

      if (user != null) {
        _role = await FirestoreService.getUserRole(user.uid);

        _profile = await FirestoreService.getUserProfile(user.uid);

        print("ROL: $_role");
        print("USUARIO: ${_profile?.firstName}");
      }

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
          role: 'user',
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

  /*Future<bool> loginWithBiometrics*/
  Future<bool> loginWithBiometrics() async {
    isLoading = true;
    notifyListeners();

    try {
      final biometricOk = await _biometricService.authenticate(
        reason: 'Confirme su identidad',
      );

      if (!biometricOk) {
        return false;
      }

      final email = await _biometricService.getBiometricEmail();
      final password = await _biometricService.getBiometricPassword();

      if (email == null || password == null) {
        print("No existen credenciales biométricas");
        return false;
      }

      await _authRepo.login(email, password);

      _lastPassword = password;

      final user = _authRepo.currentUser;

      if (user == null) {
        return false;
      }

      _role = await FirestoreService.getUserRole(user.uid);

      print("ROL: $_role");

      _profile = await FirestoreService.getUserProfile(user.uid);

      notifyListeners();

      return true;

    } catch (e) {
      print("ERROR LOGIN BIOMÉTRICO: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /*Future<void> enableBiometric*/
  Future<void> enableBiometric() async {

    final email = currentEmail;
    if (email == null || _lastPassword == null) {
      return;
    }
    await _biometricService.enableBiometric(
      email,
      _lastPassword!,
    );
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

    _profile = null;
    _role = "user";
    _lastPassword = null;

    notifyListeners();
  }

  Future<bool> verifyPassword(String password) async {
    final email = currentEmail;

    if (email == null) {
      return false;
    }

    try {
      await _authRepo.login(email, password);

      _lastPassword = password;

      return true;
    } on FirebaseAuthException {
      return false;
    } catch (e) {
      print("Error verificando contraseña: $e");
      return false;
    }
  }
}
