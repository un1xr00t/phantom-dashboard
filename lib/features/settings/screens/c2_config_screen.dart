// lib/features/settings/screens/c2_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';
import '../../shared/widgets/cyber_text_field.dart';

class C2ConfigScreen extends StatefulWidget {
  const C2ConfigScreen({super.key});

  @override
  State<C2ConfigScreen> createState() => _C2ConfigScreenState();
}

class _C2ConfigScreenState extends State<C2ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _webhookUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _c2HostController = TextEditingController();
  final _c2PortController = TextEditingController();
  final _discordWebhookController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool? _connectionSuccess;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _webhookUrlController.dispose();
    _apiKeyController.dispose();
    _c2HostController.dispose();
    _c2PortController.dispose();
    _discordWebhookController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final webhookUrl = await StorageService.getN8nWebhookUrl();
    final apiKey = await StorageService.getApiKey();
    final c2Host = await StorageService.getC2Host();
    final c2Port = await StorageService.getC2Port();
    final discordWebhook = await StorageService.getDiscordWebhook();

    if (mounted) {
      setState(() {
        _webhookUrlController.text = webhookUrl ?? '';
        _apiKeyController.text = apiKey ?? '';
        _c2HostController.text = c2Host ?? '';
        _c2PortController.text = c2Port ?? '22';
        _discordWebhookController.text = discordWebhook ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (_webhookUrlController.text.isEmpty) {
      setState(() {
        _connectionError = 'Enter a webhook URL first';
        _connectionSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _connectionError = null;
      _connectionSuccess = null;
    });

    // Temporarily save for testing
    await StorageService.saveN8nWebhookUrl(_webhookUrlController.text);
    if (_apiKeyController.text.isNotEmpty) {
      await StorageService.saveApiKey(_apiKeyController.text);
    }
    ApiService.resetDio();

    final result = await ApiService.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _connectionSuccess = result.isSuccess;
        _connectionError = result.error;
      });

      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await StorageService.saveN8nWebhookUrl(_webhookUrlController.text);
      
      if (_apiKeyController.text.isNotEmpty) {
        await StorageService.saveApiKey(_apiKeyController.text);
      }
      
      if (_c2HostController.text.isNotEmpty) {
        await StorageService.saveC2Config(
          host: _c2HostController.text,
          port: _c2PortController.text,
        );
      }
      
      if (_discordWebhookController.text.isNotEmpty) {
        await StorageService.saveDiscordWebhook(_discordWebhookController.text);
      }

      ApiService.resetDio();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Column(
                  children: [
                    // Header
                    _buildHeader(),
                    
                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // n8n section
                              _buildSectionTitle('n8n Webhook'),
                              const SizedBox(height: 12),
                              GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    CyberTextField(
                                      controller: _webhookUrlController,
                                      label: 'Webhook  Base URL',
                                      hint: 'https://n8n.example.com',
                                      prefixIcon: Icons.webhook,
                                      keyboardType: TextInputType.url,
                                      validator: (value) {
                                        // Optional - no longer required since we use C2 API
                                        if (value != null && value.isNotEmpty && !value.startsWith('http')) {
                                          return 'Must start with http:// or https://';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    CyberTextField(
                                      controller: _apiKeyController,
                                      label: 'API Key (Optional)',
                                      hint: 'Your API key',
                                      prefixIcon: Icons.key,
                                      isPassword: true,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Test connection button
                              Row(
                                children: [
                                  Expanded(
                                    child: CyberButton(
                                      label: _isTesting ? 'Testing...' : 'Test Connection',
                                      onPressed: _isTesting ? null : _testConnection,
                                      icon: Icons.wifi_tethering,
                                      isOutlined: true,
                                      isLoading: _isTesting,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Connection result
                              if (_connectionSuccess != null) ...[
                                const SizedBox(height: 12),
                                GlassContainer(
                                  padding: const EdgeInsets.all(12),
                                  borderColor: _connectionSuccess!
                                      ? AppColors.success.withOpacity(0.5)
                                      : AppColors.error.withOpacity(0.5),
                                  backgroundColor: _connectionSuccess!
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _connectionSuccess!
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: _connectionSuccess!
                                            ? AppColors.success
                                            : AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _connectionSuccess!
                                              ? 'Connection successful!'
                                              : _connectionError ?? 'Connection failed',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _connectionSuccess!
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 24),
                              
                              // C2 Server section
                              _buildSectionTitle('C2 Server (SSH)'),
                              const SizedBox(height: 12),
                              GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    CyberTextField(
                                      controller: _c2HostController,
                                      label: 'Host / IP',
                                      hint: '123.45.67.89',
                                      prefixIcon: Icons.dns,
                                      keyboardType: TextInputType.url,
                                    ),
                                    const SizedBox(height: 16),
                                    CyberTextField(
                                      controller: _c2PortController,
                                      label: 'SSH Port',
                                      hint: '22',
                                      prefixIcon: Icons.settings_ethernet,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Discord section
                              _buildSectionTitle('Discord Webhook (Optional)'),
                              const SizedBox(height: 12),
                              GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: CyberTextField(
                                  controller: _discordWebhookController,
                                  label: 'Webhook URL',
                                  hint: 'https://discord.com/api/webhooks/...',
                                  prefixIcon: Icons.discord,
                                  keyboardType: TextInputType.url,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Save button
                              CyberButton(
                                label: _isSaving ? 'Saving...' : 'Save Configuration',
                                onPressed: _isSaving ? null : _saveConfig,
                                icon: Icons.save,
                                isExpanded: true,
                                isLoading: _isSaving,
                              ),
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
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
              'C2 Configuration',
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}