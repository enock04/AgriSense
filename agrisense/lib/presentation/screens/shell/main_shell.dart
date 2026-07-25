import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../../l10n/app_strings.dart';
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
    final provider = context.read<AppProvider>();
    if (provider.selectedTabIndex != _selectedIndex) {
      setState(() => _selectedIndex = provider.selectedTabIndex);
    }
  }

  // ── Error Snackbar ─────────────────────────────────────────────────────────

  void _maybeShowError(String error) {
    if (error.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
          ]),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white70,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              context.read<AppProvider>().clearError();
            },
          ),
        ),
      );
      // Auto-clear after the snackbar disappears
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) context.read<AppProvider>().clearError();
      });
    });
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    // Keep provider in sync
    context.read<AppProvider>().navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // React to programmatic navigation from provider
    if (provider.selectedTabIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.selectedTabIndex != _selectedIndex) {
          setState(() => _selectedIndex = provider.selectedTabIndex);
        }
      });
    }

    // Surface provider errors as Snackbars
    if (provider.lastError.isNotEmpty) {
      _maybeShowError(provider.lastError);
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
