// lib/core/services/api_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';

import 'storage_service.dart';
import '../models/dropbox_model.dart';
import '../models/alert_model.dart';
import '../models/loot_model.dart';
import '../models/command_model.dart';

class ApiService {
  static final Logger _logger = Logger();
  static Dio? _dio;
  static Dio? _c2Dio;

  /// Safely convert dynamic map to Map<String, dynamic>
  static Map<String, dynamic> _toStringDynamicMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  // ============================================================
  // DIO INITIALIZATION
  // ============================================================

  /// Initialize Dio for n8n webhook calls
  static Future<Dio> _getDio() async {
    if (_dio != null) return _dio!;

    final webhookUrl = await StorageService.getN8nWebhookUrl();
    
    _dio = Dio(
      BaseOptions(
        baseUrl: webhookUrl ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add API key to headers if available
          final apiKey = await StorageService.getApiKey();
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['X-API-Key'] = apiKey;
          }
          
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _logger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          _logger.e('ERROR MESSAGE: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    return _dio!;
  }

  /// Initialize Dio for C2 API calls (direct to Linode server)
  static Future<Dio> _getC2Dio() async {
    if (_c2Dio != null) return _c2Dio!;

    final c2Host = await StorageService.getC2Host();
    final apiKey = await StorageService.getApiKey();

    if (c2Host == null || c2Host.isEmpty) {
      throw Exception('C2 server not configured');
    }

    // Build C2 API URL (port 8443 for HTTPS API)
    final baseUrl = 'https://$c2Host:8443';

    _c2Dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null && apiKey.isNotEmpty) 'X-API-Key': apiKey,
        },
      ),
    );

    // Accept self-signed certificates (for dev/self-signed certs)
    (_c2Dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    // Add logging interceptor
    _c2Dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('C2 REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('C2 RESPONSE[${response.statusCode}]');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _logger.e('C2 ERROR[${e.response?.statusCode}]: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    return _c2Dio!;
  }

  /// Check if C2 API is configured
  static Future<bool> isC2Configured() async {
    final c2Host = await StorageService.getC2Host();
    return c2Host != null && c2Host.isNotEmpty;
  }

  /// Reset Dio instances (call when config changes)
  static void resetDio() {
    _dio = null;
    _c2Dio = null;
  }

  // ============================================================
  // DROPBOX ENDPOINTS
  // ============================================================

  /// Get all registered dropboxes status
static Future<ApiResponse<List<DropboxModel>>> getDropboxes() async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        final response = await dio.get('/api/dropboxes');

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          final dropboxes = data.map((e) {
            final mapped = _mapC2ToDropbox(Map<String, dynamic>.from(e as Map));
            return DropboxModel.fromJson(mapped);
          }).toList();
          return ApiResponse.success(dropboxes);
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/dropbox-list');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['dropboxes'] ?? [];
        final dropboxes = data.map((e) => DropboxModel.fromJson(e)).toList();
        return ApiResponse.success(dropboxes);
      }
      
      return ApiResponse.error('Failed to fetch dropboxes');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching dropboxes: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get single dropbox details
  static Future<ApiResponse<DropboxModel>> getDropboxDetail(String dropboxId) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        final response = await dio.get('/api/dropboxes/$dropboxId');

        if (response.statusCode == 200) {
          return ApiResponse.success(DropboxModel.fromJson(_mapC2ToDropbox(_toStringDynamicMap(response.data))));
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/dropbox-detail', 
        queryParameters: {'dropbox_id': dropboxId},
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(DropboxModel.fromJson(_toStringDynamicMap(response.data)));
      }
      
      return ApiResponse.error('Failed to fetch dropbox details');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching dropbox detail: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get dropbox heartbeat history
  static Future<ApiResponse<List<HeartbeatModel>>> getHeartbeatHistory(
    String dropboxId, {
    int limit = 50,
  }) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        final response = await dio.get(
          '/api/dropboxes/$dropboxId/heartbeats',
          queryParameters: {'limit': limit},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          final heartbeats = data.map((e) => HeartbeatModel.fromJson(_mapC2ToHeartbeat(e))).toList();
          return ApiResponse.success(heartbeats);
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/dropbox-heartbeats',
        queryParameters: {
          'dropbox_id': dropboxId,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['heartbeats'] ?? [];
        final heartbeats = data.map((e) => HeartbeatModel.fromJson(e)).toList();
        return ApiResponse.success(heartbeats);
      }
      
      return ApiResponse.error('Failed to fetch heartbeat history');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching heartbeats: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // ============================================================
  // ALERT ENDPOINTS
  // ============================================================

  /// Get all alerts
  static Future<ApiResponse<List<AlertModel>>> getAlerts({
    String? dropboxId,
    String? level,
    int limit = 100,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/alerts',
        queryParameters: {
          if (dropboxId != null) 'dropbox_id': dropboxId,
          if (level != null) 'level': level,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['alerts'] ?? [];
        final alerts = data.map((e) => AlertModel.fromJson(e)).toList();
        return ApiResponse.success(alerts);
      }
      
      return ApiResponse.error('Failed to fetch alerts');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching alerts: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Mark alert as read
  static Future<ApiResponse<bool>> markAlertRead(String alertId) async {
    try {
      final dio = await _getDio();
      final response = await dio.post('/webhook/alert-read',
        data: {'alert_id': alertId},
      );

      return ApiResponse.success(response.statusCode == 200);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error marking alert read: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // ============================================================
  // LOOT ENDPOINTS
  // ============================================================

  /// Get loot summary
  static Future<ApiResponse<LootSummaryModel>> getLootSummary({
    String? dropboxId,
  }) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        
        // Get dropbox ID if not provided
        String targetId = dropboxId ?? '';
        if (targetId.isEmpty) {
          final dropboxesResp = await dio.get('/api/dropboxes');
          if (dropboxesResp.statusCode == 200) {
            final List<dynamic> dropboxes = dropboxesResp.data;
            if (dropboxes.isNotEmpty) {
              targetId = dropboxes.first['id'];
            }
          }
        }

        if (targetId.isNotEmpty) {
          final response = await dio.get('/api/dropboxes/$targetId/loot/summary');
          if (response.statusCode == 200) {
            return ApiResponse.success(LootSummaryModel.fromJson(_mapC2ToLootSummary(_toStringDynamicMap(response.data))));
          }
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/loot-summary',
        queryParameters: {
          if (dropboxId != null) 'dropbox_id': dropboxId,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(LootSummaryModel.fromJson(_toStringDynamicMap(response.data)));
      }
      
      return ApiResponse.error('Failed to fetch loot summary');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching loot summary: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get credentials
  static Future<ApiResponse<List<CredentialModel>>> getCredentials({
    String? dropboxId,
    String? type,
    int limit = 100,
  }) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        
        String targetId = dropboxId ?? '';
        if (targetId.isEmpty) {
          final dropboxesResp = await dio.get('/api/dropboxes');
          if (dropboxesResp.statusCode == 200) {
            final List<dynamic> dropboxes = dropboxesResp.data;
            if (dropboxes.isNotEmpty) {
              targetId = dropboxes.first['id'];
            }
          }
        }

        if (targetId.isNotEmpty) {
          final response = await dio.get('/api/dropboxes/$targetId/loot/credentials');
          if (response.statusCode == 200) {
            final List<dynamic> data = response.data;
            final creds = data.map((e) => CredentialModel.fromJson(_mapC2ToCredential(e))).toList();
            return ApiResponse.success(creds);
          }
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/loot-credentials',
        queryParameters: {
          if (dropboxId != null) 'dropbox_id': dropboxId,
          if (type != null) 'type': type,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['credentials'] ?? [];
        final creds = data.map((e) => CredentialModel.fromJson(e)).toList();
        return ApiResponse.success(creds);
      }
      
      return ApiResponse.error('Failed to fetch credentials');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching credentials: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get hashes
  static Future<ApiResponse<List<HashModel>>> getHashes({
    String? dropboxId,
    int limit = 100,
  }) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        
        String targetId = dropboxId ?? '';
        if (targetId.isEmpty) {
          final dropboxesResp = await dio.get('/api/dropboxes');
          if (dropboxesResp.statusCode == 200) {
            final List<dynamic> dropboxes = dropboxesResp.data;
            if (dropboxes.isNotEmpty) {
              targetId = dropboxes.first['id'];
            }
          }
        }

        if (targetId.isNotEmpty) {
          final response = await dio.get('/api/dropboxes/$targetId/loot/hashes');
          if (response.statusCode == 200) {
            final List<dynamic> data = response.data;
            final hashes = data.map((e) => HashModel.fromJson(_mapC2ToHash(e))).toList();
            return ApiResponse.success(hashes);
          }
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/loot-hashes',
        queryParameters: {
          if (dropboxId != null) 'dropbox_id': dropboxId,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['hashes'] ?? [];
        final hashes = data.map((e) => HashModel.fromJson(e)).toList();
        return ApiResponse.success(hashes);
      }
      
      return ApiResponse.error('Failed to fetch hashes');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching hashes: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get discovered hosts
  static Future<ApiResponse<List<HostModel>>> getDiscoveredHosts({
    String? dropboxId,
  }) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        
        String targetId = dropboxId ?? '';
        if (targetId.isEmpty) {
          final dropboxesResp = await dio.get('/api/dropboxes');
          if (dropboxesResp.statusCode == 200) {
            final List<dynamic> dropboxes = dropboxesResp.data;
            if (dropboxes.isNotEmpty) {
              targetId = dropboxes.first['id'];
            }
          }
        }

        if (targetId.isNotEmpty) {
          final response = await dio.get('/api/dropboxes/$targetId/loot/hosts');
          if (response.statusCode == 200) {
            final List<dynamic> data = response.data;
            final hosts = data.map((e) => HostModel.fromJson(_mapC2ToHost(e))).toList();
            return ApiResponse.success(hosts);
          }
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/loot-hosts',
        queryParameters: {
          if (dropboxId != null) 'dropbox_id': dropboxId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['hosts'] ?? [];
        final hosts = data.map((e) => HostModel.fromJson(e)).toList();
        return ApiResponse.success(hosts);
      }
      
      return ApiResponse.error('Failed to fetch hosts');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching hosts: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // ============================================================
  // COMMAND ENDPOINTS
  // ============================================================

  /// Send command to dropbox
  static Future<ApiResponse<CommandResultModel>> sendCommand({
    required String dropboxId,
    required String command,
    Map<String, dynamic>? args,
    int timeout = 30,
  }) async {
    // Try C2 API first if configured (preferred for commands)
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        final response = await dio.post(
          '/api/dropboxes/$dropboxId/command',
          data: {
            'command': command,
            'args': args ?? {},
            'timeout': timeout,
          },
        );

        if (response.statusCode == 200) {
          return ApiResponse.success(CommandResultModel.fromJson(_mapC2ToCommandResult(_toStringDynamicMap(response.data))));
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.post('/webhook/dropbox-command',
        data: {
          'dropbox_id': dropboxId,
          'command': command,
          'args': args ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(CommandResultModel.fromJson(_toStringDynamicMap(response.data)));
      }
      
      return ApiResponse.error('Failed to send command');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error sending command: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get command history
  static Future<ApiResponse<List<CommandModel>>> getCommandHistory({
    String? dropboxId,
    int limit = 50,
  }) async {
    // Try C2 API first if configured
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        
        // If no dropbox specified, get first one
        String? targetId = dropboxId;
        if (targetId == null) {
          final dropboxesResp = await dio.get('/api/dropboxes');
          if (dropboxesResp.statusCode == 200) {
            final List<dynamic> dropboxes = dropboxesResp.data;
            if (dropboxes.isNotEmpty) {
              targetId = dropboxes.first['id'];
            }
          }
        }
        
        if (targetId != null) {
          final response = await dio.get(
            '/api/dropboxes/$targetId/commands',
            queryParameters: {'limit': limit},
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = response.data;
            final commands = data.map((e) => CommandModel.fromJson(_mapC2ToCommand(_toStringDynamicMap(e)))).toList();
            return ApiResponse.success(commands);
          }
        }
        
        // No dropboxes or no commands, return empty
        return ApiResponse.success([]);
      } catch (e) {
        _logger.w('C2 API failed: $e');
        return ApiResponse.success([]);
      }
    }

    // Only fall back to n8n if C2 not configured
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/command-history',
        queryParameters: {
          if (dropboxId != null) 'dropbox_id': dropboxId,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['commands'] ?? [];
        final commands = data.map((e) => CommandModel.fromJson(e)).toList();
        return ApiResponse.success(commands);
      }
      
      return ApiResponse.error('Failed to fetch command history');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching command history: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Trigger self-destruct (DANGER!)
  static Future<ApiResponse<bool>> triggerSelfDestruct({
    required String dropboxId,
    required String level,
    required String confirmCode,
  }) async {
    // Try C2 API first (preferred for dangerous operations)
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        final response = await dio.post(
          '/api/dropboxes/$dropboxId/self-destruct',
          queryParameters: {
            'confirm_code': confirmCode,
            'level': level,
          },
        );

        if (response.statusCode == 200) {
          return ApiResponse.success(true);
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.post('/webhook/self-destruct',
        data: {
          'dropbox_id': dropboxId,
          'level': level,
          'confirm_code': confirmCode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return ApiResponse.success(response.statusCode == 200);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error triggering self-destruct: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // ============================================================
  // RECON ENDPOINTS
  // ============================================================

  /// Trigger network scan
  static Future<ApiResponse<bool>> triggerRecon({
    required String dropboxId,
    String scanType = 'full',
  }) async {
    // Try C2 API first
    if (await isC2Configured()) {
      try {
        final dio = await _getC2Dio();
        final response = await dio.post(
          '/api/dropboxes/$dropboxId/recon',
          queryParameters: {'scan_type': scanType},
        );

        if (response.statusCode == 200) {
          return ApiResponse.success(true);
        }
      } catch (e) {
        _logger.w('C2 API failed, falling back to n8n: $e');
      }
    }

    // Fallback to n8n webhooks
    try {
      final dio = await _getDio();
      final response = await dio.post('/webhook/trigger-recon',
        data: {
          'dropbox_id': dropboxId,
          'scan_type': scanType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return ApiResponse.success(response.statusCode == 200);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error triggering recon: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Get scan results
  static Future<ApiResponse<ScanResultModel>> getScanResults({
    required String dropboxId,
    String? scanId,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/webhook/scan-results',
        queryParameters: {
          'dropbox_id': dropboxId,
          if (scanId != null) 'scan_id': scanId,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(ScanResultModel.fromJson(_toStringDynamicMap(response.data)));
      }
      
      return ApiResponse.error('Failed to fetch scan results');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Error fetching scan results: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // ============================================================
  // CONNECTION TEST
  // ============================================================

  /// Test connection to C2 API or n8n webhook
  static Future<ApiResponse<bool>> testConnection() async {
    // First try C2 API if configured
    final c2Host = await StorageService.getC2Host();
    if (c2Host != null && c2Host.isNotEmpty) {
      try {
        final apiKey = await StorageService.getApiKey();
        
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              if (apiKey != null && apiKey.isNotEmpty) 'X-API-Key': apiKey,
            },
          ),
        );

        // Accept self-signed certificates
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };

        final response = await dio.get('https://$c2Host:8443/api/health');

        if (response.statusCode == 200) {
          return ApiResponse.success(true);
        } else if (response.statusCode == 401) {
          return ApiResponse.error('Invalid API key');
        }
      } on DioException catch (e) {
        // C2 failed, try n8n
        _logger.w('C2 connection failed: ${e.message}');
      }
    }

    // Try n8n webhook
    try {
      final webhookUrl = await StorageService.getN8nWebhookUrl();
      if (webhookUrl == null || webhookUrl.isEmpty) {
        return ApiResponse.error('No C2 server or webhook URL configured');
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.post(
        '$webhookUrl/webhook/dropbox-heartbeat',
        data: {
          'dropbox_id': 'app-test',
          'ip_address': '0.0.0.0',
          'hostname': 'connection-test',
          'mac_address': '00:00:00:00:00:00',
          'uptime': 'test',
          'load': '0',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      return ApiResponse.success(response.statusCode == 200);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Connection test failed: $e');
      return ApiResponse.error('Connection failed: $e');
    }
  }

  // ============================================================
  // DIRECT WEBHOOK CALLS (for manual URL input)
  // ============================================================

  /// Call a webhook directly with custom URL
  static Future<ApiResponse<Map<String, dynamic>>> callWebhook({
    required String url,
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final apiKey = await StorageService.getApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        dio.options.headers['X-API-Key'] = apiKey;
      }

      Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await dio.get(url, queryParameters: queryParams);
          break;
        case 'POST':
          response = await dio.post(url, data: data, queryParameters: queryParams);
          break;
        case 'PUT':
          response = await dio.put(url, data: data, queryParameters: queryParams);
          break;
        case 'DELETE':
          response = await dio.delete(url, data: data, queryParameters: queryParams);
          break;
        default:
          return ApiResponse.error('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 200) {
        return ApiResponse.success(response.data is Map 
            ? response.data 
            : {'response': response.data});
      }
      
      return ApiResponse.error('Request failed with status ${response.statusCode}');
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      _logger.e('Webhook call failed: $e');
      return ApiResponse.error('Request failed: $e');
    }
  }

  // ============================================================
  // C2 API DATA MAPPERS
  // ============================================================

  /// Map C2 API dropbox response to app model format
  static Map<String, dynamic> _mapC2ToDropbox(Map<String, dynamic> c2Data) {
    return {
      'id': c2Data['id'] ?? '',
      'name': c2Data['name'] ?? c2Data['hostname'] ?? 'Unknown',
      'hostname': c2Data['hostname'] ?? '',
      'ip_address': c2Data['ip_address'] ?? '',
      'mac_address': c2Data['mac_address'] ?? '',
      'status': c2Data['status'] ?? 'offline',
      'last_seen': c2Data['last_seen'],
      'uptime': c2Data['uptime'] ?? '',
      'load': c2Data['load'] ?? '0',
      'network_interface': c2Data['network_interface'],
      'target_network': c2Data['target_network'],
      'stealth_enabled': c2Data['stealth_enabled'] ?? true,
      'current_operation': c2Data['current_operation'],
      'stats': c2Data['stats'] ?? {},
      'c2_status': {
        'ssh_connected': c2Data['ssh_connected'] ?? false,
        'https_beacon_active': c2Data['https_beacon_active'] ?? false,
        'dns_channel_active': c2Data['dns_channel_active'] ?? false,
        'primary_channel': c2Data['primary_channel'] ?? 'ssh',
        'last_beacon': c2Data['last_seen'],
        'beacon_interval': c2Data['beacon_interval'] ?? 60,
        'failed_attempts': c2Data['failed_attempts'] ?? 0,
      },
    };
  }

  /// Map C2 API heartbeat response to app model format
  static Map<String, dynamic> _mapC2ToHeartbeat(Map<String, dynamic> c2Data) {
    return {
      'id': c2Data['id'] ?? '',
      'dropbox_id': c2Data['dropbox_id'] ?? '',
      'timestamp': c2Data['timestamp'],
      'ip_address': c2Data['ip_address'] ?? '',
      'hostname': c2Data['hostname'] ?? '',
      'mac_address': c2Data['mac_address'] ?? '',
      'uptime': c2Data['uptime'] ?? '',
      'load': c2Data['load'] ?? '0',
      'system_info': c2Data['system_info'] ?? {},
    };
  }

  /// Map C2 API loot summary response to app model format
  static Map<String, dynamic> _mapC2ToLootSummary(Map<String, dynamic> c2Data) {
    return {
      'total_credentials': c2Data['total_credentials'] ?? 0,
      'total_hashes': c2Data['total_hashes'] ?? 0,
      'total_hosts': c2Data['total_hosts'] ?? 0,
      'cracked_hashes': c2Data['cracked_hashes'] ?? 0,
      'high_value_credentials': c2Data['high_value_credentials'] ?? 0,
      'credentials_by_type': c2Data['credentials_by_type'] ?? {},
      'hashes_by_type': c2Data['hashes_by_type'] ?? {},
      'hosts_by_os': c2Data['hosts_by_os'] ?? {},
      'last_updated': c2Data['last_updated'],
    };
  }

  /// Map C2 API credential response to app model format
  static Map<String, dynamic> _mapC2ToCredential(Map<String, dynamic> c2Data) {
    return {
      'id': c2Data['id'] ?? '',
      'dropbox_id': c2Data['dropbox_id'] ?? '',
      'type': c2Data['type'] ?? 'plaintext',
      'source': c2Data['source'] ?? 'responder',
      'username': c2Data['username'] ?? '',
      'domain': c2Data['domain'],
      'password': c2Data['password'],
      'hash': c2Data['hash'],
      'target_host': c2Data['target_host'],
      'target_service': c2Data['target_service'],
      'captured_at': c2Data['captured_at'],
      'is_cracked': c2Data['is_cracked'] ?? false,
      'metadata': c2Data['metadata'] ?? {},
    };
  }

  /// Map C2 API hash response to app model format
  static Map<String, dynamic> _mapC2ToHash(Map<String, dynamic> c2Data) {
    return {
      'id': c2Data['id'] ?? '',
      'dropbox_id': c2Data['dropbox_id'] ?? '',
      'type': c2Data['type'] ?? 'unknown',
      'username': c2Data['username'] ?? '',
      'domain': c2Data['domain'],
      'hash': c2Data['hash'] ?? '',
      'cracked_password': c2Data['cracked_password'],
      'source': c2Data['source'] ?? 'responder',
      'captured_at': c2Data['captured_at'],
      'is_cracked': c2Data['is_cracked'] ?? false,
      'metadata': c2Data['metadata'] ?? {},
    };
  }

  /// Map C2 API host response to app model format
  static Map<String, dynamic> _mapC2ToHost(Map<String, dynamic> c2Data) {
    return {
      'id': c2Data['id'] ?? '',
      'dropbox_id': c2Data['dropbox_id'] ?? '',
      'ip_address': c2Data['ip_address'] ?? '',
      'hostname': c2Data['hostname'],
      'mac_address': c2Data['mac_address'],
      'os': c2Data['os'] ?? 'unknown',
      'os_version': c2Data['os_version'],
      'services': c2Data['services'] ?? [],
      'discovered_at': c2Data['discovered_at'],
      'is_alive': c2Data['is_alive'] ?? true,
      'metadata': c2Data['metadata'] ?? {},
    };
  }

  /// Map C2 API command result response to app model format
  static Map<String, dynamic> _mapC2ToCommandResult(Map<String, dynamic> c2Data) {
    return {
      'command_id': c2Data['command_id'] ?? '',
      'success': c2Data['success'] ?? false,
      'message': c2Data['message'] ?? '',
      'output': c2Data['output'],
      'error': c2Data['error'],
      'exit_code': c2Data['exit_code'] ?? -1,
      'timestamp': c2Data['timestamp'] ?? DateTime.now().toIso8601String(),
      'data': c2Data['data'] != null ? _toStringDynamicMap(c2Data['data']) : {},
    };
  }

  /// Map C2 API command response to app model format
  static Map<String, dynamic> _mapC2ToCommand(Map<String, dynamic> c2Data) {
    return {
      'id': c2Data['id'] ?? '',
      'dropbox_id': c2Data['dropbox_id'] ?? '',
      'dropbox_name': c2Data['dropbox_name'],
      'type': c2Data['type'] ?? 'custom',
      'command': c2Data['command'] ?? '',
      'args': c2Data['args'] != null ? _toStringDynamicMap(c2Data['args']) : {},
      'status': c2Data['status'] ?? 'pending',
      'created_at': c2Data['created_at'],
      'executed_at': c2Data['executed_at'],
      'completed_at': c2Data['completed_at'],
      'output': c2Data['output'],
      'error': c2Data['error'],
      'exit_code': c2Data['exit_code'],
    };
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  static String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - check your network';
      case DioExceptionType.sendTimeout:
        return 'Send timeout - server may be overloaded';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout - server took too long';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.response?.data?['detail'] ?? 'Unknown error';
        if (statusCode == 401) {
          return 'Invalid API key';
        } else if (statusCode == 404) {
          return 'Not found: $message';
        } else if (statusCode == 503) {
          return 'Dropbox not connected';
        }
        return 'Server error ($statusCode): $message';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error - check if server is reachable';
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return 'Network unavailable - check your connection';
        }
        return 'Unknown error: ${e.message}';
      default:
        return 'Request failed: ${e.message}';
    }
  }
}

// ============================================================
// API RESPONSE WRAPPER
// ============================================================

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(
      error: error,
      isSuccess: false,
    );
  }
}

// ============================================================
// SCAN RESULT MODEL (needed here for the API return type)
// ============================================================

class ScanResultModel {
  final String scanId;
  final String dropboxId;
  final String scanType;
  final DateTime timestamp;
  final int hostsFound;
  final int servicesFound;
  final int vulnerabilitiesFound;
  final Map<String, dynamic> rawData;

  ScanResultModel({
    required this.scanId,
    required this.dropboxId,
    required this.scanType,
    required this.timestamp,
    required this.hostsFound,
    required this.servicesFound,
    required this.vulnerabilitiesFound,
    required this.rawData,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      scanId: json['scan_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      scanType: json['scan_type'] ?? 'unknown',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      hostsFound: json['hosts_found'] ?? 0,
      servicesFound: json['services_found'] ?? 0,
      vulnerabilitiesFound: json['vulnerabilities_found'] ?? 0,
      rawData: json['raw_data'] ?? {},
    );
  }
}