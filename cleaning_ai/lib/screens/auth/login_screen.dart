import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/auth_state_notifier.dart';
import '../../widgets/google_logo_icon.dart';
import '../splash/cleaning_logo_painter.dart';
import 'signup_screen.dart';
import 'widgets/auth_text_field.dart';

/// Dark-mode luxury Login Screen for kleenai with Google Sign-In & Email Auth.
class LoginScreen extends StatefulWidget {
  final AuthStateNotifier authNotifier;

  const LoginScreen({
    super.key,
    required this.authNotifier,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;

  @override
  void initState() {
    super.initState();
    widget.authNotifier.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.authNotifier.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!success && mounted && widget.authNotifier.errorMessage != null) {
      _showErrorSnackBar(widget.authNotifier.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
      final success = await widget.authNotifier.signInWithGoogle();
      if (!success && mounted && widget.authNotifier.errorMessage != null) {
        _showErrorSnackBar(widget.authNotifier.errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGuestLoading = true);

    try {
      final success = await widget.authNotifier.signInAsGuest();
      if (!success && mounted && widget.authNotifier.errorMessage != null) {
        _showErrorSnackBar(widget.authNotifier.errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() => _isGuestLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.accentCoral.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.borderWhite.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          title: Text(
            'Reset Password',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your email address and we will send you a link to reset your password.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: resetEmailController,
                  label: 'Email',
                  hintText: 'name@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.backgroundStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                if (!resetFormKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();
                final sent = await widget.authNotifier.sendPasswordResetEmail(
                  email: resetEmailController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sent
                            ? 'Password reset email sent! Check your inbox.'
                            : 'Could not send reset email. Please try again.',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      backgroundColor: sent ? AppColors.primaryTeal : AppColors.accentCoral,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Text(
                'Send Link',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundStart,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authNotifier.isLoading;
    final isAnyLoading = isLoading || _isGoogleLoading || _isGuestLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated Logo Symbol
                      Center(
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: CustomPaint(
                            size: const Size(84, 84),
                            painter: CleaningLogoPainter(
                              curveProgress: 1.0,
                              sparkleProgress: 1.0,
                              sparkleFlash: 0.0,
                              shockwaveProgress: 0.0,
                              ambientGlowAlpha: 0.8,
                              breathScale: 1.0,
                              logoOpacity: 1.0,
                              globalScale: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // App Title & Subtitle
                      Text(
                        'Welcome to kleenai',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to continue your intelligent cleaning routine',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Google Sign-In Button
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.surfaceDark.withValues(alpha: 0.85),
                          border: Border.all(
                            color: AppColors.borderWhite.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isAnyLoading ? null : _handleGoogleSignIn,
                            child: Center(
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.primaryTeal,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const GoogleLogoIcon(size: 22),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Continue with Google',
                                          style: AppTypography.titleMedium.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Apple Sign-In Button
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isAnyLoading
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();
                                    final success = await widget.authNotifier.signInWithApple();
                                    if (!success && mounted && widget.authNotifier.errorMessage != null) {
                                      _showErrorSnackBar(widget.authNotifier.errorMessage!);
                                    }
                                  },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.apple, color: Colors.white, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Continue with Apple',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Continue as Guest Button
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.primaryTeal.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isAnyLoading ? null : _handleGuestSignIn,
                            child: Center(
                              child: _isGuestLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.primaryTeal,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 20,
                                          color: AppColors.primaryTeal,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Continue as Guest',
                                          style: AppTypography.titleMedium.copyWith(
                                            color: AppColors.primaryTeal,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Elegant Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.borderWhite.withValues(alpha: 0.05),
                                    AppColors.borderWhite.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.borderWhite.withValues(alpha: 0.3),
                                    AppColors.borderWhite.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'emma@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address.';
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
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSignIn(),
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
                            return 'Please enter your password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),
                          child: Text(
                            'Forgot password?',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign In Button
                      Container(
                        height: 54,
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
                          onPressed: isAnyLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.backgroundStart,
                                  ),
                                )
                              : Text(
                                  'Sign In with Email',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.backgroundStart,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sign Up Option
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(authNotifier: widget.authNotifier),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              'Create Account',
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
