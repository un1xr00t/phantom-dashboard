// lib/features/shared/widgets/cyber_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class CyberButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isExpanded;
  final bool isLoading;
  final bool isDanger;
  final Color? color;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CyberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isExpanded = false,
    this.isLoading = false,
    this.isDanger = false,
    this.color,
    this.textColor,
    this.height = 52,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    if (widget.isDanger) return AppColors.error;
    return widget.color ?? AppColors.primary;
  }

  Color get _glowColor {
    if (widget.isDanger) return AppColors.errorGlow;
    return widget.color?.withOpacity(0.4) ?? AppColors.primaryGlow;
  }

  @override
  Widget build(BuildContext context) {
    final button = AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed != null && !widget.isLoading
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: widget.isOutlined
                  ? Colors.transparent
                  : (_isPressed
                      ? _primaryColor.withOpacity(0.8)
                      : _primaryColor),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.isOutlined
                  ? Border.all(
                      color: _primaryColor,
                      width: 1.5,
                    )
                  : null,
              boxShadow: widget.onPressed != null && !widget.isOutlined
                  ? [
                      BoxShadow(
                        color: _glowColor.withOpacity(
                          0.3 + (_glowController.value * 0.2),
                        ),
                        blurRadius: _isPressed ? 8 : 12,
                        spreadRadius: _isPressed ? 0 : 2,
                        offset: Offset(0, _isPressed ? 2 : 4),
                      ),
                    ]
                  : null,
            ),
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.98 : 1.0),
            child: Row(
              mainAxisSize:
                  widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isOutlined
                            ? _primaryColor
                            : (widget.textColor ?? AppColors.background),
                      ),
                    ),
                  )
                else if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.isOutlined
                        ? _primaryColor
                        : (widget.textColor ?? AppColors.background),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.isOutlined
                        ? _primaryColor
                        : (widget.textColor ?? AppColors.background),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.isExpanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Icon-only cyber button
class CyberIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final bool showGlow;
  final String? tooltip;

  const CyberIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 44,
    this.showGlow = true,
    this.tooltip,
  });

  @override
  State<CyberIconButton> createState() => _CyberIconButtonState();
}

class _CyberIconButtonState extends State<CyberIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(_isPressed ? 0.5 : 0.3),
            width: 1,
          ),
          boxShadow: widget.showGlow && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: color.withOpacity(_isPressed ? 0.1 : 0.2),
                    blurRadius: _isPressed ? 4 : 8,
                    spreadRadius: _isPressed ? 0 : 1,
                  ),
                ]
              : null,
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Icon(
          widget.icon,
          size: widget.size * 0.5,
          color: widget.onPressed != null ? color : AppColors.textMuted,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Gradient cyber button
class GradientCyberButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final bool isExpanded;
  final bool isLoading;
  final double height;

  const GradientCyberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient,
    this.isExpanded = false,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  State<GradientCyberButton> createState() => _GradientCyberButtonState();
}

class _GradientCyberButtonState extends State<GradientCyberButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;

    final button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed != null && !widget.isLoading
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow.withOpacity(_isPressed ? 0.2 : 0.4),
                    blurRadius: _isPressed ? 8 : 16,
                    spreadRadius: _isPressed ? 0 : 2,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ]
              : null,
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Row(
          mainAxisSize:
              widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isExpanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Danger button with warning styling
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final bool isLoading;
  final bool requiresConfirmation;

  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isExpanded = false,
    this.isLoading = false,
    this.requiresConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: label,
      onPressed: requiresConfirmation
          ? () => _showConfirmationDialog(context)
          : onPressed,
      icon: icon ?? Icons.warning_amber,
      isDanger: true,
      isExpanded: isExpanded,
      isLoading: isLoading,
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Action',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to proceed with this action? This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CyberButton(
            label: 'Confirm',
            onPressed: () {
              Navigator.pop(context);
              onPressed?.call();
            },
            isDanger: true,
            height: 40,
          ),
        ],
      ),
    );
  }
}

/// Small pill-style button
class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSelected;
  final Color? selectedColor;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isSelected = false,
    this.selectedColor,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selectedColor ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed != null
          ? () {
              HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? color.withOpacity(_isPressed ? 0.8 : 1.0)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isSelected ? color : AppColors.cardBorder,
            width: 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}