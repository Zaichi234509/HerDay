import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/shell_screen.dart';

class HerDayApp extends StatelessWidget {
  const HerDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, themeName, _) {
        return MaterialApp(
          title: 'HerDay',
          debugShowCheckedModeBanner: false,
          theme: HerDayThemes.build(themeName),
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Shows the login screen when signed out, the app shell when signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();
        return ShellScreen(key: ValueKey(session.user.id));
      },
    );
  }
}
