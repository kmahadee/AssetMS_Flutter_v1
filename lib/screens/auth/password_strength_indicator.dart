import 'package:flutter/material.dart';

/// Password strength indicator widget
/// 
/// Displays visual feedback for password strength with color-coded
/// bars and labels. Helps users create secure passwords.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showCriteria;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showCriteria = false,
  });

  /// Calculate password strength (0-3)
  int _calculateStrength() {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 1;
    
    int strength = 1;
    
    // Length check
    if (password.length >= 8) strength++;
    
    // Has uppercase and lowercase
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) {
      strength++;
    }
    
    // Has numbers
    if (password.contains(RegExp(r'[0-9]'))) {
      strength++;
    }
    
    // Has special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength++;
    }
    
    return strength.clamp(0, 3);
  }

  /// Get strength label
  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Medium';
      case 3:
        return 'Strong';
      default:
        return '';
    }
  }

  /// Get strength color
  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  /// Check if criteria is met
  bool _hasMinLength() => password.length >= 6;
  bool _hasUppercase() => password.contains(RegExp(r'[A-Z]'));
  bool _hasNumber() => password.contains(RegExp(r'[0-9]'));

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculateStrength();
    final color = _getStrengthColor(strength);
    final label = _getStrengthLabel(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bars
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 1 ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 2 ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 3 ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        
        // Strength label
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Criteria checklist
        if (showCriteria && password.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCriteriaItem(
                  'At least 6 characters',
                  _hasMinLength(),
                ),
                _buildCriteriaItem(
                  'Contains uppercase letter',
                  _hasUppercase(),
                ),
                _buildCriteriaItem(
                  'Contains number',
                  _hasNumber(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCriteriaItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}