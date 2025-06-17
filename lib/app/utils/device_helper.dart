import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceHelper {
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfoPlugin.androidInfo;
      return {
        'platform': 'Android',
        'model': info.model,
        'brand': info.brand,
        'version': info.version.sdkInt,
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      return {
        'platform': 'iOS',
        'model': info.utsname.machine,
        'name': info.name,
        'systemVersion': info.systemVersion,
      };
    } else {
      return {'platform': 'Unknown'};
    }
  }
}
