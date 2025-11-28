// lib/core/services/storage_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final Logger _logger = Logger();

  // Keys for secure storage
  static const String _keyApiKey = 'phantom_api_key';
  static const String _keyC2Host = 'phantom_c2_host';
  static const String _keyC2Port = 'phantom_c2_port';
  static const String _keyN8nWebhookUrl = 'phantom_n8n_webhook_url';
  static const String _keyDiscordWebhook = 'phantom_discord_webhook';
  static const String _keySshPrivateKey = 'phantom_ssh_private_key';

  // Keys for regular storage
  static const String _keyIsSetupComplete = 'is_setup_complete';
  static const String _keyLastSync = 'last_sync_timestamp';
  static const String _keySelectedDropbox = 'selected_dropbox_id';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyAutoRefreshInterval = 'auto_refresh_interval';
  static const String _keyDropboxList = 'dropbox_list';
  static const String _keyAlertHistory = 'alert_history';

  /// Initialize storage services
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _logger.i('StorageService initialized');
  }

  // ============================================================
  // SECURE STORAGE METHODS (for sensitive data)
  // ============================================================

  /// Save API key securely
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _keyApiKey, value: apiKey);
    _logger.d('API key saved securely');
  }

  /// Get API key
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _keyApiKey);
  }

  /// Save C2 server configuration
  static Future<void> saveC2Config({
    required String host,
    required String port,
  }) async {
    await _secureStorage.write(key: _keyC2Host, value: host);
    await _secureStorage.write(key: _keyC2Port, value: port);
    _logger.d('C2 config saved securely');
  }

  /// Get C2 host
  static Future<String?> getC2Host() async {
    return await _secureStorage.read(key: _keyC2Host);
  }

  /// Get C2 port
  static Future<String?> getC2Port() async {
    return await _secureStorage.read(key: _keyC2Port);
  }

  /// Save n8n webhook URL
  static Future<void> saveN8nWebhookUrl(String url) async {
    await _secureStorage.write(key: _keyN8nWebhookUrl, value: url);
    _logger.d('n8n webhook URL saved securely');
  }

  /// Get n8n webhook URL
  static Future<String?> getN8nWebhookUrl() async {
    return await _secureStorage.read(key: _keyN8nWebhookUrl);
  }

  /// Save Discord webhook URL
  static Future<void> saveDiscordWebhook(String url) async {
    await _secureStorage.write(key: _keyDiscordWebhook, value: url);
    _logger.d('Discord webhook saved securely');
  }

  /// Get Discord webhook URL
  static Future<String?> getDiscordWebhook() async {
    return await _secureStorage.read(key: _keyDiscordWebhook);
  }

  /// Save SSH private key (for advanced users)
  static Future<void> saveSshPrivateKey(String key) async {
    await _secureStorage.write(key: _keySshPrivateKey, value: key);
    _logger.d('SSH private key saved securely');
  }

  /// Get SSH private key
  static Future<String?> getSshPrivateKey() async {
    return await _secureStorage.read(key: _keySshPrivateKey);
  }

  /// Clear all secure storage
  static Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
    _logger.w('All secure storage cleared');
  }

  // ============================================================
  // REGULAR STORAGE METHODS (for non-sensitive data)
  // ============================================================

  /// Check if setup is complete
  static bool get isSetupComplete {
    return _prefs.getBool(_keyIsSetupComplete) ?? false;
  }

  /// Set setup complete status
  static Future<void> setSetupComplete(bool complete) async {
    await _prefs.setBool(_keyIsSetupComplete, complete);
  }

  /// Get last sync timestamp
  static DateTime? get lastSync {
    final timestamp = _prefs.getInt(_keyLastSync);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Set last sync timestamp
  static Future<void> setLastSync(DateTime time) async {
    await _prefs.setInt(_keyLastSync, time.millisecondsSinceEpoch);
  }

  /// Get selected dropbox ID
  static String? get selectedDropboxId {
    return _prefs.getString(_keySelectedDropbox);
  }

  /// Set selected dropbox ID
  static Future<void> setSelectedDropboxId(String id) async {
    await _prefs.setString(_keySelectedDropbox, id);
  }

  /// Get notifications enabled status
  static bool get notificationsEnabled {
    return _prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Set notifications enabled status
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Get biometrics enabled status
  static bool get biometricsEnabled {
    return _prefs.getBool(_keyBiometricsEnabled) ?? false;
  }

  /// Set biometrics enabled status
  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricsEnabled, enabled);
  }

  /// Get auto refresh interval in seconds (default 30)
  static int get autoRefreshInterval {
    return _prefs.getInt(_keyAutoRefreshInterval) ?? 30;
  }

  /// Set auto refresh interval
  static Future<void> setAutoRefreshInterval(int seconds) async {
    await _prefs.setInt(_keyAutoRefreshInterval, seconds);
  }

  /// Save dropbox list (cached)
  static Future<void> saveDropboxList(List<Map<String, dynamic>> dropboxes) async {
    final jsonString = jsonEncode(dropboxes);
    await _prefs.setString(_keyDropboxList, jsonString);
  }

  /// Get cached dropbox list
  static List<Map<String, dynamic>> getDropboxList() {
    final jsonString = _prefs.getString(_keyDropboxList);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Error decoding dropbox list: $e');
      return [];
    }
  }

  /// Save alert history (last 100 alerts)
  static Future<void> saveAlertHistory(List<Map<String, dynamic>> alerts) async {
    // Keep only last 100 alerts
    final trimmedAlerts = alerts.length > 100 
        ? alerts.sublist(alerts.length - 100) 
        : alerts;
    final jsonString = jsonEncode(trimmedAlerts);
    await _prefs.setString(_keyAlertHistory, jsonString);
  }

  /// Get alert history
  static List<Map<String, dynamic>> getAlertHistory() {
    final jsonString = _prefs.getString(_keyAlertHistory);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Error decoding alert history: $e');
      return [];
    }
  }

  /// Clear all regular storage
  static Future<void> clearPreferences() async {
    await _prefs.clear();
    _logger.w('All preferences cleared');
  }

  /// Clear everything (nuclear option)
  static Future<void> clearAll() async {
    await clearSecureStorage();
    await clearPreferences();
    _logger.w('ALL STORAGE CLEARED');
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Check if we have valid C2 configuration
  static Future<bool> hasValidC2Config() async {
    final host = await getC2Host();
    final webhookUrl = await getN8nWebhookUrl();
    return host != null && host.isNotEmpty && 
           webhookUrl != null && webhookUrl.isNotEmpty;
  }

  /// Export all non-sensitive settings as JSON (for backup)
  static Map<String, dynamic> exportSettings() {
    return {
      'isSetupComplete': isSetupComplete,
      'lastSync': lastSync?.toIso8601String(),
      'selectedDropboxId': selectedDropboxId,
      'notificationsEnabled': notificationsEnabled,
      'biometricsEnabled': biometricsEnabled,
      'autoRefreshInterval': autoRefreshInterval,
    };
  }

  /// Import settings from JSON (for restore)
  static Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['isSetupComplete'] != null) {
      await setSetupComplete(settings['isSetupComplete']);
    }
    if (settings['selectedDropboxId'] != null) {
      await setSelectedDropboxId(settings['selectedDropboxId']);
    }
    if (settings['notificationsEnabled'] != null) {
      await setNotificationsEnabled(settings['notificationsEnabled']);
    }
    if (settings['biometricsEnabled'] != null) {
      await setBiometricsEnabled(settings['biometricsEnabled']);
    }
    if (settings['autoRefreshInterval'] != null) {
      await setAutoRefreshInterval(settings['autoRefreshInterval']);
    }
    _logger.i('Settings imported successfully');
  }
}