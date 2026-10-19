import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/herday_db.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'me_screen.dart';
import 'tasks_screen.dart';
import 'us_screen.dart';

/// Bottom navigation: Home · Tasks · Calendar · 💕 Us · Me
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final p = await HerDayDb.instance.fetchProfile();
      if (p != null && mounted) themeNotifier.value = p.theme;
    } catch (_) {
      // Offline / first run — keep the default Sakura theme.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onSeeAllTasks: () => setState(() => _index = 1)),
      const TasksScreen(),
      const CalendarScreen(),
      const UsScreen(),
      const MeScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Us 💕'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
