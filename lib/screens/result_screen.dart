import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class ResultScreen extends StatefulWidget {
  final PredictionRecord record;
  const ResultScreen({super.key, required this.record});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _gaugeAnimation =
        Tween<double>(begin: 0, end: widget.record.probability / 100)
            .animate(CurvedAnimation(
                parent: _gaugeController, curve: Curves.easeOutCubic));
    _gaugeController.forward();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  // ── Dynamic risk color (uses context.c) ───────────────
  Color _riskColor(BuildContext context) {
    switch (widget.record.riskLevel.toLowerCase()) {
      case 'low':    return context.c.success;
      case 'medium': return context.c.warning;
      default:       return context.c.danger;
    }
  }

  LinearGradient get _riskGradient {
    switch (widget.record.riskLevel.toLowerCase()) {
      case 'low':    return AppColors.lowRiskGradient;
      case 'medium': return AppColors.mediumRiskGradient;
      default:       return AppColors.highRiskGradient;
    }
  }

  IconData get _riskIcon {
    switch (widget.record.riskLevel.toLowerCase()) {
      case 'low':    return Icons.check_circle_rounded;
      case 'medium': return Icons.warning_rounded;
      default:       return Icons.dangerous_rounded;
    }
  }

  Color _bmiColor(BuildContext context, double bmi) {
    if (bmi < 18.5) return context.c.accentTeal;
    if (bmi < 25)   return context.c.success;
    if (bmi < 30)   return context.c.warning;
    return context.c.danger;
  }

  Color _levelColor(BuildContext context, int level) {
    if (level == 1) return context.c.success;
    if (level == 2) return context.c.warning;
    return context.c.danger;
  }

  String _levelLabel(int level) {
    if (level == 1) return 'Normal';
    if (level == 2) return 'High';
    return 'Very High';
  }

  List<String> _getRecommendations(PredictionRecord r) {
    final recs = <String>[];
    if (r.smoke == 1)
      recs.add('Quitting smoking can halve your Cardiovascular Disease (CVD) risk within a year.');
    if (r.alco == 1)
      recs.add('Reducing alcohol intake lowers blood pressure and reduces heart strain.');
    if (r.active == 0)
      recs.add('Aim for at least 150 minutes of moderate exercise per week to protect heart health.');
    if (r.cholesterol > 1)
      recs.add('Adopt a low-fat diet rich in fruits and vegetables to manage cholesterol levels.');
    if (r.gluc > 1)
      recs.add('Monitor blood sugar regularly — high glucose is a known CVD risk factor.');
    if (r.apHi > 130 || r.apLo > 85)
      recs.add('Your blood pressure is elevated. High BP is a leading cause of heart disease — consult a doctor.');
    if (r.bmi >= 25)
      recs.add('Maintaining a healthy weight significantly reduces your Cardiovascular Disease risk.');
    if (recs.isEmpty)
      recs.add('Excellent! Keep up your healthy lifestyle — your heart is in good shape.');
    return recs;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = widget.record;
    final riskColor = _riskColor(context);

    return Scaffold(
      backgroundColor: c.background,
      body: Container(
        decoration: BoxDecoration(gradient: c.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── App Bar ──────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.cardBorder),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: c.textPrimary, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Your Results',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d').format(r.date),
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Animated Risk Gauge ──────────────────────
                FadeInDown(
                  child: AnimatedBuilder(
                    animation: _gaugeAnimation,
                    builder: (_, __) => CircularPercentIndicator(
                      radius: 110,
                      lineWidth: 16,
                      percent: _gaugeAnimation.value,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${r.probability.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: riskColor,
                            ),
                          ),
                          Text(
                            'Risk',
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          RiskBadge(riskLevel: r.riskLevel),
                        ],
                      ),
                      progressColor: riskColor,
                      backgroundColor: c.surfaceLight,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: false,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Risk Advice Card ─────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: _riskGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: riskColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(_riskIcon, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.riskLevel} Cardiovascular Risk',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.advice,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Health Metrics ───────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: const SectionHeader(title: 'Health Metrics'),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 450),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _MetricCard(
                        icon: Icons.monitor_weight_rounded,
                        label: 'BMI',
                        value: r.bmi.toStringAsFixed(1),
                        subtitle: r.bmiCategory,
                        color: _bmiColor(context, r.bmi),
                        textMuted: c.textMuted,
                      ),
                      _MetricCard(
                        icon: Icons.favorite_rounded,
                        label: 'Blood Pressure',
                        value: '${r.apHi}/${r.apLo}',
                        subtitle: 'mmHg',
                        color: c.accent,
                        textMuted: c.textMuted,
                      ),
                      _MetricCard(
                        icon: Icons.bloodtype_rounded,
                        label: 'Cholesterol',
                        value: _levelLabel(r.cholesterol),
                        subtitle: 'Level',
                        color: _levelColor(context, r.cholesterol),
                        textMuted: c.textMuted,
                      ),
                      _MetricCard(
                        icon: Icons.water_drop_rounded,
                        label: 'Glucose',
                        value: _levelLabel(r.gluc),
                        subtitle: 'Level',
                        color: _levelColor(context, r.gluc),
                        textMuted: c.textMuted,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Lifestyle Profile ────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Lifestyle Profile'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _LifestyleChip(
                              icon: Icons.smoking_rooms_rounded,
                              label: 'Smoker',
                              value: r.smoke == 1 ? 'Yes' : 'No',
                              active: r.smoke == 1,
                              positiveWhenActive: false,
                              textSecondary: c.textSecondary,
                            ),
                            _LifestyleChip(
                              icon: Icons.local_bar_rounded,
                              label: 'Alcohol',
                              value: r.alco == 1 ? 'Yes' : 'No',
                              active: r.alco == 1,
                              positiveWhenActive: false,
                              textSecondary: c.textSecondary,
                            ),
                            _LifestyleChip(
                              icon: Icons.directions_run_rounded,
                              label: 'Active',
                              value: r.active == 1 ? 'Yes' : 'No',
                              active: r.active == 1,
                              positiveWhenActive: true,
                              textSecondary: c.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Recommendations ──────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 550),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: '💡 Recommendations',
                          subtitle: 'Personalised advice based on your results',
                        ),
                        const SizedBox(height: 16),
                        ..._getRecommendations(r).map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.primary.withOpacity(0.15),
                                  ),
                                  child: Icon(Icons.arrow_right_rounded,
                                      color: c.primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: TextStyle(
                                        color: c.textSecondary,
                                        fontSize: 13,
                                        height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── CVD Info Banner ──────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 580),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: c.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cardiovascular Disease (CVD) refers to conditions affecting the heart and blood vessels, including coronary artery disease, stroke, and high blood pressure. Early detection saves lives.',
                            style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Action Buttons ───────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.refresh_rounded, color: c.primary),
                          label: Text('Check Again',
                              style: TextStyle(color: c.primary)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.primary,
                            side: BorderSide(color: c.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GradientButton(
                          text: 'View History',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color textMuted;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Lifestyle Chip ────────────────────────────────────────────
class _LifestyleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool active;
  final bool positiveWhenActive;
  final Color textSecondary;

  const _LifestyleChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
    required this.positiveWhenActive,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = positiveWhenActive ? active : !active;
    final color = isGood ? context.c.success : context.c.danger;

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}