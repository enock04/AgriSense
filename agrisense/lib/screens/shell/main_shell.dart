import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../l10n/app_strings.dart';
import '../home/home_screen.dart';
import '../weather/weather_screen.dart';
import '../learn/learn_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    WeatherScreen(),
    LearnScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync with provider for programmatic tab navigation
    final providerIndex = context.read<AppProvider>().selectedTabIndex;
    if (providerIndex != _selectedIndex) {
      setState(() => _selectedIndex = providerIndex);
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    // Keep provider in sync
    context.read<AppProvider>().navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    // React to programmatic navigation from provider
    final providerIndex = context.watch<AppProvider>().selectedTabIndex;
    if (providerIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && providerIndex != _selectedIndex) {
          setState(() => _selectedIndex = providerIndex);
        }
      });
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: context.trW.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_rounded),
            label: context.trW.navWeather,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: context.trW.navLearn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: context.trW.navCommunity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: context.trW.navProfile,
          ),
        ],
      ),
    );
  }
}
