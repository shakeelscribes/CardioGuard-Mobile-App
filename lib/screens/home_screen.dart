import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  List<PredictionRecord> _history = [];
  StreamSubscription? _profileSub;
  int? _touchedIndex;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<_HealthTipData> _tipsData = [
    _HealthTipData(Icons.directions_walk_rounded, 'Exercise Daily',
        '30 min of brisk walking reduces CVD risk by up to 35%.', 'primary'),
    _HealthTipData(Icons.no_meals_rounded, 'Reduce Sodium',
        'Limit salt to under 5g per day to protect blood pressure.', 'accent'),
    _HealthTipData(Icons.local_drink_rounded, 'Stay Hydrated',
        'Drink 8 glasses of water daily for optimal heart function.', 'teal'),
    _HealthTipData(Icons.bedtime_rounded, 'Sleep Well',
        '7-8 hours of quality sleep reduces heart disease risk.', 'warning'),
    _HealthTipData(Icons.smoke_free_rounded, 'Quit Smoking',
        'Stopping smoking halves your risk of heart disease in 1 year.',
        'danger'),
    _HealthTipData(Icons.self_improvement_rounded, 'Manage Stress',
        'Chronic stress raises blood pressure and increases CVD risk.',
        'primaryLight'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _subscribeToProfile();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _profileSub?.cancel();
    super.dispose();
  }

  void _subscribeToProfile() {
    _profileSub?.cancel();
    _profileSub = SupabaseAuthService.profileStream().listen((profile) {
      if (mounted) setState(() => _profile = profile);
    });
  }

  Future<void> _loadHistory() async {
    try {
      final data = await SupabaseHistoryService.getHistory();
      final records = data
          .map((e) => PredictionRecord(
                id: e['id'].toString(),
                date: DateTime.parse(e['date']),
                gender: e['gender'],
                ageYears: e['age_years'],
                height: e['height'],
                weight: (e['weight'] as num).toDouble(),
                apHi: e['ap_hi'],
                apLo: e['ap_lo'],
                cholesterol: e['cholesterol'],
                gluc: e['gluc'],
                smoke: e['smoke'],
                alco: e['alco'],
                active: e['active'],
                prediction: e['prediction'],
                probability: (e['probability'] as num).toDouble(),
                riskLevel: e['risk_level'],
                advice: e['advice'],
                bmi: (e['bmi'] as num).toDouble(),
                bmiCategory: e['bmi_category'],
              ))
          .toList();
      if (mounted) setState(() => _history = records);
    } catch (_) {}
  }

  Future<void> _load() async {
    _subscribeToProfile();
    await _loadHistory();
  }

  // ── Helpers ─────────────────────────────────────────────────

  String get _displayName {
    final name = _profile?['name']?.toString() ?? '';
    return name.isNotEmpty ? name.split(' ').first : 'User';
  }

  String get _avatarLetter {
    final name = _profile?['name']?.toString() ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  _HealthTipData get _tipOfTheDay =>
      _tipsData[DateTime.now().day % _tipsData.length];

  int get _streak {
    if (_history.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = DateTime(today.year, today.month, today.day - i);
      final hasCheck = _history.any((r) =>
          r.date.year == day.year &&
          r.date.month == day.month &&
          r.date.day == day.day);
      if (hasCheck) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String get _trendText {
    if (_history.length < 2) return '';
    final diff = _history[0].probability - _history[1].probability;
    if (diff.abs() < 1) return 'Same as last check →';
    return diff < 0
        ? 'Risk dropped ${diff.abs().toStringAsFixed(1)}% ↓'
        : 'Risk rose ${diff.abs().toStringAsFixed(1)}% ↑';
  }

  Color _trendColor(AppThemeColors c) {
    if (_history.length < 2) return c.textMuted;
    final diff = _history[0].probability - _history[1].probability;
    if (diff.abs() < 1) return c.textMuted;
    return diff < 0 ? c.success : c.danger;
  }

  Color _tipColor(_HealthTipData tip, AppThemeColors c) {
    switch (tip.colorKey) {
      case 'accent':
        return c.accent;
      case 'teal':
        return c.accentTeal;
      case 'warning':
        return c.warning;
      case 'danger':
        return c.danger;
      case 'primaryLight':
        return c.primaryLight;
      default:
        return c.primary;
    }
  }

  // ── Show detail bottom sheet on dot tap ──────────────────────
  void _showRecordDetail(BuildContext context, PredictionRecord r) {
    final c = context.c;
    Color riskColor;
    switch (r.riskLevel.toLowerCase()) {
      case 'low':
        riskColor = c.success;
        break;
      case 'medium':
        riskColor = c.warning;
        break;
      default:
        riskColor = c.danger;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: c.cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header row
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: riskColor.withOpacity(0.15),
                    border:
                        Border.all(color: riskColor.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${r.probability.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RiskBadge(riskLevel: r.riskLevel),
                          const SizedBox(width: 8),
                          Text(
                            r.prediction
                                ? 'CVD Detected'
                                : 'No CVD Detected',
                            style: TextStyle(
                              color: r.prediction ? c.danger : c.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('EEEE, MMM d yyyy • h:mm a').format(r.date),
                        style:
                            TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: c.divider),
            const SizedBox(height: 16),

            // ── Vital Stats Grid ─────────────────────────────
            Text(
              'Vital Statistics',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _DetailStat(
                  label: 'Blood Pressure',
                  value: '${r.apHi}/${r.apLo}',
                  unit: 'mmHg',
                  icon: Icons.favorite_rounded,
                  color: c.accent,
                  c: c,
                ),
                _DetailStat(
                  label: 'BMI',
                  value: r.bmi.toStringAsFixed(1),
                  unit: r.bmiCategory,
                  icon: Icons.monitor_weight_rounded,
                  color: r.bmi < 25 ? c.success : c.warning,
                  c: c,
                ),
                _DetailStat(
                  label: 'Age',
                  value: '${r.ageYears}',
                  unit: 'years',
                  icon: Icons.cake_rounded,
                  color: c.primary,
                  c: c,
                ),
                _DetailStat(
                  label: 'Cholesterol',
                  value: r.cholesterol == 1
                      ? 'Normal'
                      : r.cholesterol == 2
                          ? 'High'
                          : 'Very High',
                  unit: 'level',
                  icon: Icons.bloodtype_rounded,
                  color: r.cholesterol == 1
                      ? c.success
                      : r.cholesterol == 2
                          ? c.warning
                          : c.danger,
                  c: c,
                ),
                _DetailStat(
                  label: 'Glucose',
                  value: r.gluc == 1
                      ? 'Normal'
                      : r.gluc == 2
                          ? 'High'
                          : 'Very High',
                  unit: 'level',
                  icon: Icons.water_drop_rounded,
                  color: r.gluc == 1
                      ? c.success
                      : r.gluc == 2
                          ? c.warning
                          : c.danger,
                  c: c,
                ),
                _DetailStat(
                  label: 'Gender',
                  value: r.gender == 1 ? 'Female' : 'Male',
                  unit: '',
                  icon: r.gender == 1
                      ? Icons.female_rounded
                      : Icons.male_rounded,
                  color: c.primaryLight,
                  c: c,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: c.divider),
            const SizedBox(height: 14),

            // ── Lifestyle Row ────────────────────────────────
            Text(
              'Lifestyle Factors',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LifestylePill(
                  icon: Icons.smoking_rooms_rounded,
                  label: 'Smoker',
                  active: r.smoke == 1,
                  positiveWhenActive: false,
                  c: c,
                ),
                _LifestylePill(
                  icon: Icons.local_bar_rounded,
                  label: 'Alcohol',
                  active: r.alco == 1,
                  positiveWhenActive: false,
                  c: c,
                ),
                _LifestylePill(
                  icon: Icons.directions_run_rounded,
                  label: 'Active',
                  active: r.active == 1,
                  positiveWhenActive: true,
                  c: c,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: c.divider),
            const SizedBox(height: 12),

            // ── Advice ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: riskColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.advice,
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({double size = 48, double fontSize = 20}) {
    final avatarUrl = _profile?['avatar_url']?.toString();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(_avatarLetter,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700)),
                ),
              )
            : Center(
                child: Text(_avatarLetter,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: c.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ───────────────────────────────────────
              FadeInDown(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'Hello, $_displayName 👋',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary),
                        ),
                        Text('How is your heart today?',
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 13)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        final nav = context.findAncestorStateOfType<MainNavigatorState>();
                        nav?.setIndex(3); // Index 3 is ProfileScreen
                      },
                      child: _buildAvatar(size: 48, fontSize: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Streak banner ────────────────────────────────
              if (_streak > 0)
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: c.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_streak-day check streak!',
                                style: TextStyle(
                                    color: c.warning,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text('Keep it up — consistency saves lives.',
                                style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Quick Check CTA ──────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () {
                    final nav =
                        context.findAncestorStateOfType<MainNavigatorState>();
                    nav?.setIndex(1);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.monitor_heart_rounded,
                            color: Colors.white, size: 40),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Check Your Risk Now',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text(
                                  'Get instant AI-powered Cardiovascular Disease (CVD) prediction',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Stats + Chart ────────────────────────────────
              if (_history.isNotEmpty) ...[
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildStatsRow(c),
                ),
                const SizedBox(height: 16),
                if (_trendText.isNotEmpty)
                  FadeInUp(
                    delay: const Duration(milliseconds: 340),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _trendColor(c).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _trendColor(c).withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _history[0].probability <=
                                    _history[1].probability
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                            color: _trendColor(c),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(_trendText,
                              style: TextStyle(
                                  color: _trendColor(c),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildRiskChart(c, context),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 450),
                  child: const SectionHeader(
                      title: 'Latest Result',
                      subtitle: 'Your most recent prediction'),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _buildLatestCard(_history.first, c),
                ),
                const SizedBox(height: 24),
              ] else ...[
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: GlassCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.primary.withOpacity(0.1),
                            ),
                            child: Icon(Icons.favorite_rounded,
                                color: c.primary, size: 36),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('No predictions yet',
                            style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Check" below to run your first CVD risk assessment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Tip of the Day ───────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: const SectionHeader(
                    title: 'Tip of the Day',
                    subtitle: 'Your daily heart health reminder'),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 540),
                child: _buildFeaturedTip(_tipOfTheDay, c),
              ),
              const SizedBox(height: 24),

              // ── Health Tips ──────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 560),
                child: const SectionHeader(
                    title: 'Health Tips',
                    subtitle: 'Daily heart health advice'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tipsData.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) => FadeInRight(
                    delay: Duration(milliseconds: 80 * i),
                    child: _buildTipCard(_tipsData[i], c),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart with interactive tap ───────────────────────────────
  Widget _buildRiskChart(AppThemeColors c, BuildContext context) {
    final recent = _history.take(7).toList().reversed.toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                  title: 'Risk Trend', subtitle: 'Tap any dot for details'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'Last ${recent.length} checks',
                  style: TextStyle(
                      color: c.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Legend ───────────────────────────────────────────
          Row(
            children: [
              _LegendDot(color: c.success, label: 'Low'),
              const SizedBox(width: 12),
              _LegendDot(color: c.warning, label: 'Medium'),
              const SizedBox(width: 12),
              _LegendDot(color: c.danger, label: 'High'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => c.card,
                    tooltipBorder:
                        BorderSide(color: c.cardBorder),
                    tooltipRoundedRadius: 10,
                    getTooltipItems: (spots) => spots.map((s) {
                      final i = s.x.toInt();
                      if (i < 0 || i >= recent.length) return null;
                      final r = recent[i];
                      Color dotColor;
                      switch (r.riskLevel.toLowerCase()) {
                        case 'low':
                          dotColor = c.success;
                          break;
                        case 'medium':
                          dotColor = c.warning;
                          break;
                        default:
                          dotColor = c.danger;
                      }
                      return LineTooltipItem(
                        '${r.probability.toStringAsFixed(1)}%\n',
                        TextStyle(
                            color: dotColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                        children: [
                          TextSpan(
                            text: r.riskLevel,
                            style: TextStyle(
                                color: c.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? response) {
                    if (event is FlTapUpEvent &&
                        response?.lineBarSpots != null &&
                        response!.lineBarSpots!.isNotEmpty) {
                      final idx =
                          response.lineBarSpots!.first.x.toInt();
                      if (idx >= 0 && idx < recent.length) {
                        _showRecordDetail(context, recent[idx]);
                      }
                    }
                  },
                  handleBuiltInTouches: true,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: c.cardBorder, strokeWidth: 0.5),
                  getDrawingVerticalLine: (v) =>
                      FlLine(color: c.cardBorder.withOpacity(0.3), strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style: TextStyle(
                            color: c.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= recent.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d/M').format(recent[i].date),
                            style: TextStyle(
                                color: c.textMuted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      recent.length,
                      (i) =>
                          FlSpot(i.toDouble(), recent[i].probability),
                    ),
                    isCurved: true,
                    gradient: AppColors.primaryGradient,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          c.primary.withOpacity(0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, i) {
                        Color dotColor;
                        if (i < recent.length) {
                          switch (recent[i].riskLevel.toLowerCase()) {
                            case 'low':
                              dotColor = c.success;
                              break;
                            case 'medium':
                              dotColor = c.warning;
                              break;
                            default:
                              dotColor = c.danger;
                          }
                        } else {
                          dotColor = c.primary;
                        }
                        return FlDotCirclePainter(
                          radius: _touchedIndex == i ? 7 : 5,
                          color: dotColor,
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Tap hint ─────────────────────────────────────────
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded,
                    color: c.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Tap any data point to see full details',
                  style:
                      TextStyle(color: c.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Remaining builders ───────────────────────────────────────

  Widget _buildStatsRow(AppThemeColors c) {
    final total = _history.length;
    final highRisk = _history.where((r) => r.riskLevel == 'High').length;
    final avgProb =
        _history.map((r) => r.probability).reduce((a, b) => a + b) /
            _history.length;
    return Row(
      children: [
        _StatCard(
            label: 'Total',
            value: '$total',
            icon: Icons.analytics_rounded,
            color: c.primary),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Avg Risk',
            value: '${avgProb.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
            color: c.accent),
        const SizedBox(width: 12),
        _StatCard(
            label: 'High Risk',
            value: '$highRisk',
            icon: Icons.warning_rounded,
            color: c.danger),
      ],
    );
  }

  Widget _buildLatestCard(PredictionRecord r, AppThemeColors c) {
    Color riskColor;
    switch (r.riskLevel.toLowerCase()) {
      case 'low':
        riskColor = c.success;
        break;
      case 'medium':
        riskColor = c.warning;
        break;
      default:
        riskColor = c.danger;
    }
    return GlassCard(
      onTap: () => _showRecordDetail(context, r),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: riskColor.withOpacity(0.15),
              border: Border.all(
                color: riskColor.withOpacity(
                    r.riskLevel.toLowerCase() == 'high' ? 0.8 : 0.4),
                width: r.riskLevel.toLowerCase() == 'high' ? 3 : 2,
              ),
              boxShadow: r.riskLevel.toLowerCase() == 'high'
                  ? [
                      BoxShadow(
                          color: riskColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '${r.probability.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RiskBadge(riskLevel: r.riskLevel),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(r.date),
                      style:
                          TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.advice,
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text('Tap to see full details →',
                    style: TextStyle(
                        color: c.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTip(_HealthTipData tip, AppThemeColors c) {
    final color = _tipColor(tip, c);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(tip.icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(tip.desc,
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(_HealthTipData tip, AppThemeColors c) {
    final color = _tipColor(tip, c);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tip.icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(tip.title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(tip.desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: context.c.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final AppThemeColors c;
  const _DetailStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
          if (unit.isNotEmpty)
            Text(unit,
                style: TextStyle(color: c.textMuted, fontSize: 9),
                overflow: TextOverflow.ellipsis),
          Text(label,
              style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _LifestylePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool positiveWhenActive;
  final AppThemeColors c;
  const _LifestylePill({
    required this.icon,
    required this.label,
    required this.active,
    required this.positiveWhenActive,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = positiveWhenActive ? active : !active;
    final color = isGood ? c.success : c.danger;
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(color: c.textSecondary, fontSize: 11)),
        Text(active ? 'Yes' : 'No',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _HealthTipData {
  final IconData icon;
  final String title;
  final String desc;
  final String colorKey;
  const _HealthTipData(this.icon, this.title, this.desc, this.colorKey);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}