import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = "auth_token";

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String url) async {
    final headers = await _headers();
    return await http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final headers = await _headers();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String url) async {
    final headers = await _headers();
    return await http.delete(Uri.parse(url), headers: headers);
  }

  static Future<http.StreamedResponse> postMultipart({
    required String url,
    required Map<String, String> fields,
    File? imageFile,
    String fileField = 'foto_barang',
  }) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);
    final token = await getToken();

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields.addAll(fields);

    if (imageFile != null && await imageFile.exists()) {
      request.files.add(await http.MultipartFile.fromPath(fileField, imageFile.path));
    }

    return await request.send();
  }
}
