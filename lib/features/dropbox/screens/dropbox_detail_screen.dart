// lib/features/dropbox/screens/dropbox_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/dropbox_model.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../../dashboard/widgets/connection_status_bar.dart';

class DropboxDetailScreen extends StatefulWidget {
  final String dropboxId;

  const DropboxDetailScreen({
    super.key,
    required this.dropboxId,
  });

  @override
  State<DropboxDetailScreen> createState() => _DropboxDetailScreenState();
}

class _DropboxDetailScreenState extends State<DropboxDetailScreen>
    with SingleTickerProviderStateMixin {
  DropboxModel? _dropbox;
  List<HeartbeatModel> _heartbeats = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadData(silent: true);
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await ApiService.getDropboxDetail(widget.dropboxId);
      if (result.isSuccess && result.data != null) {
        _dropbox = result.data;
      } else {
        _error = result.error;
      }

      final heartbeatResult = await ApiService.getHeartbeatHistory(
        widget.dropboxId,
        limit: 20,
      );
      if (heartbeatResult.isSuccess && heartbeatResult.data != null) {
        _heartbeats = heartbeatResult.data!;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load dropbox',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CyberButton(
              label: 'Retry',
              onPressed: _loadData,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final dropbox = _dropbox!;
    
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // App bar
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              dropbox.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              StatusIndicator(isOnline: dropbox.status == DropboxStatus.online),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onPressed: _showOptionsMenu,
              ),
            ],
          ),
          
          // Header content
          SliverToBoxAdapter(
            child: _buildHeader(dropbox),
          ),
          
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              tabs: const ['Overview', 'Heartbeats', 'System'],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(dropbox),
          _buildHeartbeatsTab(),
          _buildSystemTab(dropbox),
        ],
      ),
    );
  }

  Widget _buildHeader(DropboxModel dropbox) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status card
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderColor: dropbox.status.color.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: dropbox.status.glowColor,
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
            child: Row(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: dropbox.status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.print,
                    size: 32,
                    color: dropbox.status.color,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: dropbox.status.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dropbox.status.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: dropbox.status.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (dropbox.stealthEnabled) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.visibility_off,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dropbox.hostname,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last seen: ${dropbox.lastSeenAgo}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 16),
          
          // Quick actions
          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: 'Scan',
                  icon: Icons.radar,
                  onPressed: () => _triggerScan(dropbox.id),
                  isOutlined: true,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CyberButton(
                  label: 'Exfil',
                  icon: Icons.cloud_upload,
                  onPressed: () => _triggerExfil(dropbox.id),
                  isOutlined: true,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CyberButton(
                  label: 'Terminal',
                  icon: Icons.terminal,
                  onPressed: () => _openTerminal(dropbox.id),
                  height: 44,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(DropboxModel dropbox) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Hosts',
                  value: dropbox.stats.hostsDiscovered.toString(),
                  icon: Icons.computer,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Credentials',
                  value: dropbox.stats.credentialsCaptured.toString(),
                  icon: Icons.key,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Hashes',
                  value: dropbox.stats.hashesCaptured.toString(),
                  icon: Icons.tag,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Scans',
                  value: dropbox.stats.scanCount.toString(),
                  icon: Icons.radar,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Network info
          _buildSectionTitle('Network Information'),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('IP Address', dropbox.ipAddress, copyable: true),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow('MAC Address', dropbox.macAddress, copyable: true),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow('Interface', dropbox.networkInterface ?? 'eth0'),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow('Target Network', dropbox.targetNetwork ?? 'Unknown'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // C2 Status
          _buildSectionTitle('C2 Channels'),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildC2Row('SSH Tunnel', dropbox.c2Status.sshConnected),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildC2Row('HTTPS Beacon', dropbox.c2Status.httpsBeaconActive),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildC2Row('DNS Channel', dropbox.c2Status.dnsChannelActive),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow(
                  'Beacon Interval',
                  '${dropbox.c2Status.beaconInterval}s',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeartbeatsTab() {
    if (_heartbeats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No heartbeat history',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _heartbeats.length,
      itemBuilder: (context, index) {
        final heartbeat = _heartbeats[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heartbeat.formattedTime,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        heartbeat.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Load: ${heartbeat.load}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      heartbeat.ipAddress,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'JetBrainsMono',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemTab(DropboxModel dropbox) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resource usage
          _buildSectionTitle('Resource Usage'),
          const SizedBox(height: 12),
          ProgressStatCard(
            label: 'CPU Usage',
            value: dropbox.stats.cpuUsagePercent,
            maxValue: 100,
            color: AppColors.primary,
            icon: Icons.memory,
          ),
          const SizedBox(height: 8),
          ProgressStatCard(
            label: 'Memory Usage',
            value: dropbox.stats.memoryUsagePercent,
            maxValue: 100,
            color: AppColors.secondary,
            icon: Icons.storage,
          ),
          const SizedBox(height: 8),
          ProgressStatCard(
            label: 'Disk Usage',
            value: dropbox.stats.diskUsagePercent,
            maxValue: 100,
            color: AppColors.accent,
            icon: Icons.disc_full,
          ),
          
          const SizedBox(height: 24),
          
          // System info
          _buildSectionTitle('System Information'),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Uptime', dropbox.uptime),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow('Load Average', dropbox.load),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow('Stealth Mode', dropbox.stealthEnabled ? 'Enabled' : 'Disabled'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Danger zone
          _buildSectionTitle('Danger Zone', color: AppColors.error),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.error.withOpacity(0.3),
            child: Column(
              children: [
                DangerButton(
                  label: 'Self-Destruct',
                  icon: Icons.local_fire_department,
                  isExpanded: true,
                  onPressed: () => _triggerSelfDestruct(dropbox.id),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: copyable ? 'JetBrainsMono' : null,
                color: AppColors.textPrimary,
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: $value'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildC2Row(String label, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withOpacity(0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.cardBorder,
            ),
          ),
          child: Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: AppColors.primary),
                  title: const Text('Refresh Data'),
                  onTap: () {
                    Navigator.pop(context);
                    _loadData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.secondary),
                  title: const Text('Rename Dropbox'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Rename dialog
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Remove Dropbox'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Remove confirmation
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerScan(String dropboxId) async {
    final result = await ApiService.triggerRecon(dropboxId: dropboxId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess ? 'Scan triggered' : 'Failed: ${result.error}',
          ),
        ),
      );
    }
  }

  void _triggerExfil(String dropboxId) async {
    final result = await ApiService.sendCommand(
      dropboxId: dropboxId,
      command: 'exfil_loot',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess ? 'Exfil triggered' : 'Failed: ${result.error}',
          ),
        ),
      );
    }
  }

  void _openTerminal(String dropboxId) {
    // TODO: Open terminal/command screen
  }

  void _triggerSelfDestruct(String dropboxId) {
    // Handled by DangerButton confirmation
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;

  _TabBarDelegate({
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}