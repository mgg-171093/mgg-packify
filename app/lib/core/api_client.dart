import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/generate_result.dart';
import '../models/options_model.dart';
import '../models/package_config.dart';
import '../models/package_list_item.dart';
import '../models/settings_model.dart';
import 'app_logger.dart';

// ─────────────────────────────────────────────
// ApiException
// ─────────────────────────────────────────────

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─────────────────────────────────────────────
// ApiClient
// ─────────────────────────────────────────────

class ApiClient {
  static const _base = 'http://127.0.0.1:8787';
  static const _timeout = Duration(seconds: 30);
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // ── Helpers ──────────────────────────────────

  Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$_base$path');
    if (params != null && params.isNotEmpty) {
      return uri.replace(queryParameters: params);
    }
    return uri;
  }

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Throws [ApiException] if status is not 2xx.
  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = (body['detail'] as String?) ?? response.body;
      } catch (_) {
        message = response.body;
      }
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  void _logDebug(String message) {
    AppLogger.d(message);
  }

  // ── Health ────────────────────────────────────

  /// GET /health — throws ApiException on non-200 or timeout
  Future<void> getHealth() async {
    try {
      final response = await _client.get(_uri('/health')).timeout(_timeout);
      _logDebug('GET /health → ${response.statusCode}');
      _checkStatus(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // ── Settings ──────────────────────────────────

  /// GET /settings → SettingsModel
  Future<SettingsModel> getSettings() async {
    try {
      final response = await _client
          .get(_uri('/settings'), headers: _jsonHeaders)
          .timeout(_timeout);
      _logDebug('GET /settings → ${response.statusCode}');
      _checkStatus(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SettingsModel.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener configuración: $e');
    }
  }

  /// PUT /settings — sends full SettingsModel
  Future<void> putSettings(SettingsModel settings) async {
    try {
      final response = await _client
          .put(
            _uri('/settings'),
            headers: _jsonHeaders,
            body: jsonEncode(settings.toJson()),
          )
          .timeout(_timeout);
      _logDebug('PUT /settings → ${response.statusCode}');
      _checkStatus(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al guardar configuración: $e');
    }
  }

  // ── Options ───────────────────────────────────

  /// GET /settings/options → OptionsModel
  Future<OptionsModel> getOptions() async {
    try {
      final response = await _client
          .get(_uri('/settings/options'), headers: _jsonHeaders)
          .timeout(_timeout);
      _logDebug('GET /settings/options → ${response.statusCode}');
      _checkStatus(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OptionsModel.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener opciones: $e');
    }
  }

  /// PUT /settings/options — sends full OptionsModel, returns updated OptionsModel
  Future<OptionsModel> putOptions(OptionsModel opts) async {
    try {
      final response = await _client
          .put(
            _uri('/settings/options'),
            headers: _jsonHeaders,
            body: jsonEncode(opts.toJson()),
          )
          .timeout(_timeout);
      _logDebug('PUT /settings/options → ${response.statusCode}');
      _checkStatus(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OptionsModel.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al guardar opciones: $e');
    }
  }

  // ── Packages ──────────────────────────────────

  /// POST /packages/generate → GenerateResult
  Future<GenerateResult> generatePackage(PackageConfig config) async {
    try {
      final response = await _client
          .post(
            _uri('/packages/generate'),
            headers: _jsonHeaders,
            body: jsonEncode(config.toJson()),
          )
          .timeout(const Duration(minutes: 5));
      _logDebug('POST /packages/generate → ${response.statusCode}');
      _checkStatus(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return GenerateResult.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al generar package: $e');
    }
  }

  /// POST /packages/clone → Map with prefill data
  Future<Map<String, dynamic>> clonePackage(
    String sourcePath,
    String newIteracion,
  ) async {
    try {
      final response = await _client
          .post(
            _uri('/packages/clone'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'source_path': sourcePath,
              'new_iteracion': newIteracion,
            }),
          )
          .timeout(_timeout);
      _logDebug('POST /packages/clone → ${response.statusCode}');
      _checkStatus(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al clonar package: $e');
    }
  }

  /// GET /packages/list?base_dir=... → List<PackageListItem>
  Future<List<PackageListItem>> listPackages(String baseDir) async {
    try {
      final response = await _client
          .get(
            _uri('/packages/list', {'base_dir': baseDir}),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);
      _logDebug('GET /packages/list → ${response.statusCode}');
      _checkStatus(response);
      final list = jsonDecode(response.body) as List;
      return list
          .map((e) => PackageListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al listar packages: $e');
    }
  }

  /// GET /logs?source={source}&lines={lines} → Map with lines list
  Future<Map<String, dynamic>> getLogs({
    required String source,
    int lines = 200,
  }) async {
    try {
      final response = await _client
          .get(
            _uri('/logs', {'source': source, 'lines': '$lines'}),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);
      _logDebug(
        'GET /logs?source=$source&lines=$lines → ${response.statusCode}',
      );
      _checkStatus(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener logs: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});
