import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      icon: Icons.monitor_heart_rounded,
      color: AppColors.primary,
      title: 'Predict Your\nHeart Health',
      subtitle:
          'Use our AI-powered model trained on thousands of patients to assess your Cardiovascular Disease (CVD) risk in seconds.',
    ),
    _OnboardPage(
      icon: Icons.insights_rounded,
      color: AppColors.accent,
      title: 'Track Your\nProgress',
      subtitle:
          'View your complete CVD prediction history, monitor trends over time, and understand how your lifestyle affects your heart.',
    ),
    _OnboardPage(
      icon: Icons.health_and_safety_rounded,
      color: AppColors.accentTeal,
      title: 'Stay Healthy,\nStay Safe',
      subtitle:
          'Receive personalized advice, heart health tips, and timely reminders to take charge of your CVD wellness.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c; // ✅ reads AppThemeColors from current ThemeMode

    return Scaffold(
      body: Container(
        // ✅ FIX 1 — uses bgGradient from theme extension (dark or light)
        decoration: BoxDecoration(gradient: c.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/auth'),
                    // ✅ FIX 4 — theme-aware Skip text
                    child: Text(
                      'Skip',
                      style: TextStyle(color: c.textSecondary),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (ctx, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: c.primary,
                        // ✅ FIX 3 — theme-aware inactive dot
                        dotColor: c.cardBorder,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final c = context.c; // ✅ FIX 2 — theme-aware colors via extension

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page.color.withOpacity(0.15),
                border: Border.all(
                  color: page.color.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(page.icon, color: page.color, size: 64),
            ),
          ),
          const SizedBox(height: 48),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              // ✅ FIX 2 — theme-aware primary text
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              page.subtitle,
              textAlign: TextAlign.center,
              // ✅ FIX 2 — theme-aware secondary text
              style: TextStyle(
                fontSize: 16,
                color: c.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}