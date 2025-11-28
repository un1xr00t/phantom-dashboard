// lib/features/loot/screens/credential_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/loot_model.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';

class CredentialDetailScreen extends StatefulWidget {
  final String credentialId;

  const CredentialDetailScreen({
    super.key,
    required this.credentialId,
  });

  @override
  State<CredentialDetailScreen> createState() => _CredentialDetailScreenState();
}

class _CredentialDetailScreenState extends State<CredentialDetailScreen> {
  // In a real app, this would fetch from API
  // For now, we'll show a placeholder
  CredentialModel? _credential;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCredential();
  }

  Future<void> _loadCredential() async {
    // TODO: Load from API
    // For demo, create a mock credential
    setState(() {
      _credential = CredentialModel(
        id: widget.credentialId,
        dropboxId: 'phantom-001',
        type: CredentialType.ntlm,
        source: CredentialSource.responder,
        username: 'jsmith',
        domain: 'CORP',
        password: 'Summer2024!',
        targetHost: '192.168.1.50',
        targetService: 'SMB',
        capturedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isCracked: true,
      );
    });
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
          child: _credential == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final cred = _credential!;

    return Column(
      children: [
        // App bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Credential Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderColor: cred.isHighValue
                      ? AppColors.warning.withOpacity(0.3)
                      : cred.type.color.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: cred.type.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          cred.type.icon,
                          size: 28,
                          color: cred.type.color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cred.displayUsername,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'JetBrainsMono',
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (cred.isHighValue) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.star,
                                    size: 18,
                                    color: AppColors.warning,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cred.type.displayName} • ${cred.source.displayName}',
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
                ),

                const SizedBox(height: 24),

                // Credentials section
                _buildSectionTitle('Credentials'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCopyableRow('Username', cred.username),
                      if (cred.domain != null) ...[
                        const Divider(color: AppColors.cardBorder, height: 24),
                        _buildCopyableRow('Domain', cred.domain!),
                      ],
                      if (cred.password != null) ...[
                        const Divider(color: AppColors.cardBorder, height: 24),
                        _buildPasswordRow(cred.password!),
                      ],
                      if (cred.hash != null) ...[
                        const Divider(color: AppColors.cardBorder, height: 24),
                        _buildCopyableRow('Hash', cred.maskedHash, fullValue: cred.hash),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Target info
                _buildSectionTitle('Target Information'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (cred.targetHost != null)
                        _buildCopyableRow('Host', cred.targetHost!),
                      if (cred.targetService != null) ...[
                        const Divider(color: AppColors.cardBorder, height: 24),
                        _buildInfoRow('Service', cred.targetService!),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Metadata
                _buildSectionTitle('Metadata'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow('Captured', cred.capturedAgo),
                      const Divider(color: AppColors.cardBorder, height: 24),
                      _buildInfoRow('Type', cred.type.displayName),
                      const Divider(color: AppColors.cardBorder, height: 24),
                      _buildInfoRow('Source', cred.source.displayName),
                      const Divider(color: AppColors.cardBorder, height: 24),
                      _buildInfoRow(
                        'Status',
                        cred.isCracked ? 'Cracked' : 'Not Cracked',
                        valueColor: cred.isCracked ? AppColors.success : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: CyberButton(
                        label: 'Copy All',
                        onPressed: () => _copyAll(cred),
                        icon: Icons.copy_all,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CyberButton(
                        label: 'Test Cred',
                        onPressed: () => _testCredential(cred),
                        icon: Icons.play_arrow,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(String label, String value, {String? fullValue}) {
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
                fontFamily: 'JetBrainsMono',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(fullValue ?? value, label),
              child: Icon(
                Icons.copy,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRow(String password) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              _showPassword ? password : '•' * password.length.clamp(8, 16),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'JetBrainsMono',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showPassword = !_showPassword),
              child: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(password, 'Password'),
              child: Icon(
                Icons.copy,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyAll(CredentialModel cred) {
    final buffer = StringBuffer();
    buffer.writeln('Username: ${cred.username}');
    if (cred.domain != null) buffer.writeln('Domain: ${cred.domain}');
    if (cred.password != null) buffer.writeln('Password: ${cred.password}');
    if (cred.hash != null) buffer.writeln('Hash: ${cred.hash}');
    if (cred.targetHost != null) buffer.writeln('Target: ${cred.targetHost}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All credential info copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _testCredential(CredentialModel cred) {
    // TODO: Implement credential testing via API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credential test queued'),
      ),
    );
  }
}