// lib/features/dashboard/screens/dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/dropbox_model.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';
import '../widgets/dropbox_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/connection_status_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  List<DropboxModel> _dropboxes = [];
  List<AlertModel> _recentAlerts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Timer? _refreshTimer;

  // Stats
  int _totalHosts = 0;
  int _totalCreds = 0;
  int _totalHashes = 0;
  int _activeDropboxes = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
      // Load dropboxes
      final dropboxResult = await ApiService.getDropboxes();
      if (dropboxResult.isSuccess && dropboxResult.data != null) {
        _dropboxes = dropboxResult.data!;
        _activeDropboxes = _dropboxes.where((d) => d.status == DropboxStatus.online).length;
        
        // Calculate totals
        _totalHosts = 0;
        _totalCreds = 0;
        _totalHashes = 0;
        for (final dropbox in _dropboxes) {
          _totalHosts += dropbox.stats.hostsDiscovered;
          _totalCreds += dropbox.stats.credentialsCaptured;
          _totalHashes += dropbox.stats.hashesCaptured;
        }
      }

      // Load recent alerts
      final alertResult = await ApiService.getAlerts(limit: 5);
      if (alertResult.isSuccess && alertResult.data != null) {
        _recentAlerts = alertResult.data!;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // Connection status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConnectionStatusBar(
                  isConnected: _activeDropboxes > 0,
                  dropboxCount: _dropboxes.length,
                  activeCount: _activeDropboxes,
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Stats grid
            SliverToBoxAdapter(
              child: _buildStatsGrid(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Dropboxes section
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Dropboxes',
                actionLabel: 'Add New',
                onAction: () {
                  // TODO: Add new dropbox flow
                },
              ),
            ),

            // Dropbox list or empty state
            if (_isLoading)
              SliverToBoxAdapter(
                child: _buildLoadingState(),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: _buildErrorState(),
              )
            else if (_dropboxes.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dropbox = _dropboxes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropboxCard(
                          dropbox: dropbox,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.dropboxDetail,
                              arguments: {'dropboxId': dropbox.id},
                            );
                          },
                        ),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 100 * index),
                        duration: 400.ms,
                      );
                    },
                    childCount: _dropboxes.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Recent alerts section
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Recent Alerts',
                actionLabel: 'View All',
                onAction: () {
                  // Switch to alerts tab - handled by parent
                },
              ),
            ),

            // Recent alerts
            SliverToBoxAdapter(
              child: _buildRecentAlerts(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _activeDropboxes > 0 
                          ? AppColors.success 
                          : AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _activeDropboxes > 0
                              ? AppColors.successGlow
                              : AppColors.errorGlow,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PHANTOM PRINTER',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Command Center',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          CyberIconButton(
            icon: Icons.qr_code_scanner,
            onPressed: () {
              // TODO: QR scan for quick dropbox pairing
            },
            tooltip: 'Scan QR',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Hosts',
              value: _totalHosts.toString(),
              icon: Icons.computer,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Creds',
              value: _totalCreds.toString(),
              icon: Icons.key,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Hashes',
              value: _totalHashes.toString(),
              icon: Icons.tag,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading dropboxes...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderColor: AppColors.error.withOpacity(0.3),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            CyberButton(
              label: 'Retry',
              onPressed: () => _loadData(),
              icon: Icons.refresh,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.print_disabled,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Dropboxes Connected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deploy a Phantom Printer dropbox and it will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CyberButton(
              label: 'View Setup Guide',
              onPressed: () {
                // TODO: Open setup guide
              },
              icon: Icons.menu_book,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    if (_recentAlerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'No recent alerts',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: _recentAlerts.map((alert) {
            return _buildAlertItem(alert);
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildAlertItem(AlertModel alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: alert.level.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              alert.type.icon,
              size: 18,
              color: alert.level.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            alert.timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}