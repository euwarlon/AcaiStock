import 'package:local_auth/local_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate({
    String reason = 'Confirme sua identidade para continuar',
  }) async {
    try {
      final available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!available) return false;
      return _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      return false;
    }
  }

  /// Em dispositivos sem biometria/PIN configurável pelo plugin (ex.: Windows),
  /// permite o fluxo continuar sem bloquear a interface.
  Future<bool> authenticateOrSkip({
    String reason = 'Confirme sua identidade para continuar',
  }) async {
    try {
      final available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!available) return true;
      return authenticate(reason: reason);
    } catch (_) {
      return true;
    }
  }
}
