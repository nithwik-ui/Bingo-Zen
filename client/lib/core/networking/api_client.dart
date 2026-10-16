// Thin REST client. All endpoints are documented in docs/API.md and
// implemented by the Node.js server. The client DOES NOT invent endpoints.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/zen_failure.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _u(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    final Uri uri = _u(path).replace(
      queryParameters: query == null ? null : Map<String, String>.from(query),
    );
    return _send(() => _client.get(uri, headers: _headers()));
  }

  Future<Map<String, dynamic>> post(String path,
      [Map<String, dynamic>? body]) async {
    return _send(() => _client.post(
          _u(path),
          headers: _headers(),
          body: jsonEncode(body ?? const {}),
        ));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _send(() => _client.delete(_u(path), headers: _headers()));
  }

  Map<String, String> _headers() => {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      };

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const TimeoutFailure('Request timed out');
    } on SocketException catch (e) {
      throw NetworkFailure('Network error', cause: e);
    } catch (e) {
      throw UnknownFailure('Request failed', cause: e);
    }
    final int code = res.statusCode;
    final Map<String, dynamic> body = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (code >= 200 && code < 300) return body;
    if (code == 401) {
      throw UnauthorizedFailure(
        body['message']?.toString() ?? 'Session expired',
      );
    }
    if (code >= 500) {
      throw ServerFailure(
        body['message']?.toString() ?? 'Server error',
        statusCode: code,
      );
    }
    throw ServerFailure(
      body['message']?.toString() ?? 'Request failed',
      statusCode: code,
    );
  }

  void close() => _client.close();
}