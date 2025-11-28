// lib/features/dashboard/widgets/connection_status_bar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_container.dart';

class ConnectionStatusBar extends StatefulWidget {
  final bool isConnected;
  final int dropboxCount;
  final int activeCount;
  final DateTime? lastSync;

  const ConnectionStatusBar({
    super.key,
    required this.isConnected,
    required this.dropboxCount,
    required this.activeCount,
    this.lastSync,
  });

  @override
  State<ConnectionStatusBar> createState() => _ConnectionStatusBarState();
}

class _ConnectionStatusBarState extends State<ConnectionStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isConnected ? AppColors.success : AppColors.error;
    
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: statusColor.withOpacity(0.3),
      child: Row(
        children: [
          // Animated status indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: widget.isConnected
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(
                              0.5 + (_pulseController.value * 0.3),
                            ),
                            blurRadius: 6 + (_pulseController.value * 4),
                            spreadRadius: _pulseController.value * 2,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusMessage(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Dropbox count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.print,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.activeCount}/${widget.dropboxCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage() {
    if (!widget.isConnected) {
      return 'No active dropboxes';
    }
    
    if (widget.activeCount == 1) {
      return '1 dropbox online';
    }
    
    return '${widget.activeCount} dropboxes online';
  }
}

/// Compact status indicator for app bar
class StatusIndicator extends StatefulWidget {
  final bool isOnline;
  final double size;

  const StatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 8,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    if (widget.isOnline) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline ? AppColors.success : AppColors.error;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: widget.isOnline
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5 + (_controller.value * 0.3)),
                      blurRadius: 4 + (_controller.value * 2),
                      spreadRadius: _controller.value,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

/// Network quality indicator
class NetworkQualityIndicator extends StatelessWidget {
  final int strength; // 0-4

  const NetworkQualityIndicator({
    super.key,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < strength;
        final height = 6.0 + (index * 4);
        
        return Container(
          width: 4,
          height: height,
          margin: EdgeInsets.only(left: index > 0 ? 2 : 0),
          decoration: BoxDecoration(
            color: isActive
                ? _getColorForStrength(strength)
                : AppColors.cardBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Color _getColorForStrength(int strength) {
    if (strength >= 3) return AppColors.success;
    if (strength >= 2) return AppColors.warning;
    return AppColors.error;
  }
}

/// C2 channel status indicator
class C2ChannelIndicator extends StatelessWidget {
  final bool sshConnected;
  final bool httpsActive;
  final bool dnsActive;

  const C2ChannelIndicator({
    super.key,
    required this.sshConnected,
    required this.httpsActive,
    required this.dnsActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChannel('SSH', sshConnected),
        const SizedBox(width: 4),
        _buildChannel('HTTPS', httpsActive),
        const SizedBox(width: 4),
        _buildChannel('DNS', dnsActive),
      ],
    );
  }

  Widget _buildChannel(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }
}