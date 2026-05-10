import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ for TextInput.finishAutofillContext()
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/supabase_service.dart';
import '../main.dart'; // ✅ for themeNotifier

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  bool _loginPassVisible = false;

  // Signup
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  final _signupConfirmCtrl = TextEditingController();
  final _signupFormKey = GlobalKey<FormState>();
  bool _signupPassVisible = false;

  // OTP
  bool _showOtpScreen = false;
  String _pendingEmail = '';
  String _pendingName = '';
  final _otpCtrl = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    themeNotifier.addListener(_onThemeChange); // ✅
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange); // ✅
    _tabController.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ─── LOGIN ───────────────────────────────────────────
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await SupabaseAuthService.login(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text,
    );
    setState(() => _isLoading = false);
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      // ✅ Triggers "Save password to Google?" prompt
      TextInput.finishAutofillContext();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ─── GOOGLE SIGN IN ──────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    final error = await SupabaseAuthService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (error != null) {
      // Check if it's just user canceling the flow
      if (error == 'Sign in aborted by user') {
        return; 
      }
      _showSnack(error, isError: true);
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ─── FORGOT PASSWORD DIALOG ──────────────────────────
  Future<void> _showForgotPasswordDialog() async {
    final resetEmailCtrl = TextEditingController(text: _loginEmailCtrl.text);
    bool isSending = false;
    bool isSent = false;
    int resendCountdown = 0;
    Timer? countdownTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final c = context.c;

          void startCountdown() {
            setState(() {
              resendCountdown = 60;
            });
            countdownTimer?.cancel();
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (resendCountdown > 0) {
                setState(() {
                  resendCountdown--;
                });
              } else {
                timer.cancel();
              }
            });
          }

          Future<void> handleSend() async {
            if (resetEmailCtrl.text.isEmpty) return;
            setState(() => isSending = true);
            
            final error = await SupabaseAuthService.sendPasswordResetEmail(
              resetEmailCtrl.text.trim(),
            );
            
            if (error != null) {
              // We log or ignore the error to prevent enumeration.
              debugPrint('Reset password error: $error');
            }
            
            setState(() {
              isSending = false;
              isSent = true;
            });
            startCountdown();
          }

          return AlertDialog(
            backgroundColor: c.surface,
            title: Text('Reset Password', style: TextStyle(color: c.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSent) ...[
                  Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: TextStyle(color: c.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    controller: resetEmailCtrl,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ] else ...[
                  Icon(Icons.mark_email_read_rounded, color: c.primary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'If an account is associated with ${resetEmailCtrl.text}, you will receive a password reset link shortly.',
                    style: TextStyle(color: c.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: (resendCountdown == 0 && !isSending) ? handleSend : null,
                    child: Text(
                      resendCountdown > 0 ? 'Resend Email ($resendCountdown s)' : 'Resend Email',
                      style: TextStyle(
                        color: resendCountdown == 0 ? c.primary : c.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  Navigator.pop(context);
                },
                child: Text(isSent ? 'Close' : 'Cancel', style: TextStyle(color: c.textMuted)),
              ),
              if (!isSent)
                isSending 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: handleSend,
                      child: Text('Send Link', style: TextStyle(color: c.primary)),
                    ),
            ],
          );
        },
      ),
    );
    countdownTimer?.cancel();
  }

  // ─── SIGNUP ──────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await SupabaseAuthService.signUp(
      name: _signupNameCtrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      password: _signupPassCtrl.text,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      // ✅ Save new credentials to Google Password Manager
      TextInput.finishAutofillContext();
      setState(() {
        _pendingEmail = _signupEmailCtrl.text.trim();
        _pendingName = _signupNameCtrl.text.trim();
        _showOtpScreen = true;
      });
      _showSnack('OTP sent to ${_signupEmailCtrl.text.trim()} ✅');
    }
  }

  // ─── VERIFY OTP ──────────────────────────────────────
  Future<void> _verifyOtp() async { 
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _pendingEmail,
        token: _otpCtrl.text.trim(),
        type: OtpType.signup,
      );

      setState(() => _isLoading = false);

      if (response.user != null) {
        _showSnack('Email verified! Welcome 🎉');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnack('Invalid OTP. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Invalid or expired OTP.', isError: true);
    }
  }

  // ─── RESEND OTP ──────────────────────────────────────
  Future<void> _resendOtp() async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: _pendingEmail,
      );
      _showSnack('OTP resent to $_pendingEmail ✅');
    } catch (e) {
      _showSnack('Failed to resend OTP.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    final c = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? c.danger : c.success, // ✅
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = themeNotifier.isDark;

    return Scaffold(
      backgroundColor: c.background, // ✅
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.bgGradient : AppColors.lBgGradient, // ✅
        ),
        child: SafeArea(
          child: _showOtpScreen ? _buildOtpScreen(c) : _buildAuthScreen(c),
        ),
      ),
    );
  }

  // ─── OTP SCREEN ──────────────────────────────────────
  Widget _buildOtpScreen(AppThemeColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _otpFormKey,
        child: Column(
          children: [
            const SizedBox(height: 60),

            FadeInDown(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),

            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary, // ✅
                ),
              ),
            ),
            const SizedBox(height: 12),

            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      color: c.textSecondary, // ✅
                      fontSize: 14,
                      height: 1.5),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit OTP to\n'),
                    TextSpan(
                      text: _pendingEmail,
                      style: TextStyle(
                        color: c.primaryLight, // ✅
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ✅ OTP input with autofill
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode], // ✅
                style: TextStyle(
                  color: c.textPrimary, // ✅
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: c.textMuted, // ✅
                    fontSize: 28,
                    letterSpacing: 12,
                  ),
                  filled: true,
                  fillColor: c.surfaceLight, // ✅
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.cardBorder), // ✅
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.cardBorder), // ✅
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: c.primary, width: 2), // ✅
                  ),
                ),
                validator: (v) =>
                    v!.length != 6 ? 'Enter 6-digit OTP' : null,
              ),
            ),

            const SizedBox(height: 32),

            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: GradientButton(
                text: 'Verify OTP',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
            ),

            const SizedBox(height: 20),

            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive OTP? ",
                      style: TextStyle(color: c.textSecondary)), // ✅
                  GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        color: c.primaryLight, // ✅
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: TextButton.icon(
                onPressed: () => setState(() => _showOtpScreen = false),
                icon: Icon(Icons.arrow_back_rounded,
                    color: c.textMuted, size: 18), // ✅
                label: Text('Back to Sign Up',
                    style: TextStyle(color: c.textMuted)), // ✅
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AUTH SCREEN ─────────────────────────────────────
  Widget _buildAuthScreen(AppThemeColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          FadeInDown(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 20),

          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'CardioGuard',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary), // ✅
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Your Cardiovascular Disease (CVD) health companion',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.textSecondary, fontSize: 14), // ✅
            ),
          ),

          const SizedBox(height: 36),

          // ── Tab bar ──────────────────────────────────
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Container(
              decoration: BoxDecoration(
                color: c.surfaceLight, // ✅
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.cardBorder), // ✅
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: c.textSecondary, // ✅
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 580, // Increased to fit Google button
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(c),
                _buildSignupForm(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOGIN FORM ───────────────────────────────────────
  Widget _buildLoginForm(AppThemeColors c) {
    return AutofillGroup( // ✅ enables Google Password Manager
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Email',
              controller: _loginEmailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email], // ✅
              validator: (v) => v!.isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: _loginPassCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_loginPassVisible,
              autofillHints: const [AutofillHints.password], // ✅
              suffix: IconButton(
                icon: Icon(
                  _loginPassVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: c.textMuted, // ✅
                ),
                onPressed: () => setState(
                    () => _loginPassVisible = !_loginPassVisible),
              ),
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            
            // ✅ FORGOT PASSWORD BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            GradientButton(
              text: 'Sign In',
              onPressed: _login,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: c.cardBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR', style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: c.cardBorder)),
              ],
            ),
            const SizedBox(height: 16),
            _buildGoogleButton(c),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text(
                "Don't have an account? Sign Up",
                style: TextStyle(color: c.primaryLight), // ✅
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AppThemeColors c) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _googleSignIn,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: c.cardBorder),
        backgroundColor: c.surfaceLight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c.textPrimary)),
          const SizedBox(width: 12),
          Text('Continue with Google', style: TextStyle(fontSize: 16, color: c.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── SIGNUP FORM ──────────────────────────────────────
  Widget _buildSignupForm(AppThemeColors c) {
    return AutofillGroup( // ✅ enables Google Password Manager
      child: Form(
        key: _signupFormKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Full Name',
              controller: _signupNameCtrl,
              prefixIcon: Icons.person_outline_rounded,
              autofillHints: const [AutofillHints.name], // ✅
              validator: (v) => v!.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email',
              controller: _signupEmailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email], // ✅
              validator: (v) => v!.isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Password',
              controller: _signupPassCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_signupPassVisible,
              autofillHints: const [AutofillHints.newPassword], // ✅
              suffix: IconButton(
                icon: Icon(
                  _signupPassVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: c.textMuted, // ✅
                ),
                onPressed: () => setState(
                    () => _signupPassVisible = !_signupPassVisible),
              ),
              validator: (v) =>
                  v!.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirm Password',
              controller: _signupConfirmCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword], // ✅
              validator: (v) => v != _signupPassCtrl.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Create Account',
              onPressed: _signUp,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: c.cardBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR', style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: c.cardBorder)),
              ],
            ),
            const SizedBox(height: 16),
            _buildGoogleButton(c),
          ],
        ),
      ),
    );
  }
}