// lib/features/auth/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/cyber_button.dart';
import '../../shared/widgets/cyber_text_field.dart';
import '../../shared/widgets/glass_container.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controllers
  final _webhookUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _c2HostController = TextEditingController();
  final _c2PortController = TextEditingController(text: '22');
  final _discordWebhookController = TextEditingController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _connectionSuccess = false;
  String? _connectionError;
  
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final webhookUrl = await StorageService.getN8nWebhookUrl();
    final apiKey = await StorageService.getApiKey();
    final c2Host = await StorageService.getC2Host();
    final c2Port = await StorageService.getC2Port();
    final discordWebhook = await StorageService.getDiscordWebhook();
    
    if (mounted) {
      setState(() {
        if (webhookUrl != null) _webhookUrlController.text = webhookUrl;
        if (apiKey != null) _apiKeyController.text = apiKey;
        if (c2Host != null) _c2HostController.text = c2Host;
        if (c2Port != null) _c2PortController.text = c2Port;
        if (discordWebhook != null) _discordWebhookController.text = discordWebhook;
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pageController.dispose();
    _webhookUrlController.dispose();
    _apiKeyController.dispose();
    _c2HostController.dispose();
    _c2PortController.dispose();
    _discordWebhookController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _testConnection() async {
    if (_webhookUrlController.text.isEmpty) {
      setState(() {
        _connectionError = 'Please enter a webhook URL';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _connectionError = null;
      _connectionSuccess = false;
    });

    // Save temporarily for testing
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

      if (result.isSuccess) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save all configuration
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
      
      await StorageService.setSetupComplete(true);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacementNamed(context, AppRouter.main);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving configuration: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Progress indicator
              _buildProgressIndicator(),
              
              // Page content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildWebhookPage(),
                      _buildC2Page(),
                    ],
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
          if (_currentPage > 0)
            IconButton(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              _getPageTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Welcome';
      case 1:
        return 'n8n Configuration';
      case 2:
        return 'C2 Server';
      default:
        return '';
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentPage;
          final isCurrent = index == _currentPage;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Icon
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGlow.withOpacity(_glowController.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.print_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              );
            },
          ).animate().fadeIn(duration: 500.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 500.ms,
          ),
          
          const SizedBox(height: 32),
          
          // Welcome text
          const Text(
            'Welcome, Operator',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          Text(
            'Let\'s configure your Phantom Printer\ncommand center',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          
          const SizedBox(height: 48),
          
          // Feature list
          _buildFeatureItem(
            icon: Icons.webhook,
            title: 'n8n Webhooks',
            description: 'Connect to your automation platform',
            delay: 400,
          ),
          _buildFeatureItem(
            icon: Icons.dns,
            title: 'C2 Server',
            description: 'Configure SSH tunnel endpoints',
            delay: 500,
          ),
          _buildFeatureItem(
            icon: Icons.notifications_active,
            title: 'Alerts',
            description: 'Real-time Discord/Slack notifications',
            delay: 600,
          ),
          
          const SizedBox(height: 48),
          
          // Continue button
          CyberButton(
            label: 'Get Started',
            onPressed: _nextPage,
            icon: Icons.arrow_forward,
            isExpanded: true,
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).slideX(
      begin: 0.1,
      end: 0,
      duration: 400.ms,
    );
  }

  Widget _buildWebhookPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Info card
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.primary.withOpacity(0.3),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enter your n8n webhook base URL. This connects your dashboard to the Phantom Printer automation platform.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Webhook URL field (optional - only needed if not using C2 API)
          CyberTextField(
            controller: _webhookUrlController,
            label: 'n8n Webhook URL (Optional)',
            hint: 'https://your-n8n.example.com',
            prefixIcon: Icons.webhook,
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'Must be a valid URL starting with http:// or https://';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // API Key field (optional)
          CyberTextField(
            controller: _apiKeyController,
            label: 'API Key (Optional)',
            hint: 'Your n8n API key',
            prefixIcon: Icons.key,
            isPassword: true,
          ),
          
          const SizedBox(height: 24),
          
          // Discord webhook field (optional)
          CyberTextField(
            controller: _discordWebhookController,
            label: 'Discord Webhook (Optional)',
            hint: 'https://discord.com/api/webhooks/...',
            prefixIcon: Icons.discord,
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 32),
          
          // Test connection button
          CyberButton(
            label: _isTesting ? 'Testing...' : 'Test Connection',
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting ? Icons.hourglass_top : Icons.wifi_tethering,
            isOutlined: true,
            isExpanded: true,
            isLoading: _isTesting,
          ),
          
          const SizedBox(height: 16),
          
          // Connection status
          if (_connectionSuccess || _connectionError != null)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderColor: _connectionSuccess 
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.error.withOpacity(0.5),
              backgroundColor: _connectionSuccess
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _connectionSuccess ? Icons.check_circle : Icons.error,
                    color: _connectionSuccess ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _connectionSuccess 
                          ? 'Connection successful!'
                          : _connectionError ?? 'Connection failed',
                      style: TextStyle(
                        fontSize: 14,
                        color: _connectionSuccess ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 300.ms,
            ),
          
          const SizedBox(height: 32),
          
          // Continue button
          CyberButton(
            label: 'Continue',
            onPressed: _nextPage,
            icon: Icons.arrow_forward,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildC2Page() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Info card
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.secondary.withOpacity(0.3),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configure your C2 server details. This is where your dropbox connects via SSH tunnel.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // C2 Host field
          CyberTextField(
            controller: _c2HostController,
            label: 'C2 Server Host',
            hint: '123.45.67.89 or c2.example.com',
            prefixIcon: Icons.dns,
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 24),
          
          // C2 Port field
          CyberTextField(
            controller: _c2PortController,
            label: 'SSH Port',
            hint: '22',
            prefixIcon: Icons.settings_ethernet,
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 48),
          
          // Skip or complete
          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: 'Skip for Now',
                  onPressed: _saveAndContinue,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CyberButton(
                  label: _isLoading ? 'Saving...' : 'Complete Setup',
                  onPressed: _isLoading ? null : _saveAndContinue,
                  icon: Icons.check,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Note
          Center(
            child: Text(
              'You can update these settings later',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}