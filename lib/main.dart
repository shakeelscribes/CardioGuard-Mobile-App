import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/theme.dart';
import 'utils/theme_notifier.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/input_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reset_password_screen.dart'; // ✅ Added import

// ✅ Global notifier — accessible from anywhere
final themeNotifier = ThemeNotifier();

// ✅ Global navigator key for handling deep links outside of build context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // ✅ Load saved theme before app starts
  await themeNotifier.loadTheme();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CardioGuardApp());
}

class CardioGuardApp extends StatefulWidget {
  const CardioGuardApp({super.key});

  @override
  State<CardioGuardApp> createState() => _CardioGuardAppState();
}

class _CardioGuardAppState extends State<CardioGuardApp> {
  late final StreamSubscription<AuthState> _authSubscription; // ✅ Added stream

  @override
  void initState() {
    super.initState();
    // ✅ Rebuild when theme changes
    themeNotifier.addListener(() => setState(() {}));

    // ✅ Listen for Auth changes, specifically password recovery
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Supabase recognized the reset link! Send user to the new screen.
        navigatorKey.currentState?.pushNamed('/reset-password');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // ✅ Clean up stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Attach the global key here
      title: 'CardioGuard',
      debugShowCheckedModeBanner: false,
      // ✅ Both themes registered
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // ✅ Controlled by notifier
      themeMode: themeNotifier.themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const MainNavigator(),
        '/reset-password': (_) => const ResetPasswordScreen(), // ✅ Add the new route
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  late PageController _pageController;

  static const List<Widget> _screens = [
    HomeScreen(),
    InputFormScreen(),
    HistoryListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void setIndex(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c; // ✅ reads current theme colors
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.bgGradient),
        child: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(c),
    );
  }

  Widget _buildBottomNav(AppThemeColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: c.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: setIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: c.primary,
          unselectedItemColor: c.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_information_outlined),
              activeIcon: Icon(Icons.medical_information_rounded),
              label: 'Check',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}