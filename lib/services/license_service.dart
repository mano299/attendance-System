import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:unique_device_identifier/unique_device_identifier.dart';

class LicenseService {
  static const secret = "attendance_2026_secret";

  static Future<String> getDeviceId() async {
    return await UniqueDeviceIdentifier.getUniqueIdentifier() ?? "";
  }

  static String generateLicense(String deviceId) {
    final bytes = utf8.encode('$deviceId$secret');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> verify(String license) async {
    final id = await getDeviceId();
    return generateLicense(id) == license;
  }
}