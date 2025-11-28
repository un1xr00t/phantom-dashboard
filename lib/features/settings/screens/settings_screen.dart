// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/storage_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  int _refreshInterval = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _notificationsEnabled = StorageService.notificationsEnabled;
      _biometricsEnabled = StorageService.biometricsEnabled;
      _refreshInterval = StorageService.autoRefreshInterval;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // Connection section
            _buildSectionTitle('Connection'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.webhook,
              title: 'C2 Configuration',
              subtitle: 'Webhook URLs and API keys',
              onTap: () => Navigator.pushNamed(context, AppRouter.c2Config),
            ),
            _buildSettingsTile(
              icon: Icons.dns,
              title: 'SSH Tunnel',
              subtitle: 'Configure SSH connection settings',
              onTap: () {
                // TODO: SSH config screen
              },
            ),

            const SizedBox(height: 24),

            // Notifications section
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 12),
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive alerts for important events',
              value: _notificationsEnabled,
              onChanged: (value) async {
                await StorageService.setNotificationsEnabled(value);
                setState(() => _notificationsEnabled = value);
                HapticFeedback.selectionClick();
              },
            ),

            const SizedBox(height: 24),

            // Security section
            _buildSectionTitle('Security'),
            const SizedBox(height: 12),
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              subtitle: 'Require Face ID/fingerprint to open',
              value: _biometricsEnabled,
              onChanged: (value) async {
                await StorageService.setBiometricsEnabled(value);
                setState(() => _biometricsEnabled = value);
                HapticFeedback.selectionClick();
              },
            ),

            const SizedBox(height: 24),

            // Data section
            _buildSectionTitle('Data'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.refresh,
              title: 'Auto Refresh',
              subtitle: 'Every $_refreshInterval seconds',
              trailing: _buildRefreshDropdown(),
            ),
            _buildSettingsTile(
              icon: Icons.download,
              title: 'Export Data',
              subtitle: 'Download all captured loot',
              onTap: _exportData,
            ),
            _buildSettingsTile(
              icon: Icons.delete_outline,
              title: 'Clear Local Cache',
              subtitle: 'Remove cached data',
              onTap: _clearCache,
              isDestructive: true,
            ),

            const SizedBox(height: 24),

            // About section
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: 'Phantom Dashboard v2.0.0',
            ),
            _buildSettingsTile(
              icon: Icons.code,
              title: 'GitHub',
              subtitle: 'github.com/un1xr00t/phantom-printer',
              onTap: () {
                // TODO: Open URL
              },
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Documentation',
              subtitle: 'View setup and usage guides',
              onTap: () {
                // TODO: Open docs
              },
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
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Reset App',
                    subtitle: 'Clear all settings and data',
                    onTap: _resetApp,
                    isDestructive: true,
                    showArrow: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Phantom Printer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built by un1xr00t',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
    bool showArrow = true,
  }) {
    return GlassContainer(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.error.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDestructive ? AppColors.error : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (onTap != null && showArrow)
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _refreshInterval,
          isDense: true,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
          items: [15, 30, 60, 120, 300].map((seconds) {
            return DropdownMenuItem(
              value: seconds,
              child: Text(
                seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              await StorageService.setAutoRefreshInterval(value);
              setState(() => _refreshInterval = value);
              HapticFeedback.selectionClick();
            }
          },
        ),
      ),
    );
  }

  void _exportData() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Cache?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will remove all locally cached data. Your settings will be preserved.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          CyberButton(
            label: 'Clear',
            onPressed: () async {
              await StorageService.clearPreferences();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
            height: 40,
          ),
        ],
      ),
    );
  }

  void _resetApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.error.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: 12),
            const Text(
              'Reset App?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'This will clear ALL data including your C2 configuration. You will need to set up the app again.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          CyberButton(
            label: 'Reset',
            onPressed: () async {
              await StorageService.clearAll();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.setup,
                  (route) => false,
                );
              }
            },
            isDanger: true,
            height: 40,
          ),
        ],
      ),
    );
  }
}