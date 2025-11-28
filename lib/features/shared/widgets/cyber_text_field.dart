// lib/features/shared/widgets/cyber_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class CyberTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final Color? accentColor;
  final bool showCounter;

  const CyberTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.onSuffixTap,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.accentColor,
    this.showCounter = false,
  });

  @override
  State<CyberTextField> createState() => _CyberTextFieldState();
}

class _CyberTextFieldState extends State<CyberTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _glowController;
  bool _isFocused = false;
  bool _obscureText = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _glowController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _glowController.forward();
    } else {
      _glowController.reverse();
    }
  }

  Color get _accentColor => widget.accentColor ?? AppColors.primary;

  Color get _borderColor {
    if (_errorText != null || widget.errorText != null) {
      return AppColors.error;
    }
    if (_isFocused) {
      return _accentColor;
    }
    return AppColors.cardBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isFocused ? _accentColor : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Text field container
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.2 * _glowController.value),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: widget.isPassword && _obscureText,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            cursorColor: _accentColor,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
              errorText: widget.errorText ?? _errorText,
              errorStyle: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
              helperText: widget.helperText,
              helperStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              counterText: widget.showCounter ? null : '',
              filled: true,
              fillColor: widget.enabled ? AppColors.surface : AppColors.cardBackground,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 12 : 16,
                vertical: 16,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isFocused ? _accentColor : AppColors.textMuted,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              suffixIcon: _buildSuffixIcon(),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accentColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
              ),
            ),
            validator: (value) {
              final error = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _errorText = error);
                }
              });
              return error;
            },
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffix != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: widget.suffix,
      );
    }

    if (widget.isPassword) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          onPressed: () {
            setState(() => _obscureText = !_obscureText);
            HapticFeedback.selectionClick();
          },
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          onPressed: widget.onSuffixTap,
          icon: Icon(
            widget.suffixIcon,
            size: 20,
            color: _isFocused ? _accentColor : AppColors.textMuted,
          ),
        ),
      );
    }

    return null;
  }
}

/// Terminal-style text field with monospace font
class TerminalTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const TerminalTextField({
    super.key,
    this.controller,
    this.hint,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<TerminalTextField> createState() => _TerminalTextFieldState();
}

class _TerminalTextFieldState extends State<TerminalTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isFocused ? AppColors.terminalGreen : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.terminalGreenGlow,
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Prompt
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              '\$',
              style: AppTextStyles.terminalMedium.copyWith(
                color: AppColors.terminalGreen,
              ),
            ),
          ),
          
          // Input
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              style: AppTextStyles.terminalMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.terminalGreen,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.terminalMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
              onSubmitted: widget.onSubmitted,
            ),
          ),
          
          // Blinking cursor indicator when focused
          if (_isFocused)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _BlinkingCursor(),
            ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 8,
            height: 16,
            color: AppColors.terminalGreen,
          ),
        );
      },
    );
  }
}

/// Search field with clear button
class CyberSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const CyberSearchField({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  State<CyberSearchField> createState() => _CyberSearchFieldState();
}

class _CyberSearchFieldState extends State<CyberSearchField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return CyberTextField(
      controller: _controller,
      hint: widget.hint,
      prefixIcon: Icons.search,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      suffix: _hasText
          ? GestureDetector(
              onTap: _clear,
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.textMuted,
              ),
            )
          : null,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

/// Multi-line code/command input
class CodeInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final void Function(String)? onChanged;
  final bool readOnly;

  const CodeInputField({
    super.key,
    this.controller,
    this.hint,
    this.minLines = 3,
    this.maxLines = 10,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        minLines: minLines,
        maxLines: maxLines,
        style: AppTextStyles.codeLarge,
        cursorColor: AppColors.terminalGreen,
        decoration: InputDecoration(
          hintText: hint ?? '# Enter command or code...',
          hintStyle: AppTextStyles.codeLarge.copyWith(
            color: AppColors.textMuted,
          ),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: onChanged,
      ),
    );
  }
}