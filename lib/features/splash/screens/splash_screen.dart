// lib/features/splash/screens/splash_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _scanLineController;
  
  bool _showTagline = false;
  bool _showVersion = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showTagline = true);
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _showVersion = true);
    
    await Future.delayed(const Duration(milliseconds: 1200));
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final isSetupComplete = StorageService.isSetupComplete;
    final hasValidConfig = await StorageService.hasValidC2Config();
    
    if (mounted) {
      if (isSetupComplete && hasValidConfig) {
        Navigator.pushReplacementNamed(context, AppRouter.main);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.setup);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Animated grid background
            _buildGridBackground(),
            
            // Rotating outer ring
            _buildOuterRing(),
            
            // Scan line effect
            _buildScanLine(),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing printer icon
                  _buildPrinterIcon(),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  _buildTitle(),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline
                  if (_showTagline) _buildTagline(),
                  
                  const SizedBox(height: 40),
                  
                  // Loading indicator
                  _buildLoadingIndicator(),
                  
                  const SizedBox(height: 24),
                  
                  // Version
                  if (_showVersion) _buildVersion(),
                ],
              ),
            ),
            
            // Corner decorations
            _buildCornerDecorations(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridBackground() {
    return Opacity(
      opacity: 0.05,
      child: CustomPaint(
        painter: GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildOuterRing() {
    return Center(
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateController.value * 2 * math.pi,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Orbiting dots
                  for (int i = 0; i < 4; i++)
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: (i * math.pi / 2),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _scanLineController.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.5),
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrinterIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.8 + (_pulseController.value * 0.2);
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow.withOpacity(_pulseController.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Printer icon
                Icon(
                  Icons.print_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                // Ghost overlay
                Positioned(
                  right: 20,
                  top: 20,
                  child: Icon(
                    Icons.blur_on,
                    size: 24,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 600.ms).scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1, 1),
      curve: Curves.easeOutBack,
      duration: 800.ms,
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'PHANTOM',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 12,
            shadows: [
              Shadow(
                color: AppColors.primaryGlow,
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PRINTER',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 12,
            shadows: [
              Shadow(
                color: AppColors.primaryGlow,
                blurRadius: 20,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
      begin: 0.3,
      end: 0,
      curve: Curves.easeOut,
      duration: 600.ms,
    );
  }

  Widget _buildTagline() {
    return Text(
      'Red Team Dropbox Command Center',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        letterSpacing: 2,
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(
      begin: 0.5,
      end: 0,
      duration: 500.ms,
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          // Terminal-style loading text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'INITIALIZING',
                style: AppTextStyles.terminalSmall.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 4),
              _buildBlinkingCursor(),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: constraints.maxWidth * (0.3 + _pulseController.value * 0.7),
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }

  Widget _buildBlinkingCursor() {
    return Container(
      width: 8,
      height: 14,
      color: AppColors.primary,
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms);
  }

  Widget _buildVersion() {
    return Text(
      'v2.0.0',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCornerDecorations() {
    return Stack(
      children: [
        // Top left
        Positioned(
          top: 50,
          left: 20,
          child: _buildCornerBracket(isTopLeft: true),
        ),
        // Top right
        Positioned(
          top: 50,
          right: 20,
          child: _buildCornerBracket(isTopRight: true),
        ),
        // Bottom left
        Positioned(
          bottom: 50,
          left: 20,
          child: _buildCornerBracket(isBottomLeft: true),
        ),
        // Bottom right
        Positioned(
          bottom: 50,
          right: 20,
          child: _buildCornerBracket(isBottomRight: true),
        ),
      ],
    );
  }

  Widget _buildCornerBracket({
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: CornerBracketPainter(
          color: AppColors.primary.withOpacity(0.3),
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms, duration: 500.ms);
  }
}

// Grid background painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Corner bracket painter
class CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  CornerBracketPainter({
    required this.color,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    const length = 15.0;

    if (isTopLeft) {
      path.moveTo(0, length);
      path.lineTo(0, 0);
      path.lineTo(length, 0);
    } else if (isTopRight) {
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, length);
    } else if (isBottomLeft) {
      path.moveTo(0, size.height - length);
      path.lineTo(0, size.height);
      path.lineTo(length, size.height);
    } else if (isBottomRight) {
      path.moveTo(size.width - length, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}