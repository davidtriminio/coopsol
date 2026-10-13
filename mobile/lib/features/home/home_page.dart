import 'package:coopsol_mobile/core/auth/auth_models.dart';
import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.authService});

  final AuthUser user;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoopSol'),
        actions: [
          TextButton(
            key: const Key('home-logout'),
            onPressed: authService.logout,
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hola, ${user.fullName}',
                key: const Key('home-greeting'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(user.email, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
