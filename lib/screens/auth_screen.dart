import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/brand.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      if (_isLogin) {
        await supabase.auth
            .signInWithPassword(email: email, password: _password.text);
      } else {
        final res = await supabase.auth.signUp(
          email: email,
          password: _password.text,
          data: {'name': _name.text.trim(), 'phone': _phone.text.trim()},
        );
        if (res.session == null) {
          _snack('Account created. Confirm your email, then log in.');
          if (mounted) setState(() => _isLogin = true);
        }
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Something went wrong. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 36, 24, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandAlt],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white.withAlpha(25)),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white.withAlpha(20)),
            ),
          ),
          Column(
            children: [
              const BrandMark(size: 76, inverted: true),
              const SizedBox(height: 16),
              Text('LostLink',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Find what you lost.\nReturn what you found.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white.withAlpha(220))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isLogin ? 'Welcome back' : 'Create your account',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: Column(children: [
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: fieldDeco(context,
                                label: 'Full name', icon: Icons.person_outline),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: fieldDeco(context,
                                label: 'Phone (optional)',
                                icon: Icons.phone_outlined),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ]),
                    ),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: fieldDeco(context,
                          label: 'Email', icon: Icons.mail_outline),
                      validator: (v) {
                        final e = (v ?? '').trim();
                        if (!e.contains('@')) return 'Enter a valid email';
                        final d = AppConfig.allowedEmailDomain;
                        if (!_isLogin && d.isNotEmpty && !e.endsWith('@$d')) {
                          return 'Use your college email (@$d)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      decoration: fieldDeco(
                        context,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'At least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white))
                            : Text(_isLogin ? 'Log in' : 'Create account',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin
                            ? 'New here? Create an account'
                            : 'Already have an account? Log in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
