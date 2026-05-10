import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../main.dart';
import 'result_screen.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({super.key});

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  int _gender = 2;
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _apHiCtrl = TextEditingController();
  final _apLoCtrl = TextEditingController();
  int _cholesterol = 1;
  int _gluc = 1;
  bool _smoke = false;
  bool _alco = false;
  bool _active = true;
  double? _bmi;

  void _calcBMI() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h != null && w != null && h > 0) {
      setState(() => _bmi = w / ((h / 100) * (h / 100)));
    }
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final c = context.c;
    final result = await ApiService.predict(
      gender: _gender,
      ageYears: int.parse(_ageCtrl.text),
      height: int.parse(_heightCtrl.text),
      weight: double.parse(_weightCtrl.text),
      apHi: int.parse(_apHiCtrl.text),
      apLo: int.parse(_apLoCtrl.text),
      cholesterol: _cholesterol,
      gluc: _gluc,
      smoke: _smoke ? 1 : 0,
      alco: _alco ? 1 : 0,
      active: _active ? 1 : 0,
    );

    setState(() => _isLoading = false);

    if (result == null || result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result?['error'] ?? 'Connection failed. Check server.'),
          backgroundColor: c.danger, // ✅ theme-aware
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final record = PredictionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        gender: _gender,
        ageYears: int.parse(_ageCtrl.text),
        height: int.parse(_heightCtrl.text),
        weight: double.parse(_weightCtrl.text),
        apHi: int.parse(_apHiCtrl.text),
        apLo: int.parse(_apLoCtrl.text),
        cholesterol: _cholesterol,
        gluc: _gluc,
        smoke: _smoke ? 1 : 0,
        alco: _alco ? 1 : 0,
        active: _active ? 1 : 0,
        prediction: result['prediction'] == 1,
        probability: (result['probability'] as num).toDouble(),
        riskLevel: result['risk_level'],
        advice: result['advice'],
        bmi: (result['bmi'] as num).toDouble(),
        bmiCategory: result['bmi_category'],
      );

      await SupabaseHistoryService.savePrediction({
        'gender': record.gender,
        'age_years': record.ageYears,
        'height': record.height,
        'weight': record.weight,
        'ap_hi': record.apHi,
        'ap_lo': record.apLo,
        'cholesterol': record.cholesterol,
        'gluc': record.gluc,
        'smoke': record.smoke,
        'alco': record.alco,
        'active': record.active,
        'prediction': record.prediction,
        'probability': record.probability,
        'risk_level': record.riskLevel,
        'advice': record.advice,
        'bmi': record.bmi,
        'bmi_category': record.bmiCategory,
      });

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
        );
        if (mounted) {
          final nav =
              context.findAncestorStateOfType<MainNavigatorState>();
          nav?.setIndex(2);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: const SectionHeader(
                  title: 'CVD Risk Check',
                  subtitle:
                      'Fill in your health details to assess your Cardiovascular Disease (CVD) risk',
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal Info ─────────────────────────────────
              _SectionTitle(title: '👤 Personal Information', index: 0),
              const SizedBox(height: 14),
              _GenderSelector(
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Age (years)',
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake_rounded,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 120)
                      ? 'Enter valid age'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    label: 'Height (cm)',
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.height_rounded,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 50 || n > 250)
                          ? 'Invalid height'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTextField(
                    label: 'Weight (kg)',
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefixIcon: Icons.monitor_weight_rounded,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n < 10 || n > 300)
                          ? 'Invalid weight'
                          : null;
                    },
                  ),
                ),
              ]),

              // ── BMI calculator ────────────────────────────────
              if (_heightCtrl.text.isNotEmpty &&
                  _weightCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap: _calcBMI,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        // ✅ theme-aware
                        color: c.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: c.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calculate_rounded,
                              color: c.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _bmi != null
                                ? 'BMI: ${_bmi!.toStringAsFixed(1)}'
                                : 'Tap to calculate BMI',
                            style: TextStyle(
                                color: c.primary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Blood Pressure ────────────────────────────────
              _SectionTitle(title: '🩺 Blood Pressure', index: 1),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    label: 'Systolic (ap_hi)',
                    controller: _apHiCtrl,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 120',
                    prefixIcon: Icons.arrow_upward_rounded,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 50 || n > 250)
                          ? 'Invalid'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTextField(
                    label: 'Diastolic (ap_lo)',
                    controller: _apLoCtrl,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 80',
                    prefixIcon: Icons.arrow_downward_rounded,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 30 || n > 200)
                          ? 'Invalid'
                          : null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // ✅ theme-aware hint text
              Text(
                'Normal: Systolic < 120, Diastolic < 80',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),

              const SizedBox(height: 24),

              // ── Lab Values ────────────────────────────────────
              _SectionTitle(title: '🧪 Lab Values', index: 2),
              const SizedBox(height: 14),
              _LevelSelector(
                label: 'Cholesterol',
                value: _cholesterol,
                onChanged: (v) => setState(() => _cholesterol = v),
                options: const [
                  'Normal',
                  'Above Normal',
                  'Well Above Normal'
                ],
              ),
              const SizedBox(height: 14),
              _LevelSelector(
                label: 'Glucose',
                value: _gluc,
                onChanged: (v) => setState(() => _gluc = v),
                options: const [
                  'Normal',
                  'Above Normal',
                  'Well Above Normal'
                ],
              ),

              const SizedBox(height: 24),

              // ── Lifestyle ─────────────────────────────────────
              _SectionTitle(title: '🏃 Lifestyle', index: 3),
              const SizedBox(height: 14),
              _ToggleRow(
                label: 'Smoker',
                icon: Icons.smoking_rooms_rounded,
                value: _smoke,
                onChanged: (v) => setState(() => _smoke = v),
                activeColor: AppColors.danger,
              ),
              const SizedBox(height: 10),
              _ToggleRow(
                label: 'Alcohol Consumption',
                icon: Icons.local_bar_rounded,
                value: _alco,
                onChanged: (v) => setState(() => _alco = v),
                activeColor: AppColors.warning,
              ),
              const SizedBox(height: 10),
              _ToggleRow(
                label: 'Physically Active',
                icon: Icons.directions_run_rounded,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeColor: AppColors.success,
              ),

              const SizedBox(height: 32),
              GradientButton(
                text: 'Predict My CVD Risk',
                onPressed: () {
                  _calcBMI();
                  _predict();
                },
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int index;
  const _SectionTitle({required this.title, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: Text(
        title,
        style: TextStyle(
            // ✅ theme-aware
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────
// GENDER SELECTOR
// ─────────────────────────────────────────

class _GenderSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _GenderSelector(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      _GenderChip(
        label: 'Female',
        icon: Icons.female_rounded,
        selected: value == 1,
        color: c.accent,
        onTap: () => onChanged(1),
      ),
      const SizedBox(width: 12),
      _GenderChip(
        label: 'Male',
        icon: Icons.male_rounded,
        selected: value == 2,
        color: c.primary,
        onTap: () => onChanged(2),
      ),
    ]);
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            // ✅ selected: color tint, unselected: theme surface
            color: selected
                ? color.withOpacity(0.15)
                : c.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : c.cardBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  // ✅ theme-aware icon color
                  color: selected ? color : c.textMuted,
                  size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : c.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// LEVEL SELECTOR (Cholesterol / Glucose)
// ─────────────────────────────────────────

class _LevelSelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final List<String> options;

  const _LevelSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colors = [c.success, c.warning, c.danger];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            // ✅ theme-aware label
            color: c.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (i) {
            final selected = value == i + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    // ✅ unselected uses theme surfaceLight — no more dark bg
                    color: selected
                        ? colors[i].withOpacity(0.15)
                        : c.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? colors[i] : c.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // ✅ unselected text visible in both themes
                      color: selected ? colors[i] : c.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// TOGGLE ROW (Smoke / Alco / Active)
// ─────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // ✅ active: color tint, inactive: theme surfaceLight
        color: value
            ? activeColor.withOpacity(0.1)
            : c.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? activeColor.withOpacity(0.4)
              : c.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            // ✅ theme-aware icon
            color: value ? activeColor : c.textMuted,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                // ✅ theme-aware label text
                color: value ? c.textPrimary : c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}