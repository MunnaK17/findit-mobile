/// Host server Laravel. Setelah migrasi ke Supabase, hanya chatbot yang masih memakainya.
class ApiConstants {
  static String? _customHost;

  static String get apiHost {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    // 127.0.0.1:8000 bekerja langsung di Web dan di Android via USB (adb reverse tcp:8000 tcp:8000)
    return "http://127.0.0.1:8000";
  }

  static void setHost(String newHost) {
    if (!newHost.startsWith('http://') && !newHost.startsWith('https://')) {
      _customHost = "http://$newHost";
    } else {
      _customHost = newHost;
    }
  }

  static String get baseUrl => "$apiHost/api";

  static String get chatbot => "$baseUrl/chatbot";
}
