// lib/core/models/command_model.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ============================================================
// COMMAND STATUS
// ============================================================

enum CommandStatus {
  pending,
  queued,
  executing,
  completed,
  failed,
  timeout,
  cancelled;

  static CommandStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return CommandStatus.pending;
      case 'queued':
        return CommandStatus.queued;
      case 'executing':
      case 'running':
        return CommandStatus.executing;
      case 'completed':
      case 'success':
      case 'done':
        return CommandStatus.completed;
      case 'failed':
      case 'error':
        return CommandStatus.failed;
      case 'timeout':
      case 'timed_out':
        return CommandStatus.timeout;
      case 'cancelled':
      case 'canceled':
        return CommandStatus.cancelled;
      default:
        return CommandStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case CommandStatus.pending:
        return 'Pending';
      case CommandStatus.queued:
        return 'Queued';
      case CommandStatus.executing:
        return 'Executing';
      case CommandStatus.completed:
        return 'Completed';
      case CommandStatus.failed:
        return 'Failed';
      case CommandStatus.timeout:
        return 'Timeout';
      case CommandStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case CommandStatus.pending:
        return AppColors.textMuted;
      case CommandStatus.queued:
        return AppColors.primary;
      case CommandStatus.executing:
        return AppColors.warning;
      case CommandStatus.completed:
        return AppColors.success;
      case CommandStatus.failed:
        return AppColors.error;
      case CommandStatus.timeout:
        return AppColors.warning;
      case CommandStatus.cancelled:
        return AppColors.textMuted;
    }
  }

  IconData get icon {
    switch (this) {
      case CommandStatus.pending:
        return Icons.schedule;
      case CommandStatus.queued:
        return Icons.queue;
      case CommandStatus.executing:
        return Icons.play_circle;
      case CommandStatus.completed:
        return Icons.check_circle;
      case CommandStatus.failed:
        return Icons.error;
      case CommandStatus.timeout:
        return Icons.timer_off;
      case CommandStatus.cancelled:
        return Icons.cancel;
    }
  }

  bool get isTerminal {
    return this == CommandStatus.completed ||
           this == CommandStatus.failed ||
           this == CommandStatus.timeout ||
           this == CommandStatus.cancelled;
  }

  bool get isActive {
    return this == CommandStatus.executing;
  }
}

// ============================================================
// COMMAND TYPE
// ============================================================

enum CommandType {
  // Recon commands
  scanNetwork,
  scanHost,
  scanPorts,
  
  // Collection commands
  runResponder,
  dumpCredentials,
  captureTraffic,
  
  // Stealth commands
  enableStealth,
  disableStealth,
  changeIdentity,
  
  // C2 commands
  checkIn,
  updateConfig,
  changeBeaconInterval,
  
  // Attack commands
  startMitm,
  stopMitm,
  deployPayload,
  
  // Exfil commands
  exfilLoot,
  syncData,
  
  // OPSEC commands
  clearLogs,
  selfDestruct,
  killSwitch,
  
  // System commands
  reboot,
  shutdown,
  executeShell,
  
  // Custom
  custom;

  static CommandType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'scan_network':
      case 'network_scan':
        return CommandType.scanNetwork;
      case 'scan_host':
      case 'host_scan':
        return CommandType.scanHost;
      case 'scan_ports':
      case 'port_scan':
        return CommandType.scanPorts;
      case 'run_responder':
      case 'responder':
        return CommandType.runResponder;
      case 'dump_credentials':
      case 'dump_creds':
        return CommandType.dumpCredentials;
      case 'capture_traffic':
      case 'pcap':
        return CommandType.captureTraffic;
      case 'enable_stealth':
      case 'stealth_on':
        return CommandType.enableStealth;
      case 'disable_stealth':
      case 'stealth_off':
        return CommandType.disableStealth;
      case 'change_identity':
      case 'new_identity':
        return CommandType.changeIdentity;
      case 'check_in':
      case 'checkin':
        return CommandType.checkIn;
      case 'update_config':
      case 'config_update':
        return CommandType.updateConfig;
      case 'change_beacon_interval':
      case 'beacon_interval':
        return CommandType.changeBeaconInterval;
      case 'start_mitm':
      case 'mitm_start':
        return CommandType.startMitm;
      case 'stop_mitm':
      case 'mitm_stop':
        return CommandType.stopMitm;
      case 'deploy_payload':
      case 'payload':
        return CommandType.deployPayload;
      case 'exfil_loot':
      case 'exfil':
        return CommandType.exfilLoot;
      case 'sync_data':
      case 'sync':
        return CommandType.syncData;
      case 'clear_logs':
      case 'wipe_logs':
        return CommandType.clearLogs;
      case 'self_destruct':
      case 'selfdestruct':
        return CommandType.selfDestruct;
      case 'kill_switch':
      case 'killswitch':
        return CommandType.killSwitch;
      case 'reboot':
        return CommandType.reboot;
      case 'shutdown':
        return CommandType.shutdown;
      case 'execute_shell':
      case 'shell':
      case 'exec':
        return CommandType.executeShell;
      default:
        return CommandType.custom;
    }
  }

  String get displayName {
    switch (this) {
      case CommandType.scanNetwork:
        return 'Scan Network';
      case CommandType.scanHost:
        return 'Scan Host';
      case CommandType.scanPorts:
        return 'Scan Ports';
      case CommandType.runResponder:
        return 'Run Responder';
      case CommandType.dumpCredentials:
        return 'Dump Credentials';
      case CommandType.captureTraffic:
        return 'Capture Traffic';
      case CommandType.enableStealth:
        return 'Enable Stealth';
      case CommandType.disableStealth:
        return 'Disable Stealth';
      case CommandType.changeIdentity:
        return 'Change Identity';
      case CommandType.checkIn:
        return 'Check In';
      case CommandType.updateConfig:
        return 'Update Config';
      case CommandType.changeBeaconInterval:
        return 'Change Beacon Interval';
      case CommandType.startMitm:
        return 'Start MITM';
      case CommandType.stopMitm:
        return 'Stop MITM';
      case CommandType.deployPayload:
        return 'Deploy Payload';
      case CommandType.exfilLoot:
        return 'Exfiltrate Loot';
      case CommandType.syncData:
        return 'Sync Data';
      case CommandType.clearLogs:
        return 'Clear Logs';
      case CommandType.selfDestruct:
        return 'Self-Destruct';
      case CommandType.killSwitch:
        return 'Kill Switch';
      case CommandType.reboot:
        return 'Reboot';
      case CommandType.shutdown:
        return 'Shutdown';
      case CommandType.executeShell:
        return 'Execute Shell';
      case CommandType.custom:
        return 'Custom Command';
    }
  }

  String get commandString {
    switch (this) {
      case CommandType.scanNetwork:
        return 'scan_network';
      case CommandType.scanHost:
        return 'scan_host';
      case CommandType.scanPorts:
        return 'scan_ports';
      case CommandType.runResponder:
        return 'run_responder';
      case CommandType.dumpCredentials:
        return 'dump_credentials';
      case CommandType.captureTraffic:
        return 'capture_traffic';
      case CommandType.enableStealth:
        return 'enable_stealth';
      case CommandType.disableStealth:
        return 'disable_stealth';
      case CommandType.changeIdentity:
        return 'change_identity';
      case CommandType.checkIn:
        return 'check_in';
      case CommandType.updateConfig:
        return 'update_config';
      case CommandType.changeBeaconInterval:
        return 'change_beacon_interval';
      case CommandType.startMitm:
        return 'start_mitm';
      case CommandType.stopMitm:
        return 'stop_mitm';
      case CommandType.deployPayload:
        return 'deploy_payload';
      case CommandType.exfilLoot:
        return 'exfil_loot';
      case CommandType.syncData:
        return 'sync_data';
      case CommandType.clearLogs:
        return 'clear_logs';
      case CommandType.selfDestruct:
        return 'self_destruct';
      case CommandType.killSwitch:
        return 'kill_switch';
      case CommandType.reboot:
        return 'reboot';
      case CommandType.shutdown:
        return 'shutdown';
      case CommandType.executeShell:
        return 'execute_shell';
      case CommandType.custom:
        return 'custom';
    }
  }

  IconData get icon {
    switch (this) {
      case CommandType.scanNetwork:
        return Icons.radar;
      case CommandType.scanHost:
        return Icons.computer;
      case CommandType.scanPorts:
        return Icons.settings_ethernet;
      case CommandType.runResponder:
        return Icons.wifi_tethering;
      case CommandType.dumpCredentials:
        return Icons.key;
      case CommandType.captureTraffic:
        return Icons.stream;
      case CommandType.enableStealth:
        return Icons.visibility_off;
      case CommandType.disableStealth:
        return Icons.visibility;
      case CommandType.changeIdentity:
        return Icons.shuffle;
      case CommandType.checkIn:
        return Icons.sync;
      case CommandType.updateConfig:
        return Icons.settings;
      case CommandType.changeBeaconInterval:
        return Icons.timer;
      case CommandType.startMitm:
        return Icons.swap_horiz;
      case CommandType.stopMitm:
        return Icons.block;
      case CommandType.deployPayload:
        return Icons.rocket_launch;
      case CommandType.exfilLoot:
        return Icons.upload;
      case CommandType.syncData:
        return Icons.cloud_sync;
      case CommandType.clearLogs:
        return Icons.cleaning_services;
      case CommandType.selfDestruct:
        return Icons.local_fire_department;
      case CommandType.killSwitch:
        return Icons.dangerous;
      case CommandType.reboot:
        return Icons.restart_alt;
      case CommandType.shutdown:
        return Icons.power_settings_new;
      case CommandType.executeShell:
        return Icons.terminal;
      case CommandType.custom:
        return Icons.code;
    }
  }

  Color get color {
    switch (this) {
      case CommandType.scanNetwork:
      case CommandType.scanHost:
      case CommandType.scanPorts:
        return AppColors.primary;
      case CommandType.runResponder:
      case CommandType.dumpCredentials:
      case CommandType.captureTraffic:
        return AppColors.secondary;
      case CommandType.enableStealth:
      case CommandType.disableStealth:
      case CommandType.changeIdentity:
        return AppColors.accent;
      case CommandType.checkIn:
      case CommandType.updateConfig:
      case CommandType.changeBeaconInterval:
        return AppColors.success;
      case CommandType.startMitm:
      case CommandType.stopMitm:
      case CommandType.deployPayload:
        return AppColors.warning;
      case CommandType.exfilLoot:
      case CommandType.syncData:
        return AppColors.terminalGreen;
      case CommandType.clearLogs:
        return AppColors.textSecondary;
      case CommandType.selfDestruct:
      case CommandType.killSwitch:
        return AppColors.critical;
      case CommandType.reboot:
      case CommandType.shutdown:
        return AppColors.error;
      case CommandType.executeShell:
        return AppColors.terminalGreen;
      case CommandType.custom:
        return AppColors.textSecondary;
    }
  }

  bool get isDangerous {
    return this == CommandType.selfDestruct ||
           this == CommandType.killSwitch ||
           this == CommandType.clearLogs ||
           this == CommandType.shutdown;
  }

  bool get requiresConfirmation {
    return isDangerous ||
           this == CommandType.reboot ||
           this == CommandType.disableStealth ||
           this == CommandType.deployPayload;
  }

  String? get description {
    switch (this) {
      case CommandType.scanNetwork:
        return 'Discover hosts on the local network using ARP and ping scans';
      case CommandType.scanHost:
        return 'Detailed scan of a specific host including OS detection';
      case CommandType.scanPorts:
        return 'Fast port scan on discovered hosts';
      case CommandType.runResponder:
        return 'Start Responder to capture LLMNR/NBT-NS hashes';
      case CommandType.dumpCredentials:
        return 'Attempt to dump credentials from memory or files';
      case CommandType.captureTraffic:
        return 'Start packet capture on the network interface';
      case CommandType.enableStealth:
        return 'Enable HP printer disguise and traffic shaping';
      case CommandType.disableStealth:
        return 'Disable stealth mode (increases detection risk)';
      case CommandType.changeIdentity:
        return 'Generate new MAC address and hostname';
      case CommandType.selfDestruct:
        return 'Securely wipe all data and evidence';
      case CommandType.killSwitch:
        return 'Emergency shutdown and wipe';
      default:
        return null;
    }
  }
}

// ============================================================
// COMMAND MODEL
// ============================================================

class CommandModel {
  final String id;
  final String dropboxId;
  final String? dropboxName;
  final CommandType type;
  final String command;
  final Map<String, dynamic>? args;
  final CommandStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final DateTime? completedAt;
  final String? output;
  final String? error;
  final int? exitCode;

  CommandModel({
    required this.id,
    required this.dropboxId,
    this.dropboxName,
    required this.type,
    required this.command,
    this.args,
    required this.status,
    required this.createdAt,
    this.executedAt,
    this.completedAt,
    this.output,
    this.error,
    this.exitCode,
  });

  factory CommandModel.fromJson(Map<String, dynamic> json) {
    return CommandModel(
      id: json['id'] ?? json['command_id'] ?? '',
      dropboxId: json['dropbox_id'] ?? '',
      dropboxName: json['dropbox_name'],
      type: CommandType.fromString(json['type'] ?? json['command_type']),
      command: json['command'] ?? '',
      args: json['args'] != null ? Map<String, dynamic>.from(json['args'] as Map) : null,
      status: CommandStatus.fromString(json['status']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      executedAt: json['executed_at'] != null 
          ? DateTime.parse(json['executed_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      output: json['output'],
      error: json['error'],
      exitCode: json['exit_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropbox_id': dropboxId,
      'dropbox_name': dropboxName,
      'type': type.commandString,
      'command': command,
      'args': args,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'executed_at': executedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'output': output,
      'error': error,
      'exit_code': exitCode,
    };
  }

  /// Get execution duration
  Duration? get executionDuration {
    if (executedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(executedAt!);
  }

  /// Get formatted duration string
  String get durationString {
    final duration = executionDuration;
    if (duration == null) return '-';
    
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  /// Get time since created
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Check if command was successful
  bool get isSuccess => status == CommandStatus.completed && (exitCode == null || exitCode == 0);

  /// Get truncated output for preview
  String get outputPreview {
    if (output == null || output!.isEmpty) return 'No output';
    if (output!.length <= 100) return output!;
    return '${output!.substring(0, 100)}...';
  }

  /// Copy with updated fields
  CommandModel copyWith({
    String? id,
    String? dropboxId,
    String? dropboxName,
    CommandType? type,
    String? command,
    Map<String, dynamic>? args,
    CommandStatus? status,
    DateTime? createdAt,
    DateTime? executedAt,
    DateTime? completedAt,
    String? output,
    String? error,
    int? exitCode,
  }) {
    return CommandModel(
      id: id ?? this.id,
      dropboxId: dropboxId ?? this.dropboxId,
      dropboxName: dropboxName ?? this.dropboxName,
      type: type ?? this.type,
      command: command ?? this.command,
      args: args ?? this.args,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      executedAt: executedAt ?? this.executedAt,
      completedAt: completedAt ?? this.completedAt,
      output: output ?? this.output,
      error: error ?? this.error,
      exitCode: exitCode ?? this.exitCode,
    );
  }
}

// ============================================================
// COMMAND RESULT MODEL
// ============================================================

class CommandResultModel {
  final String commandId;
  final bool success;
  final String? message;
  final String? output;
  final String? error;
  final int? exitCode;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  CommandResultModel({
    required this.commandId,
    required this.success,
    this.message,
    this.output,
    this.error,
    this.exitCode,
    required this.timestamp,
    this.data,
  });

  factory CommandResultModel.fromJson(Map<String, dynamic> json) {
    return CommandResultModel(
      commandId: json['command_id'] ?? json['id'] ?? '',
      success: json['success'] ?? json['status'] == 'ok',
      message: json['message'],
      output: json['output'],
      error: json['error'],
      exitCode: json['exit_code'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command_id': commandId,
      'success': success,
      'message': message,
      'output': output,
      'error': error,
      'exit_code': exitCode,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

// ============================================================
// QUICK COMMAND TEMPLATES
// ============================================================

class QuickCommand {
  final String name;
  final String description;
  final CommandType type;
  final Map<String, dynamic>? defaultArgs;
  final IconData icon;
  final Color color;
  final bool isDangerous;

  const QuickCommand({
    required this.name,
    required this.description,
    required this.type,
    this.defaultArgs,
    required this.icon,
    required this.color,
    this.isDangerous = false,
  });

  static List<QuickCommand> get reconCommands => [
    QuickCommand(
      name: 'Full Network Scan',
      description: 'Discover all hosts and services on the network',
      type: CommandType.scanNetwork,
      defaultArgs: {'scan_type': 'full'},
      icon: Icons.radar,
      color: AppColors.primary,
    ),
    QuickCommand(
      name: 'Quick Scan',
      description: 'Fast host discovery only',
      type: CommandType.scanNetwork,
      defaultArgs: {'scan_type': 'quick'},
      icon: Icons.speed,
      color: AppColors.primary,
    ),
    QuickCommand(
      name: 'Port Scan',
      description: 'Scan common ports on discovered hosts',
      type: CommandType.scanPorts,
      defaultArgs: {'ports': 'common'},
      icon: Icons.settings_ethernet,
      color: AppColors.secondary,
    ),
  ];

  static List<QuickCommand> get collectionCommands => [
    QuickCommand(
      name: 'Start Responder',
      description: 'Capture LLMNR/NBT-NS/mDNS hashes',
      type: CommandType.runResponder,
      defaultArgs: {'mode': 'analyze'},
      icon: Icons.wifi_tethering,
      color: AppColors.accent,
    ),
    QuickCommand(
      name: 'Sync Loot',
      description: 'Upload collected data to C2',
      type: CommandType.exfilLoot,
      icon: Icons.cloud_upload,
      color: AppColors.success,
    ),
  ];

  static List<QuickCommand> get dangerCommands => [
    QuickCommand(
      name: 'Clear Logs',
      description: 'Securely delete all log files',
      type: CommandType.clearLogs,
      icon: Icons.cleaning_services,
      color: AppColors.warning,
      isDangerous: true,
    ),
    QuickCommand(
      name: 'Self-Destruct',
      description: 'Wipe all data and evidence',
      type: CommandType.selfDestruct,
      defaultArgs: {'level': 'standard'},
      icon: Icons.local_fire_department,
      color: AppColors.critical,
      isDangerous: true,
    ),
    QuickCommand(
      name: 'Kill Switch',
      description: 'Emergency shutdown and wipe',
      type: CommandType.killSwitch,
      icon: Icons.dangerous,
      color: AppColors.critical,
      isDangerous: true,
    ),
  ];
} 