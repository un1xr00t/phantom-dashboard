// lib/features/commands/screens/command_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/command_model.dart';
import '../../../core/models/dropbox_model.dart';
import '../../../core/services/api_service.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/cyber_button.dart';
import '../../shared/widgets/cyber_text_field.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<DropboxModel> _dropboxes = [];
  List<CommandModel> _commandHistory = [];
  DropboxModel? _selectedDropbox;
  
  bool _isLoading = true;
  bool _isSending = false;
  final _commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final dropboxResult = await ApiService.getDropboxes();
      if (dropboxResult.isSuccess && dropboxResult.data != null) {
        _dropboxes = dropboxResult.data!;
        
        // Preserve selection by ID if already selected
        if (_selectedDropbox != null) {
          final stillExists = _dropboxes.where((d) => d.id == _selectedDropbox!.id).firstOrNull;
          _selectedDropbox = stillExists ?? (_dropboxes.isNotEmpty ? _dropboxes.first : null);
        } else if (_dropboxes.isNotEmpty) {
          _selectedDropbox = _dropboxes.first;
        }
      }

      // Load command history after dropboxes
      await _loadCommandHistory();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCommandHistory() async {
    if (_selectedDropbox == null) return;
    
    try {
      final historyResult = await ApiService.getCommandHistory(
        dropboxId: _selectedDropbox?.id,
        limit: 50,
      );
      if (historyResult.isSuccess && historyResult.data != null) {
        if (mounted) {
          setState(() {
            _commandHistory = historyResult.data!;
          });
        }
      }
    } catch (e) {
      // Silent fail for history
    }
  }

  Future<void> _sendCommand(CommandType type, {Map<String, dynamic>? args}) async {
    if (_selectedDropbox == null) return;

    setState(() => _isSending = true);

    try {
      final result = await ApiService.sendCommand(
        dropboxId: _selectedDropbox!.id,
        command: type.commandString,
        args: args,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isSuccess ? 'Command sent successfully' : 'Failed: ${result.error}',
            ),
            backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
          ),
        );
        
        // Only refresh command history, not dropboxes
        _loadCommandHistory();
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendCustomCommand() async {
    if (_selectedDropbox == null || _commandController.text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final result = await ApiService.sendCommand(
        dropboxId: _selectedDropbox!.id,
        command: 'execute_shell',
        args: {'cmd': _commandController.text},
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        if (result.isSuccess) {
          _commandController.clear();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isSuccess ? 'Command queued' : 'Failed: ${result.error}',
            ),
          ),
        );
        // Only refresh command history
        _loadCommandHistory();
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Dropbox selector
          _buildDropboxSelector(),
          
          // Tab bar
          _buildTabBar(),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickCommandsTab(),
                _buildHistoryTab(),
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
            'Command Center',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              if (_isSending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDropboxSelector() {
    // Find the selected dropbox in the current list by ID
    final selectedInList = _selectedDropbox != null 
        ? _dropboxes.where((d) => d.id == _selectedDropbox!.id).firstOrNull 
        : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedInList?.id,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            icon: Icon(Icons.expand_more, color: AppColors.textSecondary),
            hint: Text(
              _isLoading ? 'Loading...' : 'Select Dropbox',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            items: _dropboxes.map((dropbox) {
              return DropdownMenuItem<String>(
                value: dropbox.id,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dropbox.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dropbox.name,
                        style: const TextStyle(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dropbox.ipAddress,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'JetBrainsMono',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? selectedId) {
              if (selectedId != null) {
                final dropbox = _dropboxes.firstWhere((d) => d.id == selectedId);
                setState(() => _selectedDropbox = dropbox);
                _loadCommandHistory();
              }
            },
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
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
          tabs: const [
            Tab(text: 'Quick Commands'),
            Tab(text: 'History'),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildQuickCommandsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom command input
          _buildSectionTitle('Custom Command'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TerminalTextField(
                  controller: _commandController,
                  hint: 'Enter command...',
                  onSubmitted: (_) => _sendCustomCommand(),
                ),
              ),
              const SizedBox(width: 12),
              CyberIconButton(
                icon: Icons.send,
                onPressed: _isSending ? null : _sendCustomCommand,
                color: AppColors.terminalGreen,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recon commands
          _buildSectionTitle('Reconnaissance'),
          const SizedBox(height: 12),
          _buildCommandGrid(QuickCommand.reconCommands),

          const SizedBox(height: 24),

          // Collection commands
          _buildSectionTitle('Collection'),
          const SizedBox(height: 12),
          _buildCommandGrid(QuickCommand.collectionCommands),

          const SizedBox(height: 24),

          // Danger zone
          _buildSectionTitle('Danger Zone', color: AppColors.error),
          const SizedBox(height: 12),
          _buildCommandGrid(QuickCommand.dangerCommands, isDanger: true),

          const SizedBox(height: 100),
        ],
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

  Widget _buildCommandGrid(List<QuickCommand> commands, {bool isDanger = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commands.map((cmd) {
        return _buildCommandButton(cmd, isDanger: isDanger);
      }).toList(),
    );
  }

  Widget _buildCommandButton(QuickCommand cmd, {bool isDanger = false}) {
    return GlassContainer(
      onTap: _selectedDropbox == null || _isSending
          ? null
          : () => _confirmAndSend(cmd),
      padding: const EdgeInsets.all(16),
      borderColor: isDanger
          ? AppColors.error.withOpacity(0.3)
          : cmd.color.withOpacity(0.2),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(cmd.icon, size: 20, color: cmd.color),
                const Spacer(),
                if (isDanger)
                  Icon(Icons.warning_amber, size: 14, color: AppColors.error),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              cmd.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cmd.description,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndSend(QuickCommand cmd) {
    if (cmd.isDangerous) {
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
                'Confirm Action',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to execute "${cmd.name}"? This action may be irreversible.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            CyberButton(
              label: 'Execute',
              onPressed: () {
                Navigator.pop(context);
                _sendCommand(cmd.type, args: cmd.defaultArgs);
              },
              isDanger: true,
              height: 40,
            ),
          ],
        ),
      );
    } else {
      _sendCommand(cmd.type, args: cmd.defaultArgs);
    }
  }

  Widget _buildHistoryTab() {
    if (_commandHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No command history',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _commandHistory.length,
      itemBuilder: (context, index) {
        final cmd = _commandHistory[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildHistoryItem(cmd),
        );
      },
    );
  }

  Widget _buildHistoryItem(CommandModel cmd) {
    return GlassContainer(
      onTap: () => _showCommandDetail(cmd),
      padding: const EdgeInsets.all(16),
      borderColor: cmd.status.color.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cmd.type.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              cmd.type.icon,
              size: 20,
              color: cmd.type.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cmd.type.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cmd.command,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cmd.status.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cmd.status.icon, size: 12, color: cmd.status.color),
                    const SizedBox(width: 4),
                    Text(
                      cmd.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cmd.status.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cmd.timeAgo,
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

  void _showCommandDetail(CommandModel cmd) {
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
                      Icon(cmd.type.icon, size: 24, color: cmd.type.color),
                      const SizedBox(width: 12),
                      Text(
                        cmd.type.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Command
                  _buildDetailSection('Command', cmd.command),
                  
                  // Status
                  _buildDetailSection('Status', cmd.status.displayName),
                  
                  // Duration
                  if (cmd.executionDuration != null)
                    _buildDetailSection('Duration', cmd.durationString),
                  
                  // Output
                  if (cmd.output != null && cmd.output!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Output',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        cmd.output!,
                        style: AppTextStyles.codeSmall,
                      ),
                    ),
                  ],
                  
                  // Error
                  if (cmd.error != null && cmd.error!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding: const EdgeInsets.all(12),
                      borderColor: AppColors.error.withOpacity(0.3),
                      child: SelectableText(
                        cmd.error!,
                        style: AppTextStyles.codeSmall.copyWith(
                          color: AppColors.error,
                        ),
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

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'JetBrainsMono',
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}