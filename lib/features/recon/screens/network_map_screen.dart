// lib/features/recon/screens/network_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/loot_model.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';

class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({super.key});

  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen> {
  List<HostModel> _hosts = [];
  bool _isLoading = true;
  String? _selectedSubnet;

  @override
  void initState() {
    super.initState();
    _loadHosts();
  }

  Future<void> _loadHosts() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getDiscoveredHosts();
      if (result.isSuccess && result.data != null) {
        _hosts = result.data!;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, List<HostModel>> get _hostsBySubnet {
    final Map<String, List<HostModel>> grouped = {};
    for (final host in _hosts) {
      final parts = host.ipAddress.split('.');
      if (parts.length == 4) {
        final subnet = '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
        grouped.putIfAbsent(subnet, () => []);
        grouped[subnet]!.add(host);
      }
    }
    return grouped;
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hosts.isEmpty
                        ? _buildEmptyState()
                        : _buildNetworkView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Network Map',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          CyberIconButton(
            icon: Icons.refresh,
            onPressed: _loadHosts,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.lan_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Hosts Discovered',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run a network scan to discover hosts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkView() {
    final subnets = _hostsBySubnet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats bar
          _buildStatsBar(),
          const SizedBox(height: 24),

          // Subnets
          ...subnets.entries.map((entry) {
            return _buildSubnetSection(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalHosts = _hosts.length;
    final aliveHosts = _hosts.where((h) => h.isAlive).length;
    final windowsHosts = _hosts.where((h) => h.os == HostOS.windows).length;
    final linuxHosts = _hosts.where((h) => h.os == HostOS.linux).length;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalHosts.toString(), AppColors.primary),
          _buildStatItem('Alive', aliveHosts.toString(), AppColors.success),
          _buildStatItem('Windows', windowsHosts.toString(), AppColors.secondary),
          _buildStatItem('Linux', linuxHosts.toString(), AppColors.terminalGreen),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSubnetSection(String subnet, List<HostModel> hosts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subnet header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.lan, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                subnet,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrainsMono',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${hosts.length} hosts',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Host grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hosts.map((host) => _buildHostNode(host)).toList(),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHostNode(HostModel host) {
    return GlassContainer(
      onTap: () => _showHostDetail(host),
      padding: const EdgeInsets.all(12),
      borderColor: host.isHighValue
          ? AppColors.warning.withOpacity(0.3)
          : host.os.color.withOpacity(0.2),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(host.os.icon, size: 18, color: host.os.color),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: host.isAlive ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              host.ipAddress,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrainsMono',
                color: AppColors.textPrimary,
              ),
            ),
            if (host.hostname != null) ...[
              const SizedBox(height: 2),
              Text(
                host.hostname!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${host.openPortCount} ports',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHostDetail(HostModel host) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(host.os.icon, size: 24, color: host.os.color),
                  const SizedBox(width: 12),
                  Text(
                    host.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('IP Address', host.ipAddress),
              if (host.macAddress != null)
                _buildDetailRow('MAC Address', host.macAddress!),
              _buildDetailRow('OS', host.os.displayName),
              _buildDetailRow('Open Ports', host.openPortCount.toString()),
              
              if (host.services.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: host.services.take(10).map((svc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: svc.isInteresting
                            ? AppColors.warning.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: svc.isInteresting
                              ? AppColors.warning.withOpacity(0.3)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        '${svc.port}/${svc.service ?? "unknown"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              CyberButton(
                label: 'Scan Host',
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Trigger host scan
                },
                icon: Icons.radar,
                isExpanded: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'JetBrainsMono',
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}