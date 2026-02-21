import 'package:flutter/material.dart';
import 'package:portfolio_tracker/theme/app_theme.dart';
import 'package:portfolio_tracker/utils/constants.dart';
import 'package:portfolio_tracker/utils/formatters.dart';
import 'package:portfolio_tracker/widgets/loading_shimmer.dart';
import 'package:provider/provider.dart';
import 'package:portfolio_tracker/services/portfolio_provider.dart';
import 'package:portfolio_tracker/providers/theme_provider.dart';
import 'package:portfolio_tracker/providers/auth_provider.dart';

/// App navigation drawer with user information and portfolio summary
///
/// Provides comprehensive navigation with:
/// - User profile section with avatar and portfolio value
/// - Navigation menu items with active state highlighting
/// - Theme toggle and settings
/// - Logout functionality
/// - Database statistics
class AppDrawer extends StatefulWidget {
  /// Current route to highlight active menu item
  final String currentRoute;

  /// Callback when navigation item is selected
  final Function(String route)? onNavigate;

  const AppDrawer({super.key, required this.currentRoute, this.onNavigate});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get user initials from full name
  String _getUserInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Handle navigation
  void _handleNavigation(String route) {
    // Close drawer with animation
    Navigator.pop(context);

    // Navigate after drawer close animation completes
    Future.delayed(const Duration(milliseconds: 250), () {
      if (widget.onNavigate != null) {
        widget.onNavigate!(route);
      } else {
        Navigator.pushReplacementNamed(context, route);
      }
    });
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _handleLogout();
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    final portfolioProvider = context.read<PortfolioProvider>();

    // Logout from both providers
    await portfolioProvider.logout();
    await authProvider.logout();

    if (mounted) {
      // Close drawer
      Navigator.pop(context);

      // Navigate to login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// Toggle theme
  void _toggleTheme() {
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Responsive drawer width
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 600 ? 320.0 : 280.0;

    return Drawer(
      width: drawerWidth,
      child: Column(
        children: [
          // Drawer Header
          _buildDrawerHeader(theme, isDark),

          // Navigation Items
          Expanded(
            child: Consumer<PortfolioProvider>(
              builder: (context, portfolioProvider, child) {
                final transactionCount = portfolioProvider.transactions.length;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildNavigationItem(
                      icon: Icons.home,
                      title: 'Portfolio',
                      route: '/',
                      theme: theme,
                    ),
                    _buildNavigationItem(
                      icon: Icons.show_chart,
                      title: 'Charts & Analytics',
                      route: '/charts',
                      theme: theme,
                    ),
                    _buildNavigationItem(
                      icon: Icons.receipt_long,
                      title: 'Transaction History',
                      route: '/transactions',
                      badge: transactionCount > 0
                          ? transactionCount.toString()
                          : null,
                      theme: theme,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),

                    _buildNavigationItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      route: '/settings',
                      theme: theme,
                    ),
                    _buildNavigationItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      route: '/about',
                      theme: theme,
                    ),
                  ],
                );
              },
            ),
          ),

          // Drawer Footer
          _buildDrawerFooter(theme, isDark),
        ],
      ),
    );
  }

  /// Build drawer header with user info and portfolio summary - FIXED: Better height management
  Widget _buildDrawerHeader(ThemeData theme, bool isDark) {
    return Container(
      height: 305, // CHANGED: Increased from 240 to 260 for better spacing
      decoration: AppTheme.drawerHeaderDecoration(isDark: isDark),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ), // CHANGED: Reduced top/bottom padding
          child: Consumer2<AuthProvider, PortfolioProvider>(
            builder: (context, authProvider, portfolioProvider, child) {
              if (portfolioProvider.isLoading) {
                return _buildHeaderLoading();
              }

              return _buildHeaderContent(
                theme,
                authProvider.currentUser?.fullName ?? 'User',
                authProvider.currentUser?.username ?? '@user',
                portfolioProvider.summary?.totalValue ?? 0.0,
                portfolioProvider.summary?.dayGain ?? 0.0,
                (portfolioProvider.summary?.dayGainPercent ?? 0.0) /
                    100, // Convert to decimal
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build header content with user information - FIXED: All overflow issues resolved
  Widget _buildHeaderContent(
    ThemeData theme,
    String userName,
    String userUsername,
    double portfolioValue,
    double dayChange,
    double dayChangePercent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min, // ADDED: Prevent column from expanding too much
      children: [
        // App branding and demo badge - FIXED: Constrained to prevent overflow
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Flexible(
              // CHANGED: Wrap in Flexible
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // CHANGED: Reduced from 20 to 16
        // User avatar and info
        Row(
          children: [
            // Avatar with initials
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _getUserInitials(userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User name and username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ADDED
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userUsername,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // CHANGED: Reduced from 20 to 16
        // Portfolio value
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ADDED
          children: [
            Text(
              'Portfolio Value',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                Formatters.formatCurrency(portfolioValue),
                key: ValueKey(portfolioValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6), // CHANGED: Reduced from 8 to 6
            // Day change - FIXED: Proper constraints to prevent overflow
            _buildDayChange(dayChange, dayChangePercent),
          ],
        ),
      ],
    );
  }

  /// Build day change indicator - FIXED: Proper constraints to prevent overflow
  Widget _buildDayChange(double dayChange, double dayChangePercent) {
    final color = Formatters.getChangeColor(dayChange) == AppTheme.gainColor
        ? Colors.greenAccent
        : Colors.redAccent;
    final icon = Formatters.getChangeIconData(dayChange);

    return Row(
      mainAxisSize: MainAxisSize.min, // ADDED
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          // CHANGED: Use Expanded instead of Flexible
          child: Text(
            '${Formatters.formatCurrency(dayChange.abs())} (${Formatters.formatPercentWithSign(dayChangePercent)}) today',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build loading shimmer for header
  Widget _buildHeaderLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoadingShimmer(width: 150, height: 16),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(width: 120, height: 18),
                  SizedBox(height: 6),
                  LoadingShimmer(width: 80, height: 13),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const LoadingShimmer(width: 100, height: 12),
        const SizedBox(height: 8),
        const LoadingShimmer(width: 180, height: 28),
        const SizedBox(height: 12),
        const LoadingShimmer(width: 140, height: 14),
      ],
    );
  }

  /// Build navigation menu item
  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required String route,
    String? badge,
    required ThemeData theme,
  }) {
    final isSelected = widget.currentRoute == route;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _handleNavigation(route),
      ),
    );
  }

  /// Build drawer footer with theme toggle and logout
  Widget _buildDrawerFooter(ThemeData theme, bool isDark) {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final assetCount = portfolioProvider.assets.length;
        final transactionCount = portfolioProvider.transactions.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),

            // Theme toggle
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  title: Text(
                    themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => _toggleTheme(),
                  ),
                  onTap: _toggleTheme,
                );
              },
            ),

            // Database statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.storage,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$assetCount assets • $transactionCount transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Switch Account (disabled for demo)
            ListTile(
              leading: Icon(
                Icons.swap_horiz,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              title: Text(
                'Switch Account',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              enabled: false,
              onTap: null,
            ),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: Text(
                'Logout',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _showLogoutDialog,
            ),

            // App version and last updated
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated ${Formatters.formatTimeAgo(DateTime.now())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Extension to easily add the drawer to any Scaffold
extension DrawerExtension on BuildContext {
  /// Show the app drawer
  void showAppDrawer() {
    Scaffold.of(this).openDrawer();
  }
}

// import 'package:flutter/material.dart';
// import 'package:portfolio_tracker/theme/app_theme.dart';
// import 'package:portfolio_tracker/utils/constants.dart';
// import 'package:portfolio_tracker/utils/formatters.dart';
// import 'package:portfolio_tracker/widgets/loading_shimmer.dart';
// import 'package:provider/provider.dart';
// import 'package:portfolio_tracker/services/portfolio_provider.dart';
// import 'package:portfolio_tracker/providers/theme_provider.dart';
// import 'package:portfolio_tracker/providers/auth_provider.dart';

// /// App navigation drawer with user information and portfolio summary
// ///
// /// Provides comprehensive navigation with:
// /// - User profile section with avatar and portfolio value
// /// - Navigation menu items with active state highlighting
// /// - Theme toggle and settings
// /// - Logout functionality
// /// - Database statistics
// class AppDrawer extends StatefulWidget {
//   /// Current route to highlight active menu item
//   final String currentRoute;

//   /// Callback when navigation item is selected
//   final Function(String route)? onNavigate;

//   const AppDrawer({super.key, required this.currentRoute, this.onNavigate});

//   @override
//   State<AppDrawer> createState() => _AppDrawerState();
// }

// class _AppDrawerState extends State<AppDrawer>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   /// Get user initials from full name
//   String _getUserInitials(String fullName) {
//     final parts = fullName.trim().split(' ');
//     if (parts.isEmpty) return 'U';
//     if (parts.length == 1) return parts[0][0].toUpperCase();
//     return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
//   }

//   /// Handle navigation
//   void _handleNavigation(String route) {
//     // Close drawer with animation
//     Navigator.pop(context);

//     // Navigate after drawer close animation completes
//     Future.delayed(const Duration(milliseconds: 250), () {
//       if (widget.onNavigate != null) {
//         widget.onNavigate!(route);
//       } else {
//         Navigator.pushReplacementNamed(context, route);
//       }
//     });
//   }

//   /// Show logout confirmation dialog
//   Future<void> _showLogoutDialog() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.errorColor,
//             ),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true && mounted) {
//       await _handleLogout();
//     }
//   }

//   /// Handle logout
//   Future<void> _handleLogout() async {
//     final authProvider = context.read<AuthProvider>();
//     final portfolioProvider = context.read<PortfolioProvider>();

//     // Logout from both providers
//     await portfolioProvider.logout();
//     await authProvider.logout();

//     if (mounted) {
//       // Close drawer
//       Navigator.pop(context);

//       // Navigate to login screen
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   /// Toggle theme
//   void _toggleTheme() {
//     final themeProvider = context.read<ThemeProvider>();
//     themeProvider.toggleTheme();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     // Responsive drawer width
//     final screenWidth = MediaQuery.of(context).size.width;
//     final drawerWidth = screenWidth > 600 ? 320.0 : 280.0;

//     return Drawer(
//       width: drawerWidth,
//       child: Column(
//         children: [
//           // Drawer Header
//           _buildDrawerHeader(theme, isDark),

//           // Navigation Items
//           Expanded(
//             child: Consumer<PortfolioProvider>(
//               builder: (context, portfolioProvider, child) {
//                 final transactionCount = portfolioProvider.transactions.length;

//                 return ListView(
//                   padding: EdgeInsets.zero,
//                   children: [
//                     _buildNavigationItem(
//                       icon: Icons.home,
//                       title: 'Portfolio',
//                       route: '/',
//                       theme: theme,
//                     ),
//                     _buildNavigationItem(
//                       icon: Icons.show_chart,
//                       title: 'Charts & Analytics',
//                       route: '/charts',
//                       theme: theme,
//                     ),
//                     _buildNavigationItem(
//                       icon: Icons.receipt_long,
//                       title: 'Transaction History',
//                       route: '/transactions',
//                       badge: transactionCount > 0
//                           ? transactionCount.toString()
//                           : null,
//                       theme: theme,
//                     ),

//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8),
//                       child: Divider(height: 1),
//                     ),

//                     _buildNavigationItem(
//                       icon: Icons.settings,
//                       title: 'Settings',
//                       route: '/settings',
//                       theme: theme,
//                     ),
//                     _buildNavigationItem(
//                       icon: Icons.info_outline,
//                       title: 'About',
//                       route: '/about',
//                       theme: theme,
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),

//           // Drawer Footer
//           _buildDrawerFooter(theme, isDark),
//         ],
//       ),
//     );
//   }

//   /// Build drawer header with user info and portfolio summary
//   Widget _buildDrawerHeader(ThemeData theme, bool isDark) {
//     return Container(
//       height: 240,
//       decoration: AppTheme.drawerHeaderDecoration(isDark: isDark),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//           child: Consumer2<AuthProvider, PortfolioProvider>(
//             builder: (context, authProvider, portfolioProvider, child) {
//               if (portfolioProvider.isLoading) {
//                 return _buildHeaderLoading();
//               }

//               return _buildHeaderContent(
//                 theme,
//                 authProvider.currentUser?.fullName ?? 'User',
//                 authProvider.currentUser?.username ?? '@user',
//                 portfolioProvider.summary?.totalValue ?? 0.0,
//                 portfolioProvider.summary?.dayGain ?? 0.0,
//                 (portfolioProvider.summary?.dayGainPercent ?? 0.0) /
//                     100, // Convert to decimal
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   /// Build header content with user information
//   Widget _buildHeaderContent(
//     ThemeData theme,
//     String userName,
//     String userUsername,
//     double portfolioValue,
//     double dayChange,
//     double dayChangePercent,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // App branding and demo badge
//         Row(
//           children: [
//             const Icon(
//               Icons.account_balance_wallet,
//               color: Colors.white,
//               size: 24,
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               AppConstants.appName,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.25),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: const Text(
//                 'DEMO',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),

//         // User avatar and info
//         Row(
//           children: [
//             // Avatar with initials
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.3),
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.5),
//                   width: 2,
//                 ),
//               ),
//               child: Center(
//                 child: Text(
//                   _getUserInitials(userName),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),

//             // User name and username
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     userName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     userUsername,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.7),
//                       fontSize: 13,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),

//         // Portfolio value
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Portfolio Value',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.8),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 4),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 300),
//               child: Text(
//                 Formatters.formatCurrency(portfolioValue),
//                 key: ValueKey(portfolioValue),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),

//             // Day change - FIXED: Wrapped in Flexible to prevent overflow
//             _buildDayChange(dayChange, dayChangePercent),
//           ],
//         ),
//       ],
//     );
//   }

//   /// Build day change indicator - FIXED: Added constraints
//   // Widget _buildDayChange(double dayChange, double dayChangePercent) {
//   //   final color = Formatters.getChangeColor(dayChange) == AppTheme.gainColor
//   //       ? Colors.greenAccent
//   //       : Colors.redAccent;
//   //   final icon = Formatters.getChangeIconData(dayChange);

//   //   return Row(
//   //     children: [
//   //       Icon(icon, size: 16, color: color),
//   //       const SizedBox(width: 4),
//   //       // FIXED: Wrap the text in Flexible to prevent overflow
//   //       Flexible(
//   //         child: Text(
//   //           '${Formatters.formatCurrency(dayChange.abs())} (${Formatters.formatPercentWithSign(dayChangePercent)}) today',
//   //           style: TextStyle(
//   //             color: color,
//   //             fontSize: 13,
//   //             fontWeight: FontWeight.w600,
//   //           ),
//   //           maxLines: 1,
//   //           overflow: TextOverflow.ellipsis,
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }

//   /// Build day change indicator - FIXED: Constrained width approach
//   Widget _buildDayChange(double dayChange, double dayChangePercent) {
//     final color = Formatters.getChangeColor(dayChange) == AppTheme.gainColor
//         ? Colors.greenAccent
//         : Colors.redAccent;
//     final icon = Formatters.getChangeIconData(dayChange);

//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 250), // Adjust as needed
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: color),
//           const SizedBox(width: 4),
//           Expanded(
//             child: Text(
//               '${Formatters.formatCurrency(dayChange.abs())} (${Formatters.formatPercentWithSign(dayChangePercent)}) today',
//               style: TextStyle(
//                 color: color,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build loading shimmer for header
//   Widget _buildHeaderLoading() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const LoadingShimmer(width: 150, height: 16),
//         const SizedBox(height: 20),
//         Row(
//           children: [
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   LoadingShimmer(width: 120, height: 18),
//                   SizedBox(height: 6),
//                   LoadingShimmer(width: 80, height: 13),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//         const LoadingShimmer(width: 100, height: 12),
//         const SizedBox(height: 8),
//         const LoadingShimmer(width: 180, height: 28),
//         const SizedBox(height: 12),
//         const LoadingShimmer(width: 140, height: 14),
//       ],
//     );
//   }

//   /// Build navigation menu item
//   Widget _buildNavigationItem({
//     required IconData icon,
//     required String title,
//     required String route,
//     String? badge,
//     required ThemeData theme,
//   }) {
//     final isSelected = widget.currentRoute == route;
//     final color = isSelected
//         ? theme.colorScheme.primary
//         : theme.colorScheme.onSurface;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: isSelected
//             ? theme.colorScheme.primary.withOpacity(0.1)
//             : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: color),
//         title: Text(
//           title,
//           style: theme.textTheme.bodyLarge?.copyWith(
//             color: color,
//             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//           ),
//         ),
//         trailing: badge != null
//             ? Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.primary,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   badge,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               )
//             : null,
//         selected: isSelected,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         onTap: () => _handleNavigation(route),
//       ),
//     );
//   }

//   /// Build drawer footer with theme toggle and logout
//   Widget _buildDrawerFooter(ThemeData theme, bool isDark) {
//     return Consumer<PortfolioProvider>(
//       builder: (context, portfolioProvider, child) {
//         final assetCount = portfolioProvider.assets.length;
//         final transactionCount = portfolioProvider.transactions.length;

//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Divider(height: 1),

//             // Theme toggle
//             Consumer<ThemeProvider>(
//               builder: (context, themeProvider, child) {
//                 return ListTile(
//                   leading: Icon(
//                     themeProvider.isDarkMode
//                         ? Icons.light_mode
//                         : Icons.dark_mode,
//                     color: theme.colorScheme.onSurface.withOpacity(0.7),
//                   ),
//                   title: Text(
//                     themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
//                     style: theme.textTheme.bodyMedium,
//                   ),
//                   trailing: Switch(
//                     value: themeProvider.isDarkMode,
//                     onChanged: (value) => _toggleTheme(),
//                   ),
//                   onTap: _toggleTheme,
//                 );
//               },
//             ),

//             // Database statistics
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.storage,
//                     size: 14,
//                     color: theme.colorScheme.onSurface.withOpacity(0.5),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     '$assetCount assets • $transactionCount transactions',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurface.withOpacity(0.5),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const Divider(height: 1),

//             // Switch Account (disabled for demo)
//             ListTile(
//               leading: Icon(
//                 Icons.swap_horiz,
//                 color: theme.colorScheme.onSurface.withOpacity(0.3),
//               ),
//               title: Text(
//                 'Switch Account',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.colorScheme.onSurface.withOpacity(0.3),
//                 ),
//               ),
//               enabled: false,
//               onTap: null,
//             ),

//             // Logout
//             ListTile(
//               leading: const Icon(Icons.logout, color: AppTheme.errorColor),
//               title: Text(
//                 'Logout',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: AppTheme.errorColor,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               onTap: _showLogoutDialog,
//             ),

//             // App version and last updated
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Text(
//                     'Version ${AppConstants.appVersion}',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurface.withOpacity(0.4),
//                       fontSize: 11,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Last updated ${Formatters.formatTimeAgo(DateTime.now())}',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurface.withOpacity(0.4),
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// /// Extension to easily add the drawer to any Scaffold
// extension DrawerExtension on BuildContext {
//   /// Show the app drawer
//   void showAppDrawer() {
//     Scaffold.of(this).openDrawer();
//   }
// }
