import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Positioned(
      top: 60,
      right: 16,
      child: GestureDetector(
        onTap: () => context.read<ThemeProvider>().toggle(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.toggleBg,
            shape: BoxShape.circle,
            border: Border.all(color: theme.border),
          ),
          child: Icon(
            theme.isDark ? Icons.light_mode : Icons.dark_mode,
            color: theme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}