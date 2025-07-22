// lib/services/settings_service.dart

class SettingsService {
  // A static variable holds the IP in memory.
  // It will be null every time the app starts fresh.
  static String? _ipAddress;

  String? getIpAddress() {
    return _ipAddress;
  }

  void setIpAddress(String ip) {
    _ipAddress = ip;
  }
}
