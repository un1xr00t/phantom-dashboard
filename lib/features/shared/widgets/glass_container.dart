// lib/features/shared/widgets/glass_container.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurAmount;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.blurAmount = 10,
    this.boxShadow,
    this.gradient,
    this.width,
    this.height,
    this.onTap,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.glassBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: borderWidth,
        ),
        gradient: gradient,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: enableBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurAmount,
                  sigmaY: blurAmount,
                ),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// A glass container with a subtle glow effect
class GlowingGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color glowColor;
  final double glowIntensity;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlowingGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.glowColor = AppColors.primary,
    this.glowIntensity = 0.3,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      width: width,
      height: height,
      onTap: onTap,
      borderColor: glowColor.withOpacity(0.3),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(glowIntensity),
          blurRadius: 20,
          spreadRadius: -5,
        ),
      ],
      child: child,
    );
  }
}

/// A card-style container with the app's dark theme
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasBorder;
  final bool hasShadow;

  const DarkCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.onTap,
    this.hasBorder = true,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: AppColors.cardBorder,
                width: 1,
              )
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: container,
        ),
      );
    }

    return container;
  }
}

/// A container with gradient border effect
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double borderWidth;
  final Gradient? borderGradient;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GradientBorderContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderWidth = 2,
    this.borderGradient,
    this.backgroundColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = borderGradient ?? AppColors.primaryGradient;
    
    final container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// Animated container that pulses with a glow
class PulsingGlassContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color glowColor;
  final Duration pulseDuration;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const PulsingGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.glowColor = AppColors.primary,
    this.pulseDuration = const Duration(milliseconds: 1500),
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<PulsingGlassContainer> createState() => _PulsingGlassContainerState();
}

class _PulsingGlassContainerState extends State<PulsingGlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GlassContainer(
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          width: widget.width,
          height: widget.height,
          onTap: widget.onTap,
          borderColor: widget.glowColor.withOpacity(0.3 + (_controller.value * 0.3)),
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(0.1 + (_controller.value * 0.2)),
              blurRadius: 15 + (_controller.value * 10),
              spreadRadius: -5 + (_controller.value * 5),
            ),
          ],
          child: widget.child,
        );
      },
    );
  }
}

/// Status indicator container (online/offline/warning)
class StatusContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final StatusType status;
  final bool showGlow;
  final VoidCallback? onTap;

  const StatusContainer({
    super.key,
    required this.child,
    required this.status,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.showGlow = true,
    this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case StatusType.online:
        return AppColors.success;
      case StatusType.offline:
        return AppColors.error;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.inactive:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      borderColor: _statusColor.withOpacity(0.4),
      boxShadow: showGlow
          ? [
              BoxShadow(
                color: _statusColor.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: -5,
              ),
            ]
          : null,
      child: child,
    );
  }
}

enum StatusType {
  online,
  offline,
  warning,
  inactive,
}