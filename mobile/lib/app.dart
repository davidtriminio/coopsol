import 'package:coopsol_mobile/core/app_dependencies.dart';
import 'package:flutter/material.dart';

import 'features/session/session_gate.dart';

class CoopSolApp extends StatelessWidget {
  const CoopSolApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  static const Color _seedColor = Color(0xFF0F3A3D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoopSol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: SessionGate(
        sessionController: dependencies.sessionController,
        authService: dependencies.authService,
      ),
    );
  }
}
