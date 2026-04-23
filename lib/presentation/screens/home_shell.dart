import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/screens/profession_flow_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/publish_placeholder_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/telegram_flow_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Start on Telegram link flow (primary first-use path).
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const ProfessionFlowScreen(),
        const TelegramFlowScreen(),
        const PublishPlaceholderScreen(),
      ][_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Profession',
          ),
          NavigationDestination(
            icon: Icon(Icons.link_outlined),
            selectedIcon: Icon(Icons.link),
            label: 'Telegram',
          ),
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch),
            label: 'Publish',
          ),
        ],
      ),
    );
  }
}
