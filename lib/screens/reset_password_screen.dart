import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/supabase_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  bool _passVisible = false;

  final List<Map<String, dynamic>> _requirements = [
    {'regex': RegExp(r'.{8,}'), 'text': 'At least 8 characters'},
    {'regex': RegExp(r'[A-Z]'), 'text': 'At least one uppercase letter'},
    {'regex': RegExp(r'[a-z]'), 'text': 'At least one lowercase letter'},
    {'regex': RegExp(r'[0-9]'), 'text': 'At least one number'},
  ];

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check dynamic requirements before proceeding
    bool allReqsMet = _requirements.every((req) => (req['regex'] as RegExp).hasMatch(_newPassCtrl.text));
    if (!allReqsMet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please meet all password requirements'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    final error = await SupabaseAuthService.updatePassword(_newPassCtrl.text);
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      // Kick them back to the Auth screen to log in with the new password
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: Text(
                    'Create New\nPassword',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  child: Text(
                    'Your new password must be different from previously used passwords.',
                    style: TextStyle(color: c.textSecondary, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: AppTextField(
                    label: 'New Password',
                    controller: _newPassCtrl,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_passVisible,
                    onChanged: (v) {
                      setState(() {}); // Trigger rebuild for checklist
                    },
                    suffix: IconButton(
                      icon: Icon(
                        _passVisible ? Icons.visibility_off : Icons.visibility,
                        color: c.textMuted,
                      ),
                      onPressed: () => setState(() => _passVisible = !_passVisible),
                    ),
                  ),
                ),
                
                // Password Requirements Checklist
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: Column(
                    children: _requirements.map((req) {
                      final isMet = (req['regex'] as RegExp).hasMatch(_newPassCtrl.text);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isMet ? Colors.green : c.textMuted.withOpacity(0.5),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              req['text'],
                              style: TextStyle(
                                color: isMet ? Colors.green : c.textSecondary,
                                fontSize: 14,
                                fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: AppTextField(
                    label: 'Confirm New Password',
                    controller: _confirmPassCtrl,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) => v != _newPassCtrl.text ? 'Passwords do not match' : null,
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: GradientButton(
                    text: 'Update Password',
                    onPressed: _updatePassword,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}