import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 30);
  static void Function()? onUnauthorized;

  static Future<http.Response> _send(Future<http.Response> response) async {
    final result = await response.timeout(_timeout);
    if (result.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      for (final key in ['token', 'name', 'role', 'user']) {
        await prefs.remove(key);
      }
      onUnauthorized?.call();
    }
    return result;
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _send(http.get(url, headers: headers));
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _send(http.post(url, headers: headers, body: body));
  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _send(http.patch(url, headers: headers, body: body));
}
