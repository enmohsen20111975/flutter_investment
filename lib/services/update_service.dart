import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static Future<void> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final result = await InAppUpdate.checkForUpdate();
      if (result.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // Play Store in-app updates are ignored during local testing.
    }
  }
}
