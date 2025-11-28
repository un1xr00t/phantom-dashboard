// lib/core/models/loot_model.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ============================================================
// CREDENTIAL MODEL
// ============================================================

enum CredentialType {
  plaintext,
  ntlm,
  kerberos,
  ssh,
  certificate,
  token,
  cookie,
  apiKey,
  other;

  static CredentialType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'plaintext':
      case 'plain':
      case 'cleartext':
        return CredentialType.plaintext;
      case 'ntlm':
        return CredentialType.ntlm;
      case 'kerberos':
      case 'krb5':
        return CredentialType.kerberos;
      case 'ssh':
      case 'ssh_key':
        return CredentialType.ssh;
      case 'certificate':
      case 'cert':
        return CredentialType.certificate;
      case 'token':
      case 'jwt':
      case 'bearer':
        return CredentialType.token;
      case 'cookie':
      case 'session':
        return CredentialType.cookie;
      case 'api_key':
      case 'apikey':
        return CredentialType.apiKey;
      default:
        return CredentialType.other;
    }
  }

  String get displayName {
    switch (this) {
      case CredentialType.plaintext:
        return 'Plaintext';
      case CredentialType.ntlm:
        return 'NTLM';
      case CredentialType.kerberos:
        return 'Kerberos';
      case CredentialType.ssh:
        return 'SSH Key';
      case CredentialType.certificate:
        return 'Certificate';
      case CredentialType.token:
        return 'Token';
      case CredentialType.cookie:
        return 'Cookie';
      case CredentialType.apiKey:
        return 'API Key';
      case CredentialType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case CredentialType.plaintext:
        return Icons.text_fields;
      case CredentialType.ntlm:
        return Icons.window;
      case CredentialType.kerberos:
        return Icons.security;
      case CredentialType.ssh:
        return Icons.terminal;
      case CredentialType.certificate:
        return Icons.verified_user;
      case CredentialType.token:
        return Icons.token;
      case CredentialType.cookie:
        return Icons.cookie;
      case CredentialType.apiKey:
        return Icons.api;
      case CredentialType.other:
        return Icons.key;
    }
  }

  Color get color {
    switch (this) {
      case CredentialType.plaintext:
        return AppColors.success;
      case CredentialType.ntlm:
        return AppColors.secondary;
      case CredentialType.kerberos:
        return AppColors.accent;
      case CredentialType.ssh:
        return AppColors.terminalGreen;
      case CredentialType.certificate:
        return AppColors.primary;
      case CredentialType.token:
        return AppColors.warning;
      case CredentialType.cookie:
        return const Color(0xFFFF9800);
      case CredentialType.apiKey:
        return AppColors.error;
      case CredentialType.other:
        return AppColors.textSecondary;
    }
  }
}

enum CredentialSource {
  responder,
  mimikatz,
  keylogger,
  browserDump,
  configFile,
  networkCapture,
  phishing,
  manual,
  other;

  static CredentialSource fromString(String? source) {
    switch (source?.toLowerCase()) {
      case 'responder':
      case 'llmnr':
      case 'nbns':
        return CredentialSource.responder;
      case 'mimikatz':
      case 'lsass':
        return CredentialSource.mimikatz;
      case 'keylogger':
      case 'keylog':
        return CredentialSource.keylogger;
      case 'browser':
      case 'browser_dump':
      case 'chrome':
      case 'firefox':
        return CredentialSource.browserDump;
      case 'config':
      case 'config_file':
      case 'file':
        return CredentialSource.configFile;
      case 'network':
      case 'capture':
      case 'pcap':
        return CredentialSource.networkCapture;
      case 'phishing':
      case 'portal':
        return CredentialSource.phishing;
      case 'manual':
        return CredentialSource.manual;
      default:
        return CredentialSource.other;
    }
  }

  String get displayName {
    switch (this) {
      case CredentialSource.responder:
        return 'Responder';
      case CredentialSource.mimikatz:
        return 'Mimikatz';
      case CredentialSource.keylogger:
        return 'Keylogger';
      case CredentialSource.browserDump:
        return 'Browser';
      case CredentialSource.configFile:
        return 'Config File';
      case CredentialSource.networkCapture:
        return 'Network';
      case CredentialSource.phishing:
        return 'Phishing';
      case CredentialSource.manual:
        return 'Manual';
      case CredentialSource.other:
        return 'Other';
    }
  }
}

class CredentialModel {
  final String id;
  final String dropboxId;
  final CredentialType type;
  final CredentialSource source;
  final String username;
  final String? domain;
  final String? password;
  final String? hash;
  final String? targetHost;
  final String? targetService;
  final DateTime capturedAt;
  final bool isCracked;
  final Map<String, dynamic>? metadata;

  CredentialModel({
    required this.id,
    required this.dropboxId,
    required this.type,
    required this.source,
    required this.username,
    this.domain,
    this.password,
    this.hash,
    this.targetHost,
    this.targetService,
    required this.capturedAt,
    this.isCracked = false,
    this.metadata,
  });

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    return CredentialModel(
      id: json['id'] ?? json['cred_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      type: CredentialType.fromString(json['type']),
      source: CredentialSource.fromString(json['source']),
      username: json['username'] ?? json['user'] ?? '',
      domain: json['domain'],
      password: json['password'] ?? json['pass'],
      hash: json['hash'],
      targetHost: json['target_host'] ?? json['host'] ?? json['target'],
      targetService: json['target_service'] ?? json['service'],
      capturedAt: json['captured_at'] != null 
          ? DateTime.parse(json['captured_at']) 
          : (json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now()),
      isCracked: json['is_cracked'] ?? json['cracked'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropbox_id': dropboxId,
      'type': type.name,
      'source': source.name,
      'username': username,
      'domain': domain,
      'password': password,
      'hash': hash,
      'target_host': targetHost,
      'target_service': targetService,
      'captured_at': capturedAt.toIso8601String(),
      'is_cracked': isCracked,
      'metadata': metadata,
    };
  }

  /// Get display username (with domain if available)
  String get displayUsername {
    if (domain != null && domain!.isNotEmpty) {
      return '$domain\\$username';
    }
    return username;
  }

  /// Get masked password for display
  String get maskedPassword {
    if (password == null || password!.isEmpty) return '••••••••';
    if (password!.length <= 4) return '••••••••';
    return '${password!.substring(0, 2)}${'•' * (password!.length - 4)}${password!.substring(password!.length - 2)}';
  }

  /// Get masked hash for display
  String get maskedHash {
    if (hash == null || hash!.isEmpty) return 'N/A';
    if (hash!.length <= 8) return hash!;
    return '${hash!.substring(0, 8)}...${hash!.substring(hash!.length - 8)}';
  }

  /// Check if this is a high-value credential
  bool get isHighValue {
    final lowerUser = username.toLowerCase();
    return lowerUser.contains('admin') ||
           lowerUser.contains('root') ||
           lowerUser.contains('system') ||
           lowerUser.contains('service') ||
           lowerUser.contains('sql') ||
           lowerUser.contains('backup') ||
           type == CredentialType.kerberos ||
           (domain != null && domain!.toLowerCase().contains('admin'));
  }

  /// Get time since capture
  String get capturedAgo {
    final diff = DateTime.now().difference(capturedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

// ============================================================
// HASH MODEL
// ============================================================

enum HashType {
  ntlm,
  netNtlmV1,
  netNtlmV2,
  kerberosTgs,
  kerberosAsRep,
  md5,
  sha1,
  sha256,
  bcrypt,
  other;

  static HashType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'ntlm':
      case 'nt':
        return HashType.ntlm;
      case 'netntlmv1':
      case 'net-ntlmv1':
        return HashType.netNtlmV1;
      case 'netntlmv2':
      case 'net-ntlmv2':
        return HashType.netNtlmV2;
      case 'kerberos_tgs':
      case 'tgs':
      case 'kerberoast':
        return HashType.kerberosTgs;
      case 'kerberos_asrep':
      case 'asrep':
      case 'asreproast':
        return HashType.kerberosAsRep;
      case 'md5':
        return HashType.md5;
      case 'sha1':
        return HashType.sha1;
      case 'sha256':
        return HashType.sha256;
      case 'bcrypt':
        return HashType.bcrypt;
      default:
        return HashType.other;
    }
  }

  String get displayName {
    switch (this) {
      case HashType.ntlm:
        return 'NTLM';
      case HashType.netNtlmV1:
        return 'Net-NTLMv1';
      case HashType.netNtlmV2:
        return 'Net-NTLMv2';
      case HashType.kerberosTgs:
        return 'Kerberoast';
      case HashType.kerberosAsRep:
        return 'AS-REP';
      case HashType.md5:
        return 'MD5';
      case HashType.sha1:
        return 'SHA-1';
      case HashType.sha256:
        return 'SHA-256';
      case HashType.bcrypt:
        return 'bcrypt';
      case HashType.other:
        return 'Other';
    }
  }

  /// Hashcat mode number
  int? get hashcatMode {
    switch (this) {
      case HashType.ntlm:
        return 1000;
      case HashType.netNtlmV1:
        return 5500;
      case HashType.netNtlmV2:
        return 5600;
      case HashType.kerberosTgs:
        return 13100;
      case HashType.kerberosAsRep:
        return 18200;
      case HashType.md5:
        return 0;
      case HashType.sha1:
        return 100;
      case HashType.sha256:
        return 1400;
      case HashType.bcrypt:
        return 3200;
      case HashType.other:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case HashType.ntlm:
        return AppColors.secondary;
      case HashType.netNtlmV1:
      case HashType.netNtlmV2:
        return AppColors.accent;
      case HashType.kerberosTgs:
      case HashType.kerberosAsRep:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

class HashModel {
  final String id;
  final String dropboxId;
  final HashType type;
  final String username;
  final String? domain;
  final String hash;
  final String? crackedPassword;
  final String? source;
  final DateTime capturedAt;
  final bool isCracked;
  final Map<String, dynamic>? metadata;

  HashModel({
    required this.id,
    required this.dropboxId,
    required this.type,
    required this.username,
    this.domain,
    required this.hash,
    this.crackedPassword,
    this.source,
    required this.capturedAt,
    this.isCracked = false,
    this.metadata,
  });

  factory HashModel.fromJson(Map<String, dynamic> json) {
    return HashModel(
      id: json['id'] ?? json['hash_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      type: HashType.fromString(json['type'] ?? json['hash_type']),
      username: json['username'] ?? json['user'] ?? '',
      domain: json['domain'],
      hash: json['hash'] ?? '',
      crackedPassword: json['cracked_password'] ?? json['password'],
      source: json['source'],
      capturedAt: json['captured_at'] != null 
          ? DateTime.parse(json['captured_at']) 
          : DateTime.now(),
      isCracked: json['is_cracked'] ?? json['cracked'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropbox_id': dropboxId,
      'type': type.name,
      'username': username,
      'domain': domain,
      'hash': hash,
      'cracked_password': crackedPassword,
      'source': source,
      'captured_at': capturedAt.toIso8601String(),
      'is_cracked': isCracked,
      'metadata': metadata,
    };
  }

  /// Get display username (with domain if available)
  String get displayUsername {
    if (domain != null && domain!.isNotEmpty) {
      return '$domain\\$username';
    }
    return username;
  }

  /// Get truncated hash for display
  String get truncatedHash {
    if (hash.length <= 32) return hash;
    return '${hash.substring(0, 16)}...${hash.substring(hash.length - 16)}';
  }

  /// Get hashcat command
  String get hashcatCommand {
    final mode = type.hashcatMode;
    if (mode == null) return '# Unknown hash type';
    return 'hashcat -m $mode hash.txt wordlist.txt';
  }
}

// ============================================================
// HOST MODEL
// ============================================================

enum HostOS {
  windows,
  linux,
  macos,
  networkDevice,
  printer,
  unknown;

  static HostOS fromString(String? os) {
    final lower = os?.toLowerCase() ?? '';
    if (lower.contains('windows')) return HostOS.windows;
    if (lower.contains('linux') || lower.contains('ubuntu') || lower.contains('debian')) return HostOS.linux;
    if (lower.contains('mac') || lower.contains('darwin') || lower.contains('osx')) return HostOS.macos;
    if (lower.contains('cisco') || lower.contains('router') || lower.contains('switch')) return HostOS.networkDevice;
    if (lower.contains('printer') || lower.contains('hp') || lower.contains('xerox')) return HostOS.printer;
    return HostOS.unknown;
  }

  String get displayName {
    switch (this) {
      case HostOS.windows:
        return 'Windows';
      case HostOS.linux:
        return 'Linux';
      case HostOS.macos:
        return 'macOS';
      case HostOS.networkDevice:
        return 'Network Device';
      case HostOS.printer:
        return 'Printer';
      case HostOS.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case HostOS.windows:
        return Icons.window;
      case HostOS.linux:
        return Icons.terminal;
      case HostOS.macos:
        return Icons.laptop_mac;
      case HostOS.networkDevice:
        return Icons.router;
      case HostOS.printer:
        return Icons.print;
      case HostOS.unknown:
        return Icons.device_unknown;
    }
  }

  Color get color {
    switch (this) {
      case HostOS.windows:
        return AppColors.secondary;
      case HostOS.linux:
        return AppColors.terminalGreen;
      case HostOS.macos:
        return AppColors.textSecondary;
      case HostOS.networkDevice:
        return AppColors.warning;
      case HostOS.printer:
        return AppColors.primary;
      case HostOS.unknown:
        return AppColors.textMuted;
    }
  }
}

class HostModel {
  final String id;
  final String dropboxId;
  final String ipAddress;
  final String? hostname;
  final String? macAddress;
  final HostOS os;
  final String? osVersion;
  final List<ServiceModel> services;
  final DateTime discoveredAt;
  final bool isAlive;
  final Map<String, dynamic>? metadata;

  HostModel({
    required this.id,
    required this.dropboxId,
    required this.ipAddress,
    this.hostname,
    this.macAddress,
    required this.os,
    this.osVersion,
    this.services = const [],
    required this.discoveredAt,
    this.isAlive = true,
    this.metadata,
  });

  factory HostModel.fromJson(Map<String, dynamic> json) {
    List<ServiceModel> services = [];
    if (json['services'] != null) {
      services = (json['services'] as List)
          .map((s) => ServiceModel.fromJson(s))
          .toList();
    }

    return HostModel(
      id: json['id'] ?? json['host_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      ipAddress: json['ip_address'] ?? json['ip'] ?? '',
      hostname: json['hostname'] ?? json['name'],
      macAddress: json['mac_address'] ?? json['mac'],
      os: HostOS.fromString(json['os'] ?? json['os_type']),
      osVersion: json['os_version'] ?? json['version'],
      services: services,
      discoveredAt: json['discovered_at'] != null 
          ? DateTime.parse(json['discovered_at']) 
          : DateTime.now(),
      isAlive: json['is_alive'] ?? json['alive'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropbox_id': dropboxId,
      'ip_address': ipAddress,
      'hostname': hostname,
      'mac_address': macAddress,
      'os': os.name,
      'os_version': osVersion,
      'services': services.map((s) => s.toJson()).toList(),
      'discovered_at': discoveredAt.toIso8601String(),
      'is_alive': isAlive,
      'metadata': metadata,
    };
  }

  /// Get display name (hostname or IP)
  String get displayName => hostname ?? ipAddress;

  /// Check if host has interesting services
  bool get hasInterestingServices {
    return services.any((s) => s.isInteresting);
  }

  /// Get count of open ports
  int get openPortCount => services.length;

  /// Check if this is potentially a high-value target
  bool get isHighValue {
    final lower = (hostname ?? '').toLowerCase();
    return lower.contains('dc') ||
           lower.contains('domain') ||
           lower.contains('sql') ||
           lower.contains('exchange') ||
           lower.contains('admin') ||
           lower.contains('backup') ||
           services.any((s) => s.port == 88 || s.port == 389 || s.port == 636);
  }
}

class ServiceModel {
  final int port;
  final String protocol;
  final String? service;
  final String? version;
  final String? banner;
  final bool isOpen;

  ServiceModel({
    required this.port,
    this.protocol = 'tcp',
    this.service,
    this.version,
    this.banner,
    this.isOpen = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      port: json['port'] ?? 0,
      protocol: json['protocol'] ?? 'tcp',
      service: json['service'] ?? json['name'],
      version: json['version'],
      banner: json['banner'],
      isOpen: json['is_open'] ?? json['open'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'port': port,
      'protocol': protocol,
      'service': service,
      'version': version,
      'banner': banner,
      'is_open': isOpen,
    };
  }

  /// Check if this is an interesting service for pentesting
  bool get isInteresting {
    final interestingPorts = [
      21, 22, 23, 25, 53, 80, 88, 110, 111, 135, 139, 143, 389, 443, 445,
      465, 587, 636, 993, 995, 1433, 1521, 2049, 3306, 3389, 5432, 5900,
      5985, 5986, 6379, 8080, 8443, 9200, 27017
    ];
    return interestingPorts.contains(port);
  }

  /// Get display string
  String get displayString {
    final svc = service ?? 'unknown';
    final ver = version != null ? ' ($version)' : '';
    return '$port/$protocol - $svc$ver';
  }
}

// ============================================================
// LOOT SUMMARY MODEL
// ============================================================

class LootSummaryModel {
  final int totalCredentials;
  final int totalHashes;
  final int totalHosts;
  final int crackedHashes;
  final int highValueCredentials;
  final Map<String, int> credentialsByType;
  final Map<String, int> hashesByType;
  final Map<String, int> hostsByOS;
  final DateTime? lastUpdated;

  LootSummaryModel({
    this.totalCredentials = 0,
    this.totalHashes = 0,
    this.totalHosts = 0,
    this.crackedHashes = 0,
    this.highValueCredentials = 0,
    this.credentialsByType = const {},
    this.hashesByType = const {},
    this.hostsByOS = const {},
    this.lastUpdated,
  });

  factory LootSummaryModel.fromJson(Map<String, dynamic> json) {
    return LootSummaryModel(
      totalCredentials: json['total_credentials'] ?? json['credentials'] ?? 0,
      totalHashes: json['total_hashes'] ?? json['hashes'] ?? 0,
      totalHosts: json['total_hosts'] ?? json['hosts'] ?? 0,
      crackedHashes: json['cracked_hashes'] ?? json['cracked'] ?? 0,
      highValueCredentials: json['high_value_credentials'] ?? json['high_value'] ?? 0,
      credentialsByType: Map<String, int>.from(json['credentials_by_type'] ?? {}),
      hashesByType: Map<String, int>.from(json['hashes_by_type'] ?? {}),
      hostsByOS: Map<String, int>.from(json['hosts_by_os'] ?? {}),
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_credentials': totalCredentials,
      'total_hashes': totalHashes,
      'total_hosts': totalHosts,
      'cracked_hashes': crackedHashes,
      'high_value_credentials': highValueCredentials,
      'credentials_by_type': credentialsByType,
      'hashes_by_type': hashesByType,
      'hosts_by_os': hostsByOS,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  /// Get total loot count
  int get totalLoot => totalCredentials + totalHashes;

  /// Get crack rate percentage
  double get crackRate {
    if (totalHashes == 0) return 0;
    return (crackedHashes / totalHashes) * 100;
  }
}