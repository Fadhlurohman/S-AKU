import 'package:flutter/material.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/add_transaction_tab.dart';
import 'tabs/history_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check screen width for responsiveness (Desktop vs Mobile layouts)
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    final tabs = [
      const DashboardTab(),
      AddTransactionTab(onSuccess: () {
        setState(() {
          _currentIndex = 0;
        });
      }),
      const HistoryTab(),
    ];

    // Gradient styling for the Brand text (Green to Red matching the slogan)
    Widget brandTitle = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFFF43F5E)],
      ).createShader(Offset.zero & bounds.size),
      child: const Text(
        'DompetGweh',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 38,
                width: 38,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            // Title + Slogan Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  brandTitle,
                  Text(
                    'Catat masuknya dikit, keluarnya banyak.',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8FA899) : const Color(0xFF688072),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Desktop Sidebar Navigation
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    indicatorColor: theme.primaryColor.withOpacity(0.15),
                    selectedIconTheme: IconThemeData(color: theme.primaryColor),
                    unselectedIconTheme: const IconThemeData(color: Colors.grey),
                    selectedLabelTextStyle: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.add_circle_outline),
                        selectedIcon: Icon(Icons.add_circle),
                        label: Text('Tambah'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: Text('Riwayat'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Content Area
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: tabs,
                    ),
                  ),
                ],
              )
            : IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
      ),
      // Mobile Bottom Navigation Bar (Hidden on desktop screens)
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: theme.scaffoldBackgroundColor,
              selectedItemColor: theme.primaryColor,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              elevation: 8,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline),
                  activeIcon: Icon(Icons.add_circle),
                  label: 'Tambah',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
              ],
            ),
    );
  }
}
