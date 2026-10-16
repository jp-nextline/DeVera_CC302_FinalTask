import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_themes.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'services/app_state.dart';
import 'services/image_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImageService.init();
  final state = AppState();
  await state.init();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const BrainHumorApp()),
  );
}

class BrainHumorApp extends StatelessWidget {
  const BrainHumorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedTheme = AppThemes.byId(state.themeId);
    return MaterialApp(
      title: 'Brain Humor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(selectedTheme.palette, selectedTheme.brightness),
      // Swaps automatically when the user logs in / out.
      home: state.isLoggedIn ? const MainShell() : const AuthScreen(),
    );
  }
}
