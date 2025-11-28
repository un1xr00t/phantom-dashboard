// lib/core/models/alert_model.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AlertLevel {
  critical,
  high,
  warning,
  info,
  success;

  static AlertLevel fromString(String? level) {
    switch (level?.toLowerCase()) {
      case 'critical':
        return AlertLevel.critical;
      case 'high':
      case 'error':
        return AlertLevel.high;
      case 'warning':
      case 'warn':
        return AlertLevel.warning;
      case 'success':
        return AlertLevel.success;
      case 'info':
      default:
        return AlertLevel.info;
    }
  }

  String get displayName {
    switch (this) {
      case AlertLevel.critical:
        return 'CRITICAL';
      case AlertLevel.high:
        return 'HIGH';
      case AlertLevel.warning:
        return 'WARNING';
      case AlertLevel.info:
        return 'INFO';
      case AlertLevel.success:
        return 'SUCCESS';
    }
  }

  Color get color {
    switch (this) {
      case AlertLevel.critical:
        return AppColors.critical;
      case AlertLevel.high:
        return AppColors.error;
      case AlertLevel.warning:
        return AppColors.warning;
      case AlertLevel.info:
        return AppColors.primary;
      case AlertLevel.success:
        return AppColors.success;
    }
  }

  Color get glowColor {
    switch (this) {
      case AlertLevel.critical:
        return AppColors.errorGlow;
      case AlertLevel.high:
        return AppColors.errorGlow;
      case AlertLevel.warning:
        return AppColors.warningGlow;
      case AlertLevel.info:
        return AppColors.primaryGlow;
      case AlertLevel.success:
        return AppColors.successGlow;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AlertLevel.critical:
        return AppColors.critical.withOpacity(0.15);
      case AlertLevel.high:
        return AppColors.error.withOpacity(0.15);
      case AlertLevel.warning:
        return AppColors.warning.withOpacity(0.15);
      case AlertLevel.info:
        return AppColors.primary.withOpacity(0.15);
      case AlertLevel.success:
        return AppColors.success.withOpacity(0.15);
    }
  }

  IconData get icon {
    switch (this) {
      case AlertLevel.critical:
        return Icons.dangerous;
      case AlertLevel.high:
        return Icons.error;
      case AlertLevel.warning:
        return Icons.warning_amber;
      case AlertLevel.info:
        return Icons.info_outline;
      case AlertLevel.success:
        return Icons.check_circle;
    }
  }

  int get priority {
    switch (this) {
      case AlertLevel.critical:
        return 5;
      case AlertLevel.high:
        return 4;
      case AlertLevel.warning:
        return 3;
      case AlertLevel.info:
        return 2;
      case AlertLevel.success:
        return 1;
    }
  }
}

enum AlertType {
  online,
  offline,
  newCredentials,
  newHashes,
  reconComplete,
  commandExecuted,
  commandFailed,
  connectionLost,
  connectionRestored,
  selfDestruct,
  killSwitch,
  error,
  stealthDisabled,
  intrusionDetected,
  custom;

  static AlertType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'online':
        return AlertType.online;
      case 'offline':
        return AlertType.offline;
      case 'new_creds':
      case 'new_credentials':
      case 'credentials':
        return AlertType.newCredentials;
      case 'new_hashes':
      case 'hashes':
        return AlertType.newHashes;
      case 'recon_complete':
      case 'scan_complete':
        return AlertType.reconComplete;
      case 'command_executed':
      case 'cmd_success':
        return AlertType.commandExecuted;
      case 'command_failed':
      case 'cmd_failed':
        return AlertType.commandFailed;
      case 'connection_lost':
        return AlertType.connectionLost;
      case 'connection_restored':
        return AlertType.connectionRestored;
      case 'self_destruct':
      case 'selfdestruct':
        return AlertType.selfDestruct;
      case 'kill_switch':
      case 'killswitch':
        return AlertType.killSwitch;
      case 'error':
        return AlertType.error;
      case 'stealth_disabled':
        return AlertType.stealthDisabled;
      case 'intrusion_detected':
      case 'intrusion':
        return AlertType.intrusionDetected;
      default:
        return AlertType.custom;
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.online:
        return 'Dropbox Online';
      case AlertType.offline:
        return 'Dropbox Offline';
      case AlertType.newCredentials:
        return 'Credentials Captured';
      case AlertType.newHashes:
        return 'Hashes Captured';
      case AlertType.reconComplete:
        return 'Recon Complete';
      case AlertType.commandExecuted:
        return 'Command Executed';
      case AlertType.commandFailed:
        return 'Command Failed';
      case AlertType.connectionLost:
        return 'Connection Lost';
      case AlertType.connectionRestored:
        return 'Connection Restored';
      case AlertType.selfDestruct:
        return 'Self-Destruct';
      case AlertType.killSwitch:
        return 'Kill Switch';
      case AlertType.error:
        return 'Error';
      case AlertType.stealthDisabled:
        return 'Stealth Disabled';
      case AlertType.intrusionDetected:
        return 'Intrusion Detected';
      case AlertType.custom:
        return 'Alert';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.online:
        return Icons.power;
      case AlertType.offline:
        return Icons.power_off;
      case AlertType.newCredentials:
        return Icons.key;
      case AlertType.newHashes:
        return Icons.tag;
      case AlertType.reconComplete:
        return Icons.radar;
      case AlertType.commandExecuted:
        return Icons.terminal;
      case AlertType.commandFailed:
        return Icons.error_outline;
      case AlertType.connectionLost:
        return Icons.link_off;
      case AlertType.connectionRestored:
        return Icons.link;
      case AlertType.selfDestruct:
        return Icons.local_fire_department;
      case AlertType.killSwitch:
        return Icons.dangerous;
      case AlertType.error:
        return Icons.bug_report;
      case AlertType.stealthDisabled:
        return Icons.visibility_off;
      case AlertType.intrusionDetected:
        return Icons.shield;
      case AlertType.custom:
        return Icons.notifications;
    }
  }

  AlertLevel get defaultLevel {
    switch (this) {
      case AlertType.online:
        return AlertLevel.success;
      case AlertType.offline:
        return AlertLevel.warning;
      case AlertType.newCredentials:
        return AlertLevel.high;
      case AlertType.newHashes:
        return AlertLevel.high;
      case AlertType.reconComplete:
        return AlertLevel.info;
      case AlertType.commandExecuted:
        return AlertLevel.info;
      case AlertType.commandFailed:
        return AlertLevel.warning;
      case AlertType.connectionLost:
        return AlertLevel.high;
      case AlertType.connectionRestored:
        return AlertLevel.success;
      case AlertType.selfDestruct:
        return AlertLevel.critical;
      case AlertType.killSwitch:
        return AlertLevel.critical;
      case AlertType.error:
        return AlertLevel.high;
      case AlertType.stealthDisabled:
        return AlertLevel.warning;
      case AlertType.intrusionDetected:
        return AlertLevel.critical;
      case AlertType.custom:
        return AlertLevel.info;
    }
  }
}

class AlertModel {
  final String id;
  final String dropboxId;
  final String? dropboxName;
  final AlertType type;
  final AlertLevel level;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  AlertModel({
    required this.id,
    required this.dropboxId,
    this.dropboxName,
    required this.type,
    required this.level,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final type = AlertType.fromString(json['type']);
    final level = json['level'] != null 
        ? AlertLevel.fromString(json['level'])
        : type.defaultLevel;

    return AlertModel(
      id: json['id'] ?? json['alert_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      dropboxName: json['dropbox_name'] ?? json['name'],
      type: type,
      level: level,
      title: json['title'] ?? type.displayName,
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['is_read'] ?? json['read'] ?? false,
      metadata: json['metadata'] ?? json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropbox_id': dropboxId,
      'dropbox_name': dropboxName,
      'type': type.name,
      'level': level.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'metadata': metadata,
    };
  }

  /// Get time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  /// Get formatted timestamp
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date
  String get formattedDate {
    return '${timestamp.year}-'
           '${timestamp.month.toString().padLeft(2, '0')}-'
           '${timestamp.day.toString().padLeft(2, '0')}';
  }

  /// Get full formatted datetime
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  /// Create a copy with updated fields
  AlertModel copyWith({
    String? id,
    String? dropboxId,
    String? dropboxName,
    AlertType? type,
    AlertLevel? level,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AlertModel(
      id: id ?? this.id,
      dropboxId: dropboxId ?? this.dropboxId,
      dropboxName: dropboxName ?? this.dropboxName,
      type: type ?? this.type,
      level: level ?? this.level,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if alert is high priority (critical or high)
  bool get isHighPriority => level == AlertLevel.critical || level == AlertLevel.high;

  /// Check if this is a loot-related alert
  bool get isLootAlert => 
      type == AlertType.newCredentials || 
      type == AlertType.newHashes ||
      type == AlertType.reconComplete;

  /// Check if this is a connection-related alert
  bool get isConnectionAlert =>
      type == AlertType.online ||
      type == AlertType.offline ||
      type == AlertType.connectionLost ||
      type == AlertType.connectionRestored;

  /// Check if this is a danger alert
  bool get isDangerAlert =>
      type == AlertType.selfDestruct ||
      type == AlertType.killSwitch ||
      type == AlertType.intrusionDetected;
}

/// Helper class for grouping alerts by date
class AlertGroup {
  final String dateLabel;
  final DateTime date;
  final List<AlertModel> alerts;

  AlertGroup({
    required this.dateLabel,
    required this.date,
    required this.alerts,
  });

  /// Get unread count in this group
  int get unreadCount => alerts.where((a) => !a.isRead).length;

  /// Get high priority count
  int get highPriorityCount => alerts.where((a) => a.isHighPriority).length;
}

/// Extension for grouping alerts by date
extension AlertListExtension on List<AlertModel> {
  List<AlertGroup> groupByDate() {
    final Map<String, List<AlertModel>> grouped = {};
    
    for (final alert in this) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final alertDate = DateTime(alert.timestamp.year, alert.timestamp.month, alert.timestamp.day);
      
      String label;
      if (alertDate == today) {
        label = 'Today';
      } else if (alertDate == today.subtract(const Duration(days: 1))) {
        label = 'Yesterday';
      } else if (now.difference(alertDate).inDays < 7) {
        final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        label = weekdays[alertDate.weekday - 1];
      } else {
        label = '${alertDate.month}/${alertDate.day}/${alertDate.year}';
      }
      
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(alert);
    }
    
    return grouped.entries.map((e) => AlertGroup(
      dateLabel: e.key,
      date: e.value.first.timestamp,
      alerts: e.value,
    )).toList();
  }

  /// Filter by level
  List<AlertModel> filterByLevel(AlertLevel level) {
    return where((a) => a.level == level).toList();
  }

  /// Filter unread only
  List<AlertModel> get unreadOnly {
    return where((a) => !a.isRead).toList();
  }

  /// Sort by priority (highest first)
  List<AlertModel> sortByPriority() {
    final sorted = List<AlertModel>.from(this);
    sorted.sort((a, b) => b.level.priority.compareTo(a.level.priority));
    return sorted;
  }

  /// Sort by timestamp (newest first)
  List<AlertModel> sortByTime() {
    final sorted = List<AlertModel>.from(this);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }
}