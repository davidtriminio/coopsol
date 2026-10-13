import 'package:coopsol_mobile/core/app_dependencies.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = AppDependencies.create();
  dependencies.sessionController.restore();

  runApp(CoopSolApp(dependencies: dependencies));
}
