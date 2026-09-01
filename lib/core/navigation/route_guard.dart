import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class RouteGuard extends StatelessWidget {
  const RouteGuard({
    super.key,
    required this.child,
    this.requiresAdmin = false,
  });

  final Widget child;
  final bool requiresAdmin;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!authProvider.isLoggedIn) {
      final target = requiresAdmin
          ? AppRoutes.adminLogin
          : AppRoutes.login;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            target,
            (route) => false,
          );
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (requiresAdmin && !authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return child;
  }
}