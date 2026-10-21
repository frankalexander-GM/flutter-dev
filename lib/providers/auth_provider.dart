import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Estado global de la sesión: usuario (`UserMe`), carga y errores.
/// Los tokens JWT los administra `ApiService` (SharedPreferences).
class AuthProvider extends ChangeNotifier {
  UserMe? _user;
  bool _isLoading = false;
  String? _error;

  UserMe? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Al arrancar: si hay tokens guardados, valida con `GET /auth/me`.
  Future<void> checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await AuthService.isLoggedIn()) {
        _user = await AuthService.getMe();
      }
    } catch (_) {
      // Token inválido/expirado: limpia la sesión local.
      await AuthService.logout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _start();
    try {
      final session = await AuthService.login(email, password);
      _user = session.user;
      _finish();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  /// Paso 1 del registro: crea la cuenta y envía el código de 6 dígitos.
  Future<RegisterResult> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required int age,
  }) async {
    _start();
    try {
      final result = await AuthService.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
        age: age,
      );
      _finish();
      return result;
    } catch (e) {
      _fail(e);
      rethrow;
    }
  }

  /// Paso 2: confirma el código y, si es válido, inicia sesión con las
  /// credenciales que se mantienen en memoria en la pantalla de verificación.
  Future<bool> verifyAndLogin({
    required String email,
    required String password,
    String? code,
    bool resend = false,
  }) async {
    _start();
    try {
      await AuthService.verifyRegister(
        email: email,
        code: code,
        resend: resend,
      );
      if (resend) {
        _finish();
        return false;
      }
      final session = await AuthService.login(email, password);
      _user = session.user;
      _finish();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  /// Entrada como invitado (solo lectura).
  Future<bool> loginAsGuest() async {
    _start();
    try {
      final session = await AuthService.guest();
      _user = session.user;
      _finish();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _start() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _finish() {
    _isLoading = false;
    notifyListeners();
  }

  void _fail(Object e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
