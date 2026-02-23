import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'services_screen.dart';
import 'income_screen.dart';
import 'profile_screen.dart';
import 'app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServicesScreen(),
    IncomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme: IconThemeData(color: AppTheme.primaryBlue),
                  unselectedIconTheme: IconThemeData(color: AppTheme.textGrey),
                  selectedLabelTextStyle: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.build_circle,
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Ana Sayfa'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.build_outlined),
                      selectedIcon: Icon(Icons.build),
                      label: Text('Servisler'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Gelirler'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profil'),
                    ),
                  ],
                ),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: 'Ana Sayfa',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.build_outlined),
                        activeIcon: Icon(Icons.build),
                        label: 'Servisler',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.bar_chart_outlined),
                        activeIcon: Icon(Icons.bar_chart),
                        label: 'Gelirler',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person),
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
