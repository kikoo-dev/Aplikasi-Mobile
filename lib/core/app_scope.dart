import 'package:flutter/material.dart';

import '../services/auth_controller.dart';

/// InheritedNotifier sederhana untuk mengakses [AuthController]
/// dari mana saja tanpa dependency tambahan.
class AppScope extends InheritedNotifier<AuthController> {
  const AppScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree.');
    return scope!.notifier!;
  }

  /// Akses tanpa rebuild (untuk memanggil aksi).
  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree.');
    return scope!.notifier!;
  }
}
