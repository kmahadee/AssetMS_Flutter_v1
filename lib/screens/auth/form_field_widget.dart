import 'package:flutter/material.dart';

/// Reusable custom form field widget with animations and validation
/// 
/// Provides a consistent, beautiful text input experience across the app
/// with label animations, icons, validation states, and error messages.
class FormFieldWidget extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final void Function(String)? onChanged;
  final bool enabled;
  final int? maxLength;
  final bool showCounter;
  final String? errorText;
  final bool isValid;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const FormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.onChanged,
    this.enabled = true,
    this.maxLength,
    this.showCounter = false,
    this.errorText,
    this.isValid = false,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<FormFieldWidget> createState() => _FormFieldWidgetState();
}

class _FormFieldWidgetState extends State<FormFieldWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FormFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake animation when error appears
    if (widget.errorText != null && oldWidget.errorText == null) {
      _animationController.forward(from: 0);
    }
  }

  Color _getBorderColor() {
    if (!widget.enabled) {
      return Colors.grey.shade300;
    }
    if (widget.errorText != null) {
      return Colors.red;
    }
    if (widget.isValid && widget.controller.text.isNotEmpty) {
      return Colors.green;
    }
    if (_isFocused) {
      return Theme.of(context).primaryColor;
    }
    return Colors.grey.shade400;
  }

  Widget? _buildValidationIcon() {
    if (widget.controller.text.isEmpty) return null;
    
    if (widget.errorText != null) {
      return const Icon(Icons.error, color: Colors.red, size: 20);
    }
    if (widget.isValid) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _isFocused = hasFocus;
              });
            },
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              enabled: widget.enabled,
              maxLength: widget.showCounter ? widget.maxLength : null,
              textInputAction: widget.textInputAction,
              onFieldSubmitted: widget.onSubmitted,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              style: TextStyle(
                fontSize: 16,
                color: widget.enabled ? Colors.black87 : Colors.grey,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: TextStyle(
                  color: _isFocused
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _getBorderColor(),
                      )
                    : null,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_buildValidationIcon() != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildValidationIcon()!,
                      ),
                    if (widget.suffixWidget != null) widget.suffixWidget!,
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _getBorderColor()),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: widget.validator,
            ),
          ),
          if (widget.errorText != null)
            AnimatedOpacity(
              opacity: widget.errorText != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}