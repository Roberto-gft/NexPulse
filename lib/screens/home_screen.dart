import 'package:flutter/material.dart';
import 'package:nexpulse/screens/fitness_hub_tab.dart';
import 'package:nexpulse/screens/history_tab.dart';
import 'package:nexpulse/screens/profile_tab.dart';
import 'package:nexpulse/screens/tracker_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      const TrackerTab(),
      const FitnessHubTab(),
      HistoryTab(isActiveTab: _selectedIndex == 2),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: isDark ? const Color(0xFF182226) : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF2E9E6B).withValues(alpha: 0.28)
            : const Color(0xFFD6F2E4),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run, color: Color(0xFF2E9E6B)),
            label: 'Entrenamiento',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: Color(0xFF2E9E6B)),
            label: 'Fitness',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Color(0xFF2E9E6B)),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E9E6B)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}