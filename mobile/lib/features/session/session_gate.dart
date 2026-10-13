import 'package:coopsol_mobile/core/auth/auth_service.dart';
import 'package:coopsol_mobile/core/auth/session_controller.dart';
import 'package:coopsol_mobile/features/login/login_page.dart';
import 'package:flutter/material.dart';

import '../home/home_page.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({
    super.key,
    required this.sessionController,
    required this.authService,
  });

  final SessionController sessionController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessionController,
      builder: (context, _) {
        switch (sessionController.status) {
          case SessionStatus.restoring:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case SessionStatus.unauthenticated:
            return LoginPage(authService: authService);
          case SessionStatus.authenticated:
            return HomePage(
              user: sessionController.currentUser!,
              authService: authService,
            );
        }
      },
    );
  }
}
