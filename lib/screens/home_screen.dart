import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'history_tab.dart';
import 'profile_tab.dart';
import 'tracker_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _currentIndex == 0
            ? null
            : AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F17),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _currentIndex == 1
                    ? 'Historial Deportivo'
                    : 'Perfil del Atleta',
                style: const TextStyle(
                  color: Color(0xFF0B0F17),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFCCB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBEF264)),
              ),
              child: const Text(
                'NEXPULSE',
                style: TextStyle(
                  color: Color(0xFF3F6212),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            TrackerTab(isActiveTab: _currentIndex == 0),
            HistoryTab(isActiveTab: _currentIndex == 1),
            const ProfileTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: NavigationBar(
            height: 66,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: const Color(0xFFECFCCB),
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.directions_run_outlined,
                    color: Color(0xFF64748B)),
                selectedIcon:
                Icon(Icons.directions_run_rounded, color: Color(0xFF0B0F17)),
                label: 'Entrenamiento',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined, color: Color(0xFF64748B)),
                selectedIcon:
                Icon(Icons.history_rounded, color: Color(0xFF0B0F17)),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded,
                    color: Color(0xFF64748B)),
                selectedIcon:
                Icon(Icons.person_rounded, color: Color(0xFF0B0F17)),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}