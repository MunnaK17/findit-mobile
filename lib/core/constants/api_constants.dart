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

  static String get host => apiHost;

  static String get baseUrl => "$apiHost/api";
  static String get baseStorageUrl => "$apiHost/storage";

  // Auth Endpoints
  static String get login => "$baseUrl/login";
  static String get register => "$baseUrl/register";
  static String get verifyEmail => "$baseUrl/verify-email";
  static String get resendVerification => "$baseUrl/resend-verification";
  static String get logout => "$baseUrl/logout";
  static String get user => "$baseUrl/user";

  // Reports & Masters
  static String get reports => "$baseUrl/reports";
  static String get myReports => "$baseUrl/my-reports";
  static String get categories => "$baseUrl/categories";
  static String get campuses => "$baseUrl/campuses";

  // Claims
  static String get claims => "$baseUrl/claims";
  static String get myClaims => "$baseUrl/my-claims";

  // AI Chatbot
  static String get chatbot => "$baseUrl/chatbot";
}

