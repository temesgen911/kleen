import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/auth_state_notifier.dart';
import '../splash/cleaning_logo_painter.dart';
import 'widgets/auth_text_field.dart';

/// Dark-mode luxury Sign Up / Account Creation Screen for Cleaning AI.
class SignUpScreen extends StatefulWidget {
  final AuthStateNotifier authNotifier;

  const SignUpScreen({
    super.key,
    required this.authNotifier,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    widget.authNotifier.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthStateChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.authNotifier.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      // If sign up succeeded, pop to root AuthGate which will route to HomeScreen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!success && mounted && widget.authNotifier.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.authNotifier.errorMessage!,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.accentCoral.withValues(alpha: 0.95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 6) strength += 0.33;
    if (password.length >= 8) strength += 0.33;
    if (RegExp(r'[0-9]').hasMatch(password) && RegExp(r'[a-zA-Z]').hasMatch(password)) {
      strength += 0.34;
    }
    return strength.clamp(0.0, 1.0);
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength <= 0.34) return AppColors.accentCoral;
    if (strength <= 0.67) return AppColors.accentOrange;
    return AppColors.primaryTeal;
  }

  String _getPasswordStrengthLabel(double strength) {
    if (strength <= 0.0) return '';
    if (strength <= 0.34) return 'Weak';
    if (strength <= 0.67) return 'Medium';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authNotifier.isLoading;
    final passwordStrength = _calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundStart,
              Color(0xFF04060B),
              AppColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mini Emblem
                      Center(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: CustomPaint(
                            size: const Size(64, 64),
                            painter: CleaningLogoPainter(
                              curveProgress: 1.0,
                              sparkleProgress: 1.0,
                              sparkleFlash: 0.0,
                              shockwaveProgress: 0.0,
                              ambientGlowAlpha: 0.7,
                              breathScale: 1.0,
                              logoOpacity: 1.0,
                              globalScale: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start your personalized smart cleaning journey',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Full Name Field
                      AuthTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Emma Watson',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Email Field
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'emma@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email.';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Password Field
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'At least 6 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                      ),

                      // Password Strength Indicator
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: passwordStrength,
                                  backgroundColor: AppColors.borderWhite.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getPasswordStrengthColor(passwordStrength),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getPasswordStrengthLabel(passwordStrength),
                              style: AppTypography.caption.copyWith(
                                color: _getPasswordStrengthColor(passwordStrength),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Confirm Password Field
                      AuthTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hintText: 'Repeat password',
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSignUp(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Create Account Button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryTeal,
                              Color(0xFF00E5C8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.backgroundStart,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.backgroundStart,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Already have account
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Sign In',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
}
