import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'core/env.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_controller.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(
      service: createAuthService(useSupabase: Env.isSupabaseConfigured),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'ProfilKita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
