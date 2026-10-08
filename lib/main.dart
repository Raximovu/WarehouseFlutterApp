import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/inventory/initial_balances_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/partners/partners_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GrandPolimerPlastApp());
}

class GrandPolimerPlastApp extends StatelessWidget {
  const GrandPolimerPlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Grand Polimer Plast',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode, 
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  final List<Widget> _pages = [
    const HomeScreen(),
    const InventoryScreen(),
    const InitialBalancesScreen(),
    const TransactionsScreen(),
    const PartnersScreen(),
    const DebtsScreen(),
    const SettingsScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Bosh sahifa', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
    {'title': 'Sklad va Qoldiqlar', 'icon': Icons.inventory_2_outlined, 'activeIcon': Icons.inventory_2},
    {'title': 'Boshlang\'ich Qoldiqlar', 'icon': Icons.archive_outlined, 'activeIcon': Icons.archive},
    {'title': 'Ombor Harakatlari', 'icon': Icons.history_outlined, 'activeIcon': Icons.history},
    {'title': 'Kontragentlar', 'icon': Icons.people_outline, 'activeIcon': Icons.people},
    {'title': 'Qarzlar Balansi', 'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet},
    {'title': 'Sozlamalar & Backup', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // YON MENYU (Sidebar - Material Me Style)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 270 : 80, // Kenglik biroz oshirildi
            color: isDark ? AppTheme.darkSurface : AppTheme.primaryColor,
            child: Column(
              children: [
                // Header va Logotip qismi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Row(
                    children: [
                      // Rasmli Logotip (yoki rasm yo'q bo'lsa standart icon)
                      Image.asset(
                        'assets/logo.png',
                        height: 38,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.inventory,
                            color: isDark ? AppTheme.primaryColor : Colors.white,
                            size: 32,
                          );
                        },
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown, // Matn qisqarmasdan to'liq sig'ib turadi
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'GRAND POLIMER PLAST',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Menyu ro'yxati
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppTheme.buttonRadius,
                            onTap: () {
                              setState(() => _selectedIndex = index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(
                                horizontal: _isExpanded ? 16.0 : 12.0,
                                vertical: 14.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: AppTheme.buttonRadius,
                                color: isSelected 
                                    ? (isDark ? AppTheme.primaryMutedDark : AppTheme.primaryMutedDark.withValues(alpha: 0.2)) 
                                    : Colors.transparent,
                              ),
                              child: Row(
                                mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item['activeIcon'] : item['icon'],
                                    color: isSelected 
                                        ? (isDark ? AppTheme.primaryColor : Colors.white) 
                                        : (isDark ? Colors.grey[400] : Colors.white70),
                                    size: 22,
                                  ),
                                  if (_isExpanded) ...[
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        item['title'],
                                        style: TextStyle(
                                          color: isSelected 
                                              ? (isDark ? AppTheme.primaryColor : Colors.white) 
                                              : (isDark ? Colors.grey[400] : Colors.white70),
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 14.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Toggle Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right,
                      color: isDark ? Colors.grey[400] : Colors.white70,
                    ),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                  ),
                ),
              ],
            ),
          ),

          // ASOSIY KONTENT (Body)
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: ClipRRect(
                child: _pages[_selectedIndex], 
              ),
            ),
          ),
        ],
      ),
    );
  }
}
