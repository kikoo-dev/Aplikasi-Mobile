import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../widgets/common.dart';
import '../../widgets/itenas_logo.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppScope.read(context).login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailCtrl.text.trim());
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFE3DFF2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Lupa Password',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan email kamu, kami akan mengirim tautan reset password.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF8B84AC),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'email@contoh.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Kirim Tautan',
                  icon: Icons.send_rounded,
                  onPressed: () async {
                    final value = controller.text.trim();
                    if (value.isEmpty || !value.contains('@')) {
                      showAppSnack(ctx, 'Email tidak valid', isError: true);
                      return;
                    }
                    try {
                      await AppScope.read(ctx).resetPassword(value);
                      if (ctx.mounted) Navigator.pop(ctx, value);
                    } catch (e) {
                      if (ctx.mounted) {
                        showAppSnack(ctx, e.toString(), isError: true);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (email != null && mounted) {
      showAppSnack(
        context,
        'Tautan reset dikirim ke $email (cek inbox/spam).',
      );
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = AppScope.of(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Center(child: ItenasLogo(size: 82)),
                    const SizedBox(height: 22),
                    Text(
                      'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: isDark ? Colors.white : const Color(0xFF1B1436),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk ke akun ITENAS untuk mengelola profil & memakai kalkulator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF8B84AC),
                      ),
                    ),
                    const SizedBox(height: 26),

                    if (controller.isDemo) ...[
                      _DemoBanner(),
                      const SizedBox(height: 18),
                    ],

                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LabeledField(
                              label: 'Email',
                              required: true,
                              child: TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  hintText: 'email@contoh.com',
                                  prefixIcon: Icon(
                                    Icons.mail_outline_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  final ok = RegExp(
                                    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
                                  ).hasMatch(value);
                                  return ok ? null : 'Format email tidak valid';
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            LabeledField(
                              label: 'Password',
                              required: true,
                              child: TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? '').isEmpty) {
                                    return 'Password wajib diisi';
                                  }
                                  if (v!.length < 6) {
                                    return 'Minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Lupa password?',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              _ErrorBox(message: _error!),
                              const SizedBox(height: 14),
                            ],
                            GradientButton(
                              label: 'Masuk',
                              icon: Icons.login_rounded,
                              loading: _loading,
                              onPressed: _loading ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF8B84AC),
                          ),
                        ),
                        GestureDetector(
                          onTap: _openRegister,
                          child: Text(
                            'Daftar sekarang',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFF9B87FF)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.science_outlined,
            size: 19,
            color: Color(0xFF128A6C),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode demo aktif (Supabase belum diset). Data disimpan lokal. '
              'Isi Env.supabaseUrl & Env.supabaseAnonKey untuk memakai database.',
              style: TextStyle(
                fontSize: 11.8,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF7FE9C9)
                    : const Color(0xFF0E6B53),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE5484D).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFE5484D),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFFD93A3F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Utility untuk memaksa keyboard numerik tanpa import tambahan di layar lain.
const numericKeyboard = TextInputType.number;
