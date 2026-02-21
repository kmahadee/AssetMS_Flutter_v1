import 'package:flutter/material.dart';
import 'package:portfolio_tracker/database/auth_service.dart';
import 'package:portfolio_tracker/screens/auth/form_field_widget.dart';
// import 'package:portfolio_tracker/screens/home_screen.dart';

import 'package:provider/provider.dart';
import 'package:portfolio_tracker/providers/auth_provider.dart';

import 'register_screen.dart';

/// Beautiful login screen with gradient background and form validation
///
/// Provides user authentication with smooth animations and error handling.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _usernameError;
  String? _passwordError;

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

    // Auto-focus username field
    Future.delayed(const Duration(milliseconds: 500), () {
      _usernameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validateUsername() {
    setState(() {
      if (_usernameController.text.isEmpty) {
        _usernameError = 'Username is required';
      } else if (_usernameController.text.length < 3) {
        _usernameError = 'Username must be at least 3 characters';
      } else {
        _usernameError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password is required';
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  // Future<void> _handleLogin() async {
  //   // Validate fields
  //   _validateUsername();
  //   _validatePassword();

  //   if (_usernameError != null || _passwordError != null) {
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   try {
  //     final user = await _authService.loginUser(
  //       _usernameController.text.trim(),
  //       _passwordController.text,
  //     );

  //     if (!mounted) return;

  //     if (user != null) {
  //       // Success - navigate to home screen
  //       Navigator.of(context).pushReplacement(
  //         MaterialPageRoute(builder: (context) => const HomeScreen()),
  //       );
  //     } else {
  //       setState(() {
  //         _errorMessage = 'Invalid username or password';
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _errorMessage = 'Login failed. Please try again.';
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _handleLogin() async {
    // Validate fields
    _validateUsername();
    _validatePassword();

    if (_usernameError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // IMPORTANT: Use AuthProvider instead of AuthService directly
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Success - navigate to home screen using the helper
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? 'Invalid username or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
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

                      // App title
                      const Text(
                        'Portfolio Tracker',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      const Text(
                        'Track your investments with ease',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 40),

                      // Login form card
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginCard(),
                      ),
                      const SizedBox(height: 24),

                      // Divider with OR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 1,
                            width: 60,
                            color: Colors.white30,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 60,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Demo credentials hint
                      const Text(
                        'Demo: demo / demo123',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
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
        size: 50,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildLoginCard() {
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
              // Username field
              FormFieldWidget(
                label: 'Username',
                controller: _usernameController,
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                focusNode: _usernameFocus,
                enabled: !_isLoading,
                errorText: _usernameError,
                isValid:
                    _usernameError == null &&
                    _usernameController.text.isNotEmpty,
                onChanged: (value) {
                  if (_usernameError != null) {
                    _validateUsername();
                  }
                },
                onSubmitted: (_) {
                  _passwordFocus.requestFocus();
                },
              ),
              const SizedBox(height: 16),

              // Password field
              FormFieldWidget(
                label: 'Password',
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                focusNode: _passwordFocus,
                enabled: !_isLoading,
                errorText: _passwordError,
                isValid:
                    _passwordError == null &&
                    _passwordController.text.isNotEmpty,
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
                onChanged: (value) {
                  if (_passwordError != null) {
                    _validatePassword();
                  }
                },
                onSubmitted: (_) {
                  _handleLogin();
                },
              ),
              const SizedBox(height: 8),

              // Forgot password (disabled for demo)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: null,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null)
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
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                        'Login',
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
}
