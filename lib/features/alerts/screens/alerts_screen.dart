// lib/features/alerts/screens/alerts_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  
  AlertLevel? _filterLevel;
  String? _filterDropbox;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadAlerts(silent: true);
    });
  }

  Future<void> _loadAlerts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await ApiService.getAlerts(
        level: _filterLevel?.name,
        dropboxId: _filterDropbox,
        limit: 100,
      );

      if (result.isSuccess && result.data != null) {
        _alerts = result.data!;
      } else {
        _error = result.error;
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

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadAlerts(silent: true);
  }

  List<AlertModel> get _filteredAlerts {
    var filtered = _alerts;
    if (_filterLevel != null) {
      filtered = filtered.where((a) => a.level == _filterLevel).toList();
    }
    return filtered.sortByTime();
  }

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;
  int get _criticalCount => _alerts.where((a) => a.level == AlertLevel.critical).length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Filter chips
          _buildFilters(),
          
          // Alert list
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _filteredAlerts.isEmpty
                        ? _buildEmptyState()
                        : _buildAlertList(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (_unreadCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unreadCount unread',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_criticalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_criticalCount critical',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.critical,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          CyberIconButton(
            icon: Icons.done_all,
            onPressed: _markAllRead,
            tooltip: 'Mark all read',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: _filterLevel == null,
            onTap: () => setState(() => _filterLevel = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Critical',
            isSelected: _filterLevel == AlertLevel.critical,
            color: AppColors.critical,
            onTap: () => setState(() => _filterLevel = AlertLevel.critical),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'High',
            isSelected: _filterLevel == AlertLevel.high,
            color: AppColors.error,
            onTap: () => setState(() => _filterLevel = AlertLevel.high),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Warning',
            isSelected: _filterLevel == AlertLevel.warning,
            color: AppColors.warning,
            onTap: () => setState(() => _filterLevel = AlertLevel.warning),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Info',
            isSelected: _filterLevel == AlertLevel.info,
            color: AppColors.primary,
            onTap: () => setState(() => _filterLevel = AlertLevel.info),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor.withOpacity(0.5) : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? chipColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
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
              'Failed to load alerts',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CyberButton(
              label: 'Retry',
              onPressed: _loadAlerts,
              icon: Icons.refresh,
              isOutlined: true,
            ),
          ],
        ),
      ),
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
              Icons.notifications_off_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All quiet on the network front',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList() {
    final groupedAlerts = _filteredAlerts.groupByDate();
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: groupedAlerts.length,
        itemBuilder: (context, groupIndex) {
          final group = groupedAlerts[groupIndex];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  group.dateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              // Alerts in group
              ...group.alerts.asMap().entries.map((entry) {
                final index = entry.key;
                final alert = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAlertCard(alert),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * index),
                  duration: 300.ms,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    return GlassContainer(
      onTap: () => _showAlertDetail(alert),
      padding: const EdgeInsets.all(16),
      borderColor: alert.level.color.withOpacity(alert.isRead ? 0.1 : 0.3),
      backgroundColor: alert.isRead 
          ? AppColors.glassBackground 
          : alert.level.backgroundColor.withOpacity(0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alert.level.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              alert.type.icon,
              size: 20,
              color: alert.level.color,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: alert.level.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: alert.level.backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.level.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: alert.level.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropbox name
                    if (alert.dropboxName != null)
                      Text(
                        alert.dropboxName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    const Spacer(),
                    // Time
                    Text(
                      alert.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetail(AlertModel alert) {
    // Mark as read
    if (!alert.isRead) {
      ApiService.markAlertRead(alert.id);
      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          _alerts[index] = alert.copyWith(isRead: true);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: alert.level.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          alert.type.icon,
                          size: 24,
                          color: alert.level.color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.formattedDateTime,
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
                  
                  const SizedBox(height: 24),
                  
                  // Message
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Metadata
                  if (alert.metadata != null) ...[
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        alert.metadata.toString(),
                        style: AppTextStyles.codeSmall,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _markAllRead() async {
    for (final alert in _alerts.where((a) => !a.isRead)) {
      await ApiService.markAlertRead(alert.id);
    }
    setState(() {
      _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    });
    HapticFeedback.mediumImpact();
  }
}