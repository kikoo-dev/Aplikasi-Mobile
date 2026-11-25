import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../widgets/common.dart';
import '../../widgets/itenas_logo.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agree = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int get _strength {
    final p = _passCtrl.text;
    var score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(0, 5);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Kamu harus menyetujui syarat & ketentuan.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppScope.read(context).register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      showAppSnack(context, 'Akun berhasil dibuat. Selamat bergabung! 🎉');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: 'Buat Akun',
                      subtitle: 'Isi data dasar untuk memulai',
                    ),
                    const SizedBox(height: 18),
                    const Center(child: ItenasLogo(size: 76)),
                    const SizedBox(height: 18),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LabeledField(
                              label: 'Nama Lengkap',
                              required: true,
                              child: TextFormField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Budi Santoso',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) {
                                    return 'Nama wajib diisi';
                                  }
                                  if (value.length < 3) {
                                    return 'Nama minimal 3 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            LabeledField(
                              label: 'Username',
                              required: true,
                              child: TextFormField(
                                controller: _usernameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'budisantoso',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) {
                                    return 'Username wajib diisi';
                                  }
                                  if (value.length < 3) {
                                    return 'Username minimal 3 karakter';
                                  }
                                  final ok = RegExp(
                                    r'^[a-zA-Z0-9._]+$',
                                  ).hasMatch(value);
                                  return ok
                                      ? null
                                      : 'Hanya huruf, angka, titik & underscore';
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            LabeledField(
                              label: 'Email',
                              required: true,
                              child: TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
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
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Minimal 6 karakter',
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
                            if (_passCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _StrengthBar(score: _strength),
                            ],
                            const SizedBox(height: 16),
                            LabeledField(
                              label: 'Konfirmasi Password',
                              required: true,
                              child: TextFormField(
                                controller: _confirmCtrl,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: 'Ulangi password',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? '').isEmpty) {
                                    return 'Konfirmasi password wajib diisi';
                                  }
                                  if (v != _passCtrl.text) {
                                    return 'Password tidak sama';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agree,
                                    onChanged: (v) =>
                                        setState(() => _agree = v ?? false),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Saya setuju dengan Syarat & Ketentuan serta Kebijakan Privasi.',
                                    style: TextStyle(
                                      fontSize: 11.8,
                                      height: 1.4,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF6B6488),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              _RegisterError(message: _error!),
                            ],
                            const SizedBox(height: 18),
                            GradientButton(
                              label: 'Daftar Sekarang',
                              icon: Icons.person_add_alt_1_rounded,
                              loading: _loading,
                              onPressed: _loading ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF8B84AC),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Masuk',
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

class _StrengthBar extends StatelessWidget {
  final int score;

  const _StrengthBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final labels = ['Sangat lemah', 'Lemah', 'Cukup', 'Kuat', 'Sangat kuat'];
    final colors = [
      const Color(0xFFE5484D),
      const Color(0xFFFF9F43),
      const Color(0xFFFFD93D),
      const Color(0xFF25D0A6),
      const Color(0xFF0FA97F),
    ];
    final index = (score - 1).clamp(0, 4);
    final color = score == 0 ? const Color(0xFFC9C4DC) : colors[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 4.5,
                margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                decoration: BoxDecoration(
                  color: i < score
                      ? color
                      : color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          score == 0 ? 'Masukkan password' : labels[index],
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RegisterError extends StatelessWidget {
  final String message;

  const _RegisterError({required this.message});

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
