import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  static const baseUrl = 'https://yoursite.com/api/v1';

  Future<dynamic> get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/$path'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw ApiException('Request failed (${res.statusCode}).');
      }
      return jsonDecode(res.body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('No connection. Check your internet and try again.');
    }
  }
}