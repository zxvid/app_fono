import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/bienvenida_screen.dart';

void main() {
  runApp(const FonoSaludApp());
}

class FonoSaludApp extends StatelessWidget {
  const FonoSaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FonoSalud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BienvenidaScreen(),
    );
  }
}
