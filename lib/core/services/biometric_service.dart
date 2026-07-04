import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    return canCheck && supported;
  }

  Future<List<BiometricType>> availableBiometrics() async {
    return _auth.getAvailableBiometrics();
  }

  Future<bool> authenticate() async {
    final canUse = await canUseBiometrics();
    if (!canUse) return false;

    return _auth.authenticate(
      localizedReason: 'افتح تطبيق حساباتي',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}