// lib/core/models/dropbox_model.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum DropboxStatus {
  online,
  offline,
  connecting,
  warning,
  unknown;

  static DropboxStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return DropboxStatus.online;
      case 'offline':
        return DropboxStatus.offline;
      case 'connecting':
        return DropboxStatus.connecting;
      case 'warning':
        return DropboxStatus.warning;
      default:
        return DropboxStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case DropboxStatus.online:
        return 'Online';
      case DropboxStatus.offline:
        return 'Offline';
      case DropboxStatus.connecting:
        return 'Connecting';
      case DropboxStatus.warning:
        return 'Warning';
      case DropboxStatus.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case DropboxStatus.online:
        return AppColors.online;
      case DropboxStatus.offline:
        return AppColors.offline;
      case DropboxStatus.connecting:
        return AppColors.connecting;
      case DropboxStatus.warning:
        return AppColors.warning;
      case DropboxStatus.unknown:
        return AppColors.textMuted;
    }
  }

  Color get glowColor {
    switch (this) {
      case DropboxStatus.online:
        return AppColors.successGlow;
      case DropboxStatus.offline:
        return Colors.transparent;
      case DropboxStatus.connecting:
        return AppColors.warningGlow;
      case DropboxStatus.warning:
        return AppColors.warningGlow;
      case DropboxStatus.unknown:
        return Colors.transparent;
    }
  }

  IconData get icon {
    switch (this) {
      case DropboxStatus.online:
        return Icons.check_circle;
      case DropboxStatus.offline:
        return Icons.cancel;
      case DropboxStatus.connecting:
        return Icons.sync;
      case DropboxStatus.warning:
        return Icons.warning;
      case DropboxStatus.unknown:
        return Icons.help_outline;
    }
  }
}

class DropboxModel {
  final String id;
  final String name;
  final String hostname;
  final String ipAddress;
  final String macAddress;
  final DropboxStatus status;
  final DateTime? lastSeen;
  final String uptime;
  final String load;
  final String? networkInterface;
  final String? targetNetwork;
  final DropboxStatsModel stats;
  final DropboxC2Model c2Status;
  final bool stealthEnabled;
  final String? currentOperation;

  DropboxModel({
    required this.id,
    required this.name,
    required this.hostname,
    required this.ipAddress,
    required this.macAddress,
    required this.status,
    this.lastSeen,
    required this.uptime,
    required this.load,
    this.networkInterface,
    this.targetNetwork,
    required this.stats,
    required this.c2Status,
    this.stealthEnabled = true,
    this.currentOperation,
  });

  factory DropboxModel.fromJson(Map<String, dynamic> json) {
    return DropboxModel(
      id: json['dropbox_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['dropbox_id'] ?? 'Unknown',
      hostname: json['hostname'] ?? 'Unknown',
      ipAddress: json['ip_address'] ?? json['ip'] ?? '0.0.0.0',
      macAddress: json['mac_address'] ?? json['mac'] ?? '00:00:00:00:00:00',
      status: DropboxStatus.fromString(json['status']),
      lastSeen: json['last_seen'] != null 
          ? DateTime.tryParse(json['last_seen']) 
          : (json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null),
      uptime: json['uptime'] ?? 'Unknown',
      load: json['load']?.toString() ?? '0.00',
      networkInterface: json['network_interface'] ?? json['interface'],
      targetNetwork: json['target_network'] ?? json['network'],
      stats: DropboxStatsModel.fromJson(json['stats'] ?? {}),
      c2Status: DropboxC2Model.fromJson(json['c2_status'] ?? json['c2'] ?? {}),
      stealthEnabled: json['stealth_enabled'] ?? json['stealth'] ?? true,
      currentOperation: json['current_operation'] ?? json['operation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dropbox_id': id,
      'name': name,
      'hostname': hostname,
      'ip_address': ipAddress,
      'mac_address': macAddress,
      'status': status.name,
      'last_seen': lastSeen?.toIso8601String(),
      'uptime': uptime,
      'load': load,
      'network_interface': networkInterface,
      'target_network': targetNetwork,
      'stats': stats.toJson(),
      'c2_status': c2Status.toJson(),
      'stealth_enabled': stealthEnabled,
      'current_operation': currentOperation,
    };
  }

  /// Check if dropbox is considered stale (no heartbeat in X minutes)
  bool get isStale {
    if (lastSeen == null) return true;
    final diff = DateTime.now().difference(lastSeen!);
    return diff.inMinutes > 5; // Consider stale after 5 minutes
  }

  /// Get time since last seen as human-readable string
  String get lastSeenAgo {
    if (lastSeen == null) return 'Never';
    final diff = DateTime.now().difference(lastSeen!);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Create a copy with updated fields
  DropboxModel copyWith({
    String? id,
    String? name,
    String? hostname,
    String? ipAddress,
    String? macAddress,
    DropboxStatus? status,
    DateTime? lastSeen,
    String? uptime,
    String? load,
    String? networkInterface,
    String? targetNetwork,
    DropboxStatsModel? stats,
    DropboxC2Model? c2Status,
    bool? stealthEnabled,
    String? currentOperation,
  }) {
    return DropboxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      uptime: uptime ?? this.uptime,
      load: load ?? this.load,
      networkInterface: networkInterface ?? this.networkInterface,
      targetNetwork: targetNetwork ?? this.targetNetwork,
      stats: stats ?? this.stats,
      c2Status: c2Status ?? this.c2Status,
      stealthEnabled: stealthEnabled ?? this.stealthEnabled,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }
}

class DropboxStatsModel {
  final int hostsDiscovered;
  final int credentialsCaptured;
  final int hashesCaptured;
  final int alertsTriggered;
  final int commandsExecuted;
  final int scanCount;
  final double diskUsagePercent;
  final double memoryUsagePercent;
  final double cpuUsagePercent;

  DropboxStatsModel({
    this.hostsDiscovered = 0,
    this.credentialsCaptured = 0,
    this.hashesCaptured = 0,
    this.alertsTriggered = 0,
    this.commandsExecuted = 0,
    this.scanCount = 0,
    this.diskUsagePercent = 0.0,
    this.memoryUsagePercent = 0.0,
    this.cpuUsagePercent = 0.0,
  });

  factory DropboxStatsModel.fromJson(Map<String, dynamic> json) {
    return DropboxStatsModel(
      hostsDiscovered: json['hosts_discovered'] ?? json['hosts'] ?? 0,
      credentialsCaptured: json['credentials_captured'] ?? json['credentials'] ?? 0,
      hashesCaptured: json['hashes_captured'] ?? json['hashes'] ?? 0,
      alertsTriggered: json['alerts_triggered'] ?? json['alerts'] ?? 0,
      commandsExecuted: json['commands_executed'] ?? json['commands'] ?? 0,
      scanCount: json['scan_count'] ?? json['scans'] ?? 0,
      diskUsagePercent: (json['disk_usage'] ?? json['disk'] ?? 0.0).toDouble(),
      memoryUsagePercent: (json['memory_usage'] ?? json['memory'] ?? 0.0).toDouble(),
      cpuUsagePercent: (json['cpu_usage'] ?? json['cpu'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hosts_discovered': hostsDiscovered,
      'credentials_captured': credentialsCaptured,
      'hashes_captured': hashesCaptured,
      'alerts_triggered': alertsTriggered,
      'commands_executed': commandsExecuted,
      'scan_count': scanCount,
      'disk_usage': diskUsagePercent,
      'memory_usage': memoryUsagePercent,
      'cpu_usage': cpuUsagePercent,
    };
  }

  int get totalLoot => credentialsCaptured + hashesCaptured;
}

class DropboxC2Model {
  final bool sshConnected;
  final bool httpsBeaconActive;
  final bool dnsChannelActive;
  final String? primaryChannel;
  final DateTime? lastBeacon;
  final int beaconInterval;
  final int failedAttempts;

  DropboxC2Model({
    this.sshConnected = false,
    this.httpsBeaconActive = false,
    this.dnsChannelActive = false,
    this.primaryChannel,
    this.lastBeacon,
    this.beaconInterval = 60,
    this.failedAttempts = 0,
  });

  factory DropboxC2Model.fromJson(Map<String, dynamic> json) {
    return DropboxC2Model(
      sshConnected: json['ssh_connected'] ?? json['ssh'] ?? false,
      httpsBeaconActive: json['https_beacon_active'] ?? json['https'] ?? false,
      dnsChannelActive: json['dns_channel_active'] ?? json['dns'] ?? false,
      primaryChannel: json['primary_channel'] ?? json['channel'],
      lastBeacon: json['last_beacon'] != null 
          ? DateTime.tryParse(json['last_beacon']) 
          : null,
      beaconInterval: json['beacon_interval'] ?? json['interval'] ?? 60,
      failedAttempts: json['failed_attempts'] ?? json['failures'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssh_connected': sshConnected,
      'https_beacon_active': httpsBeaconActive,
      'dns_channel_active': dnsChannelActive,
      'primary_channel': primaryChannel,
      'last_beacon': lastBeacon?.toIso8601String(),
      'beacon_interval': beaconInterval,
      'failed_attempts': failedAttempts,
    };
  }

  /// Check if any C2 channel is active
  bool get hasActiveChannel => sshConnected || httpsBeaconActive || dnsChannelActive;

  /// Get count of active channels
  int get activeChannelCount {
    int count = 0;
    if (sshConnected) count++;
    if (httpsBeaconActive) count++;
    if (dnsChannelActive) count++;
    return count;
  }

  /// Get status color based on C2 health
  Color get statusColor {
    if (sshConnected) return AppColors.online;
    if (httpsBeaconActive || dnsChannelActive) return AppColors.warning;
    return AppColors.offline;
  }
}

class HeartbeatModel {
  final String id;
  final String dropboxId;
  final DateTime timestamp;
  final String ipAddress;
  final String hostname;
  final String macAddress;
  final String uptime;
  final String load;
  final Map<String, dynamic>? systemInfo;

  HeartbeatModel({
    required this.id,
    required this.dropboxId,
    required this.timestamp,
    required this.ipAddress,
    required this.hostname,
    required this.macAddress,
    required this.uptime,
    required this.load,
    this.systemInfo,
  });

  factory HeartbeatModel.fromJson(Map<String, dynamic> json) {
    return HeartbeatModel(
      id: json['id'] ?? json['heartbeat_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      ipAddress: json['ip_address'] ?? json['ip'] ?? '0.0.0.0',
      hostname: json['hostname'] ?? 'Unknown',
      macAddress: json['mac_address'] ?? json['mac'] ?? '00:00:00:00:00:00',
      uptime: json['uptime'] ?? 'Unknown',
      load: json['load']?.toString() ?? '0.00',
      systemInfo: json['system_info'] ?? json['system'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropbox_id': dropboxId,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'hostname': hostname,
      'mac_address': macAddress,
      'uptime': uptime,
      'load': load,
      'system_info': systemInfo,
    };
  }

  /// Get formatted timestamp
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Get formatted date
  String get formattedDate {
    return '${timestamp.year}-'
           '${timestamp.month.toString().padLeft(2, '0')}-'
           '${timestamp.day.toString().padLeft(2, '0')}';
  }
}