import 'package:flutter/material.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/screens/auth/form_field_widget.dart';
import 'package:portfolio_tracker/screens/auth/password_strength_indicator.dart';
import 'dart:async';
import 'onboarding_screen.dart';

/// Registration screen with comprehensive form validation
///
/// Provides user registration with real-time validation, password strength
/// indicator, and username availability checking.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;
  bool _usernameAvailable = true;
  bool _checkingUsername = false;

  String? _fullNameError;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  Timer? _usernameDebounce;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();

    // Add listeners for real-time validation
    _fullNameController.addListener(_validateFullName);
    _emailController.addListener(_validateEmail);
    _usernameController.addListener(_onUsernameChanged);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _usernameDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _validateFullName() {
    if (!mounted) return;
    setState(() {
      if (_fullNameController.text.isEmpty) {
        _fullNameError = null; // Don't show error for empty field
      } else if (_fullNameController.text.length < 2) {
        _fullNameError = 'Name must be at least 2 characters';
      } else {
        _fullNameError = null;
      }
    });
  }

  void _validateEmail() {
    if (!mounted) return;
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = null;
      } else if (!_emailController.text.contains('@') ||
          !_emailController.text.contains('.')) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _onUsernameChanged() {
    if (!mounted) return;

    // Cancel previous timer
    _usernameDebounce?.cancel();

    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = null;
        _usernameAvailable = true;
      });
      return;
    }

    // Basic validation first
    if (_usernameController.text.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
        _usernameAvailable = false;
      });
      return;
    }

    // Check availability with debounce
    setState(() {
      _checkingUsername = true;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await _authService.isUsernameAvailable(
        _usernameController.text,
      );
      if (!mounted) return;
      setState(() {
        _usernameAvailable = available;
        _usernameError = available ? null : 'Username already taken';
        _checkingUsername = false;
      });
    });
  }

  void _validatePassword() {
    if (!mounted) return;
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = null;
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
      // Also revalidate confirm password
      if (_confirmPasswordController.text.isNotEmpty) {
        _validateConfirmPassword();
      }
    });
  }

  void _validateConfirmPassword() {
    if (!mounted) return;
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  bool _validateAllFields() {
    bool isValid = true;

    if (_fullNameController.text.isEmpty) {
      _fullNameError = 'Full name is required';
      isValid = false;
    }

    if (_emailController.text.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    }

    if (_usernameController.text.isEmpty) {
      _usernameError = 'Username is required';
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    }

    setState(() {});
    return isValid &&
        _fullNameError == null &&
        _emailError == null &&
        _usernameError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _usernameAvailable;
  }

  Future<void> _handleRegister() async {
    if (!_validateAllFields()) {
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _generalError = 'Please agree to the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final userId = await _authService.registerUser(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _fullNameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Auto-login
      await _authService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(userId: userId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generalError = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App logo
                            _buildLogo(),
                            const SizedBox(height: 16),

                            // Title
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Registration form
                            SlideTransition(
                              position: _slideAnimation,
                              child: _buildRegistrationCard(),
                            ),
                            const SizedBox(height: 16),

                            // Login link
                            _buildLoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.show_chart,
        size: 40,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildRegistrationCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              FormFieldWidget(
                label: 'Full Name',
                controller: _fullNameController,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                focusNode: _fullNameFocus,
                enabled: !_isLoading,
                errorText: _fullNameError,
                isValid:
                    _fullNameError == null &&
                    _fullNameController.text.length >= 2,
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Email
              FormFieldWidget(
                label: 'Email',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                focusNode: _emailFocus,
                enabled: !_isLoading,
                errorText: _emailError,
                isValid:
                    _emailError == null && _emailController.text.isNotEmpty,
                onSubmitted: (_) => _usernameFocus.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Username
              FormFieldWidget(
                label: 'Username',
                controller: _usernameController,
                prefixIcon: Icons.alternate_email,
                textInputAction: TextInputAction.next,
                focusNode: _usernameFocus,
                enabled: !_isLoading,
                errorText: _usernameError,
                isValid:
                    _usernameAvailable &&
                    _usernameError == null &&
                    _usernameController.text.isNotEmpty,
                suffixWidget: _checkingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Password
              FormFieldWidget(
                label: 'Password',
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                focusNode: _passwordFocus,
                enabled: !_isLoading,
                errorText: _passwordError,
                isValid:
                    _passwordError == null &&
                    _passwordController.text.length >= 6,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              ),
              const SizedBox(height: 8),

              // Password strength indicator
              if (_passwordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PasswordStrengthIndicator(
                    password: _passwordController.text,
                    showCriteria: false,
                  ),
                ),

              if (_passwordController.text.isEmpty) const SizedBox(height: 16),

              // Confirm Password
              FormFieldWidget(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                focusNode: _confirmPasswordFocus,
                enabled: !_isLoading,
                errorText: _confirmPasswordError,
                isValid:
                    _confirmPasswordError == null &&
                    _confirmPasswordController.text.isNotEmpty,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                onSubmitted: (_) => _handleRegister(),
              ),
              const SizedBox(height: 16),

              // Terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms & Conditions',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              // General error message
              if (_generalError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Register button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
