import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Email might already exist.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() {
          _errorMessage = 'Google Sign-In failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                    Colors.black,
                  ]
                : [
                    Colors.blue[50]!,
                    Colors.white,
                    Colors.grey[50]!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background elements
              Positioned(
                top: -100,
                right: -100,
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _backgroundAnimation.value,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.08),
                              colorScheme.primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_backgroundAnimation.value * 0.7,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.secondary.withOpacity(0.06),
                              colorScheme.secondary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.15,
                left: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.15,
                right: -70,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondary.withOpacity(0.04),
                  ),
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and Brand Section
                        Container(
                          margin: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            children: [
                              // Logo with glow effect
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/premier.png',
                                  width: 120,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 48,
                                      color: colorScheme.primary,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.grey[900],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLoginMode
                                    ? 'Sign in to continue to My Premier'
                                    : 'Create your account to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Auth Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[900]!.withOpacity(0.95)
                                : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.05),
                                blurRadius: 60,
                                offset: const Offset(0, 20),
                                spreadRadius: -10,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Mode Toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]!.withOpacity(0.6)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: _isLoginMode
                                              ? LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    colorScheme.primary
                                                        .withOpacity(0.9),
                                                    colorScheme.primary,
                                                  ],
                                                )
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: _isLoginMode
                                              ? [
                                                  BoxShadow(
                                                    color: colorScheme.primary
                                                        .withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 6),
                                                    spreadRadius: 0,
                                                  )
                                                ]
                                              : null,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!_isLoginMode) {
                                              setState(() {
                                                _isLoginMode = true;
                                                _errorMessage = null;
                                                _fullNameController.clear();
                                                _phoneController.clear();
                                              });
                                            }
                                          },
                                          child: Text(
                                            'Login',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: _isLoginMode
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: !_isLoginMode
                                              ? LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    colorScheme.primary
                                                        .withOpacity(0.9),
                                                    colorScheme.primary,
                                                  ],
                                                )
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: !_isLoginMode
                                              ? [
                                                  BoxShadow(
                                                    color: colorScheme.primary
                                                        .withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 6),
                                                    spreadRadius: 0,
                                                  )
                                                ]
                                              : null,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_isLoginMode) {
                                              setState(() {
                                                _isLoginMode = false;
                                                _errorMessage = null;
                                              });
                                            }
                                          },
                                          child: Text(
                                            'Register',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: !_isLoginMode
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Error message
                              if (_errorMessage != null)
                                AnimatedSlide(
                                  duration: const Duration(milliseconds: 300),
                                  offset:
                                      Offset(_errorMessage != null ? 0 : -1, 0),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red.withOpacity(0.1),
                                          ),
                                          child: Icon(
                                            Icons.error_outline_rounded,
                                            size: 20,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Colors.red[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (_errorMessage != null)
                                const SizedBox(height: 24),

                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Full Name field - Only for Register
                                    if (!_isLoginMode)
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: _fullNameController,
                                              keyboardType: TextInputType.name,
                                              textInputAction:
                                                  TextInputAction.next,
                                              style:
                                                  const TextStyle(fontSize: 15),
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Full Name (Optional)',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.person_outline_rounded,
                                                  color: Colors.grey[500],
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                filled: true,
                                                fillColor: isDark
                                                    ? Colors.grey[800]
                                                    : Colors.grey[50],
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),

                                    // Email field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(fontSize: 15),
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Colors.grey[500],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[50],
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Phone field - Only for Register
                                    if (!_isLoginMode)
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: _phoneController,
                                              keyboardType: TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.next,
                                              style:
                                                  const TextStyle(fontSize: 15),
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Phone Number (Optional)',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.phone_outlined,
                                                  color: Colors.grey[500],
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                filled: true,
                                                fillColor: isDark
                                                    ? Colors.grey[800]
                                                    : Colors.grey[50],
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),

                                    // Password field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _isLoginMode
                                          ? _handleLogin()
                                          : _handleRegister(),
                                      style: const TextStyle(fontSize: 15),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline_rounded,
                                          color: Colors.grey[500],
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.grey[500],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[50],
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (!_isLoginMode && value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : (_isLoginMode
                                          ? _handleLogin
                                          : _handleRegister),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    disabledBackgroundColor:
                                        colorScheme.primary.withOpacity(0.5),
                                  ).copyWith(
                                    elevation: MaterialStateProperty
                                        .resolveWith<double>(
                                      (Set<MaterialState> states) {
                                        if (states
                                            .contains(MaterialState.disabled)) {
                                          return 0;
                                        }
                                        return 8;
                                      },
                                    ),
                                    shadowColor: MaterialStateProperty.all(
                                      colorScheme.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isLoginMode
                                                  ? 'Sign In'
                                                  : 'Create Account',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.withOpacity(0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'or continue with',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.withOpacity(0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Google Sign-In button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _handleGoogleSignIn,
                                  icon: Container(
                                    width: 24,
                                    height: 24,
                                    child: Image.network(
                                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.g_mobiledata_rounded,
                                          size: 24,
                                        );
                                      },
                                    ),
                                  ),
                                  label: Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey[800],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.grey[900]!.withOpacity(0.6)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Footer
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[900]!.withOpacity(0.5)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '© 2024 PT Premier Engineering Indonesia.\nAll rights reserved.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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
