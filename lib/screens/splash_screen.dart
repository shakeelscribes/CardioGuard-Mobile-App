import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/theme.dart';
import '../main.dart'; // ✅ for themeNotifier

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'Starting up...';
  double _progress = 0.0;

  static const String _backendUrl =
      'https://cardiovascluar-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ✅ Rebuild when theme changes (edge case — user switches mid-splash)
    themeNotifier.addListener(_onThemeChange);

    _initializeApp();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeApp() async {
    _updateStatus('Loading CardioGuard...', 0.1);
    await Future.delayed(const Duration(milliseconds: 500));

    _updateStatus('Connecting to server...', 0.3);
    await _wakeUpServer();

    _updateStatus('Checking your account...', 0.7);
    await Future.delayed(const Duration(milliseconds: 500));

    _updateStatus('Ready! ✅', 1.0);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  Future<void> _wakeUpServer() async {
    try {
      await http
          .get(Uri.parse('$_backendUrl/'))
          .timeout(const Duration(seconds: 55));
      _updateStatus('Server ready ✅', 0.6);
    } catch (e) {
      _updateStatus('Connecting...', 0.6);
    }
  }

  void _updateStatus(String message, double progress) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Read theme from notifier — already loaded before runApp()
    final isDark = themeNotifier.isDark;

    // ✅ Pick correct colors based on theme
    final bgGradient = isDark ? AppColors.bgGradient : AppColors.lBgGradient;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lTextMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColors.lCardBorder;

    return Scaffold(
      // ✅ Scaffold background matches theme
      backgroundColor:
          isDark ? AppColors.background : AppColors.lBackground,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient), // ✅
        child: Stack(
          children: [
            // ── Top-left glow ─────────────────────────────────
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withOpacity(
                        isDark ? 0.15 : 0.08), // ✅ subtler in light
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // ── Bottom-right glow ─────────────────────────────
            Positioned(
              bottom: -150,
              right: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accent.withOpacity(
                        isDark ? 0.1 : 0.05), // ✅ subtler in light
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Pulsing heart icon ─────────────────────
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(
                                  isDark ? 0.5 : 0.3), // ✅ softer in light
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 55),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── App name ───────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'CardioGuard',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Tagline ────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Cardiovascular Disease (CVD) Risk Prediction Application',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary, // ✅
                          letterSpacing: 1.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Progress bar + status ──────────────────
                  FadeIn(
                    delay: const Duration(milliseconds: 800),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: cardBorder, // ✅
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _statusMessage,
                              key: ValueKey(_statusMessage),
                              style: TextStyle(
                                color: textSecondary, // ✅
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Version text ──────────────────────────────────
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeIn(
                delay: const Duration(milliseconds: 1000),
                child: Text(
                  'v1.0.0 • Fueled by Team STR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted, // ✅
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}