// lib/features/loot/screens/loot_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/loot_model.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';
import '../../shared/widgets/cyber_text_field.dart';
import '../../dashboard/widgets/stat_card.dart';

class LootBrowserScreen extends StatefulWidget {
  const LootBrowserScreen({super.key});

  @override
  State<LootBrowserScreen> createState() => _LootBrowserScreenState();
}

class _LootBrowserScreenState extends State<LootBrowserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  LootSummaryModel? _summary;
  List<CredentialModel> _credentials = [];
  List<HashModel> _hashes = [];
  List<HostModel> _hosts = [];
  
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load summary
      final summaryResult = await ApiService.getLootSummary();
      if (summaryResult.isSuccess) {
        _summary = summaryResult.data;
      }

      // Load credentials
      final credsResult = await ApiService.getCredentials();
      if (credsResult.isSuccess) {
        _credentials = credsResult.data ?? [];
      }

      // Load hashes
      final hashesResult = await ApiService.getHashes();
      if (hashesResult.isSuccess) {
        _hashes = hashesResult.data ?? [];
      }

      // Load hosts
      final hostsResult = await ApiService.getDiscoveredHosts();
      if (hostsResult.isSuccess) {
        _hosts = hostsResult.data ?? [];
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

  List<CredentialModel> get _filteredCreds {
    if (_searchQuery.isEmpty) return _credentials;
    final query = _searchQuery.toLowerCase();
    return _credentials.where((c) =>
      c.username.toLowerCase().contains(query) ||
      (c.domain?.toLowerCase().contains(query) ?? false) ||
      (c.targetHost?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  List<HashModel> get _filteredHashes {
    if (_searchQuery.isEmpty) return _hashes;
    final query = _searchQuery.toLowerCase();
    return _hashes.where((h) =>
      h.username.toLowerCase().contains(query) ||
      (h.domain?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  List<HostModel> get _filteredHosts {
    if (_searchQuery.isEmpty) return _hosts;
    final query = _searchQuery.toLowerCase();
    return _hosts.where((h) =>
      h.ipAddress.toLowerCase().contains(query) ||
      (h.hostname?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Stats summary
          if (_summary != null) _buildStatsSummary(),
          
          // Search bar
          _buildSearchBar(),
          
          // Tab bar
          _buildTabBar(),
          
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCredentialsTab(),
                          _buildHashesTab(),
                          _buildHostsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Loot',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          CyberIconButton(
            icon: Icons.file_download,
            onPressed: _exportLoot,
            tooltip: 'Export',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatsSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              icon: Icons.key,
              value: _summary!.totalCredentials.toString(),
              label: 'Creds',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.tag,
              value: _summary!.totalHashes.toString(),
              label: 'Hashes',
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.computer,
              value: _summary!.totalHosts.toString(),
              label: 'Hosts',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.check_circle,
              value: '${_summary!.crackRate.toStringAsFixed(0)}%',
              label: 'Cracked',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CyberSearchField(
        hint: 'Search loot...',
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.key, size: 16),
                const SizedBox(width: 6),
                Text('Creds (${_filteredCreds.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tag, size: 16),
                const SizedBox(width: 6),
                Text('Hashes (${_filteredHashes.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.computer, size: 16),
                const SizedBox(width: 6),
                Text('Hosts (${_filteredHosts.length})'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load loot', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          CyberButton(
            label: 'Retry',
            onPressed: _loadData,
            icon: Icons.refresh,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsTab() {
    if (_filteredCreds.isEmpty) {
      return _buildEmptyTab('No credentials captured yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredCreds.length,
      itemBuilder: (context, index) {
        final cred = _filteredCreds[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCredentialCard(cred),
        );
      },
    );
  }

  Widget _buildCredentialCard(CredentialModel cred) {
    return GlassContainer(
      onTap: () => _showCredentialDetail(cred),
      padding: const EdgeInsets.all(16),
      borderColor: cred.isHighValue 
          ? AppColors.warning.withOpacity(0.3) 
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cred.type.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              cred.type.icon,
              size: 20,
              color: cred.type.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cred.displayUsername,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cred.isHighValue)
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${cred.type.displayName} • ${cred.source.displayName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (cred.targetHost != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    cred.targetHost!,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHashesTab() {
    if (_filteredHashes.isEmpty) {
      return _buildEmptyTab('No hashes captured yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredHashes.length,
      itemBuilder: (context, index) {
        final hash = _filteredHashes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildHashCard(hash),
        );
      },
    );
  }

  Widget _buildHashCard(HashModel hash) {
    return GlassContainer(
      onTap: () => _showHashDetail(hash),
      padding: const EdgeInsets.all(16),
      borderColor: hash.isCracked ? AppColors.success.withOpacity(0.3) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hash.type.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tag,
              size: 20,
              color: hash.type.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hash.displayUsername,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hash.isCracked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CRACKED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hash.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hash.truncatedHash,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: AppColors.textMuted),
            onPressed: () => _copyHash(hash),
          ),
        ],
      ),
    );
  }

  Widget _buildHostsTab() {
    if (_filteredHosts.isEmpty) {
      return _buildEmptyTab('No hosts discovered yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredHosts.length,
      itemBuilder: (context, index) {
        final host = _filteredHosts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildHostCard(host),
        );
      },
    );
  }

  Widget _buildHostCard(HostModel host) {
    return GlassContainer(
      onTap: () => _showHostDetail(host),
      padding: const EdgeInsets.all(16),
      borderColor: host.isHighValue ? AppColors.warning.withOpacity(0.3) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: host.os.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              host.os.icon,
              size: 20,
              color: host.os.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  host.ipAddress,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.textSecondary,
                  ),
                ),
                if (host.services.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${host.openPortCount} open ports',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: host.isAlive ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                host.os.displayName,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCredentialDetail(CredentialModel cred) {
    Navigator.pushNamed(
      context,
      AppRouter.credentialDetail,
      arguments: {'credentialId': cred.id},
    );
  }

  void _showHashDetail(HashModel hash) {
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
              Text(
                hash.displayUsername,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hash.type.displayName,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  hash.hash,
                  style: AppTextStyles.codeSmall,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hashcat Command:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  hash.hashcatCommand,
                  style: AppTextStyles.terminalSmall,
                ),
              ),
              const SizedBox(height: 24),
              CyberButton(
                label: 'Copy Hash',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: hash.hash));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hash copied')),
                  );
                },
                icon: Icons.copy,
                isExpanded: true,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHostDetail(HostModel host) {
    // TODO: Navigate to host detail or show bottom sheet
  }

  void _copyHash(HashModel hash) {
    Clipboard.setData(ClipboardData(text: hash.hash));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hash copied to clipboard')),
    );
    HapticFeedback.mediumImpact();
  }

  void _exportLoot() {
    // TODO: Export functionality
  }
}