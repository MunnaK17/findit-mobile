import 'dart:convert';
import 'package:http/http.dart' as http;

/// Klien HTTP ke server Laravel. Login memakai Supabase, jadi request di sini tidak membawa token.
class ApiService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    return await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
  }
}
