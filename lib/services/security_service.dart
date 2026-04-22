import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class SecurityService {
  SecurityService._privateConstructor();
  static final SecurityService instance = SecurityService._privateConstructor();

  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    return await auth.isDeviceSupported();
  }

  Future<bool> canCheckBiometrics() async {
    return await auth.canCheckBiometrics;
  }

  Future<bool> authenticate({String reason = 'الرجاء توثيق الهوية لفتح التطبيق.'}) async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false, // fallback to PIN is allowed
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.passcodeNotSet ||
          e.code == auth_error.notEnrolled) {
        // Device does not have security setup. Let them pass to avoid blocking access entirely, 
        // or return false to strictly block. 
        // Returning true here because if it's not setup, we shouldn't lock out the user completely.
        return true; 
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
