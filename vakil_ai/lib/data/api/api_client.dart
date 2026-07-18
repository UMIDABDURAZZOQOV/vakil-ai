import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin REST client for the FastAPI backend. Every repository goes through
/// here so base-URL resolution, auth headers, and error handling live in
/// exactly one place.
class ApiClient {
  ApiClient(this._tokenProvider);

  final String? Function() _tokenProvider;

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    // 10.0.2.2 is the Android emulator's alias for the host machine's
    // localhost. A physical device needs the host's real LAN IP instead.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = _tokenProvider();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    String message = 'So\'rov muvaffaqiyatsiz tugadi (${response.statusCode})';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['detail'] != null) message = body['detail'].toString();
    } catch (_) {
      // Non-JSON error body — keep the generic message.
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> uploadFile(
    String path, {
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(json: false))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }
}
