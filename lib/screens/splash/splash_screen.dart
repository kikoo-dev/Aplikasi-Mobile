import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../../widgets/itenas_logo.dart';

/// Splash screen dengan animasi logo + pengecekan sesi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _anim.forward();
    _boot();
  }

  Future<void> _boot() async {
    final controller = AppScope.read(context);

    // Minimal tampil 2 detik agar animasi splash terlihat.
    final results = await Future.wait<dynamic>([
      controller.bootstrap(),
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);
    if (!mounted) return;
    // ignore: unnecessary_statements
    results;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => controller.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Lingkaran dekoratif
            Positioned(
              top: -120,
              right: -90,
              child: _ring(260, Colors.white.withValues(alpha: 0.07)),
            ),
            Positioned(
              bottom: -140,
              left: -110,
              child: _ring(320, Colors.white.withValues(alpha: 0.05)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: const ItenasLogo(size: 118),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _slide,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: Opacity(
                        opacity: _fade.value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ITENAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Institut Teknologi Nasional Bandung',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profil • Biodata • Kalkulator',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: AnimatedBuilder(
                animation: _fade,
                builder: (context, child) => Opacity(
                  opacity: _fade.value.clamp(0.0, 1.0),
                  child: child,
                ),
                child: Column(
                  children: [
                    Text(
                      'Institut Teknologi Nasional Bandung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w600,
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

  Widget _ring(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 34),
      ),
    );
  }
}
