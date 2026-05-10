import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../main.dart'; // for themeNotifier

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<PredictionRecord> _history = [];
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  StreamSubscription? _profileSub;

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _subscribeToProfile();
    _loadHistory();
    // ✅ Rebuild when theme toggles
    themeNotifier.addListener(_onThemeChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    _profileSub?.cancel();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────
  // PROFILE STREAM
  // ─────────────────────────────────────────

  void _subscribeToProfile() {
    _profileSub?.cancel();
    _profileSub = SupabaseAuthService.profileStream().listen((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          if (!_isEditing) {
            _nameCtrl.text = profile?['name'] ?? '';
            _ageCtrl.text = profile?['age']?.toString() ?? '';
            _heightCtrl.text = profile?['height']?.toString() ?? '';
            _weightCtrl.text = profile?['weight']?.toString() ?? '';
            _selectedGender = profile?['gender'];
          }
        });
      }
    });
  }

  // ─────────────────────────────────────────
  // HISTORY
  // ─────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final historyData = await SupabaseHistoryService.getHistory();
      final records = historyData.map((e) => PredictionRecord(
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
          )).toList();
      if (mounted) setState(() => _history = records);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────
  // SAVE PROFILE
  // ─────────────────────────────────────────

  Future<void> _saveProfile() async {
    final c = context.c;
    final error = await SupabaseAuthService.updateProfile(
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text),
      gender: _selectedGender,
      height: double.tryParse(_heightCtrl.text),
      weight: double.tryParse(_weightCtrl.text),
    );

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $error'),
          backgroundColor: c.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated!'),
        backgroundColor: c.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─────────────────────────────────────────
  // AVATAR
  // ─────────────────────────────────────────

  void _showAvatarOptions() {
    final c = context.c;
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Profile Photo',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _BottomSheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              color: c.primary,
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) await _uploadAvatar(File(image.path));
              },
            ),
            const SizedBox(height: 8),
            _BottomSheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              color: c.primary,
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) await _uploadAvatar(File(image.path));
              },
            ),
            if (_profile?['avatar_url'] != null) ...[
              const SizedBox(height: 8),
              _BottomSheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                color: c.danger,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _removeAvatar();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(File file) async {
    final c = context.c;
    setState(() => _isUploadingAvatar = true);
    final url = await SupabaseAuthService.uploadAvatar(file);
    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            url != null ? 'Photo updated!' : 'Upload failed. Try again.'),
        backgroundColor: url != null ? c.success : c.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _removeAvatar() async {
    final c = context.c;
    setState(() => _isUploadingAvatar = true);
    final error = await SupabaseAuthService.removeAvatar();
    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            error == null ? 'Photo removed!' : 'Failed to remove: $error'),
        backgroundColor: error == null ? c.success : c.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────

  void _logout() {
    final c = context.c;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: TextStyle(color: c.textPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseAuthService.logout();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
            child: Text('Sign Out', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  String get _displayName {
    final name = _profile?['name']?.toString() ?? '';
    return name.isNotEmpty ? name : 'User';
  }

  String get _avatarLetter {
    final name = _profile?['name']?.toString() ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.c; // ✅ all colors from theme extension
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final totalChecks = _history.length;
    final highRisk = _history.where((r) => r.riskLevel == 'High').length;
    final avgProb = _history.isEmpty
        ? 0.0
        : _history.map((r) => r.probability).reduce((a, b) => a + b) /
            _history.length;

    return SafeArea(
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: c.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Header ───────────────────────────────────────
                  FadeInDown(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: 'My Profile'),
                        if (!_isEditing)
                          GestureDetector(
                            onTap: () => setState(() => _isEditing = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: c.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: c.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded,
                                      color: c.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Edit',
                                      style: TextStyle(
                                          color: c.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _saveProfile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Save',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Avatar ───────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarOptions,
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _isUploadingAvatar
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : _profile?['avatar_url'] != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  _profile!['avatar_url'],
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Center(
                                                child: Text(
                                                  _avatarLetter,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 36,
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                _avatarLetter,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _displayName,
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(email,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Stats ────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Row(
                      children: [
                        _ProfileStat('Total Checks', '$totalChecks', c.primary),
                        const SizedBox(width: 12),
                        _ProfileStat('Avg Risk',
                            '${avgProb.toStringAsFixed(1)}%', c.accent),
                        const SizedBox(width: 12),
                        _ProfileStat('High Risk', '$highRisk', c.danger),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Edit form or info display ─────────────────────
                  if (_isEditing) ...[
                    FadeInUp(
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Edit Profile'),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Full Name',
                              controller: _nameCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              label: 'Age',
                              controller: _ageCtrl,
                              prefixIcon: Icons.cake_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Height (cm)',
                                  controller: _heightCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.height_rounded,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: AppTextField(
                                  label: 'Weight (kg)',
                                  controller: _weightCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.monitor_weight_rounded,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            Text('Gender',
                                style: TextStyle(
                                    color: c.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: ['Female', 'Male'].map((g) {
                                final selected = _selectedGender == g;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedGender = g),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      margin: EdgeInsets.only(
                                          right: g == 'Female' ? 8 : 0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? c.primary.withOpacity(0.2)
                                            : c.surfaceLight,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? c.primary
                                              : c.cardBorder,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(g,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: selected
                                                ? c.primary
                                                : c.textMuted,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        side: BorderSide(color: c.cardBorder),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ] else ...[
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      child: GlassCard(
                        child: Column(
                          children: [
                            _InfoRow(Icons.person_rounded, 'Gender',
                                _profile?['gender'] ?? 'Not set'),
                            Divider(color: c.divider),
                            _InfoRow(
                                Icons.cake_rounded,
                                'Age',
                                _profile?['age'] != null
                                    ? '${_profile!['age']} years'
                                    : 'Not set'),
                            Divider(color: c.divider),
                            _InfoRow(
                                Icons.height_rounded,
                                'Height',
                                _profile?['height'] != null
                                    ? '${_profile!['height']} cm'
                                    : 'Not set'),
                            Divider(color: c.divider),
                            _InfoRow(
                                Icons.monitor_weight_rounded,
                                'Weight',
                                _profile?['weight'] != null
                                    ? '${_profile!['weight']} kg'
                                    : 'Not set'),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Theme Toggle ──────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 450),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            themeNotifier.isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: c.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              themeNotifier.isDark
                                  ? 'Dark Mode'
                                  : 'Light Mode',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          // ✅ Animated theme switch
                          Switch(
                            value: themeNotifier.isDark,
                            onChanged: (_) => themeNotifier.toggleTheme(),
                            activeColor: c.primary,
                            inactiveThumbColor: c.textMuted,
                            inactiveTrackColor: c.cardBorder,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Sign Out ─────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: GestureDetector(
                      onTap: _logout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: c.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: c.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: c.danger, size: 20),
                            const SizedBox(width: 10),
                            Text('Sign Out',
                                style: TextStyle(
                                    color: c.danger,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ProfileStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: c.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: c.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: c.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}