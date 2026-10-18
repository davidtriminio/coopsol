import 'package:coopsol_mobile/core/app_dependencies.dart';
import 'package:coopsol_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'features/session/session_gate.dart';

class CoopSolApp extends StatelessWidget {
  const CoopSolApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoopSol',
      debugShowCheckedModeBanner: false,
      theme:AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: SessionGate(
        sessionController: dependencies.sessionController,
        authService: dependencies.authService,
      ),
    );
  }
}
