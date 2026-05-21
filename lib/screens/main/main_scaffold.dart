import 'package:acai_stock/screens/alerts/alerts_screen.dart';
import 'package:acai_stock/screens/entry/scanner_screen.dart';
import 'package:acai_stock/screens/home/home_screen.dart';
import 'package:acai_stock/screens/products/products_screen.dart';
import 'package:acai_stock/screens/settings/settings_screen.dart';
import 'package:acai_stock/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int index = 0;

  void _onTabSelected(int value) {
    setState(() => index = value);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const ProductsScreen(),
      const AlertsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
          },
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Entrada'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }
}
