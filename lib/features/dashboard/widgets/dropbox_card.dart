// lib/features/dashboard/widgets/dropbox_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/dropbox_model.dart';
import '../../shared/widgets/glass_container.dart';

class DropboxCard extends StatelessWidget {
  final DropboxModel dropbox;
  final VoidCallback? onTap;

  const DropboxCard({
    super.key,
    required this.dropbox,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderColor: dropbox.status.color.withOpacity(0.3),
      boxShadow: dropbox.status == DropboxStatus.online
          ? [
              BoxShadow(
                color: dropbox.status.glowColor,
                blurRadius: 15,
                spreadRadius: -5,
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Status indicator
              _buildStatusIndicator(),
              const SizedBox(width: 12),
              
              // Name and hostname
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dropbox.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropbox.hostname,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'JetBrainsMono',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status badge
              _buildStatusBadge(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Info grid
          Row(
            children: [
              // IP Address
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.language,
                  label: 'IP',
                  value: dropbox.ipAddress,
                ),
              ),
              
              // Last seen
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'Last Seen',
                  value: dropbox.lastSeenAgo,
                ),
              ),
              
              // Uptime
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.timer,
                  label: 'Uptime',
                  value: _formatUptime(dropbox.uptime),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats row
          _buildStatsRow(),
          
          // C2 channels row
          if (dropbox.status == DropboxStatus.online) ...[
            const SizedBox(height: 12),
            _buildC2Channels(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: dropbox.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dropbox.status.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.print,
            size: 24,
            color: dropbox.status.color,
          ),
          if (dropbox.stealthEnabled)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.visibility_off,
                  size: 8,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dropbox.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dropbox.status.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dropbox.status.color,
              shape: BoxShape.circle,
              boxShadow: dropbox.status == DropboxStatus.online
                  ? [
                      BoxShadow(
                        color: dropbox.status.glowColor,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            dropbox.status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dropbox.status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontFamily: label == 'IP' ? 'JetBrainsMono' : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.computer,
            value: dropbox.stats.hostsDiscovered.toString(),
            label: 'Hosts',
            color: AppColors.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.key,
            value: dropbox.stats.credentialsCaptured.toString(),
            label: 'Creds',
            color: AppColors.success,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.tag,
            value: dropbox.stats.hashesCaptured.toString(),
            label: 'Hashes',
            color: AppColors.accent,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.radar,
            value: dropbox.stats.scanCount.toString(),
            label: 'Scans',
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.cardBorder,
    );
  }

  Widget _buildC2Channels() {
    return Row(
      children: [
        Text(
          'C2:',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        _buildChannelBadge(
          'SSH',
          dropbox.c2Status.sshConnected,
        ),
        const SizedBox(width: 6),
        _buildChannelBadge(
          'HTTPS',
          dropbox.c2Status.httpsBeaconActive,
        ),
        const SizedBox(width: 6),
        _buildChannelBadge(
          'DNS',
          dropbox.c2Status.dnsChannelActive,
        ),
        const Spacer(),
        Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildChannelBadge(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.success.withOpacity(0.15) 
            : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }

  String _formatUptime(String uptime) {
    // Already formatted from API
    if (uptime.length > 10) {
      return uptime.substring(0, 10);
    }
    return uptime;
  }
}

/// Compact version of dropbox card for lists
class DropboxCardCompact extends StatelessWidget {
  final DropboxModel dropbox;
  final VoidCallback? onTap;

  const DropboxCardCompact({
    super.key,
    required this.dropbox,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: dropbox.status.color.withOpacity(0.2),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dropbox.status.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dropbox.status.glowColor,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dropbox.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dropbox.ipAddress,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Last seen
          Text(
            dropbox.lastSeenAgo,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}